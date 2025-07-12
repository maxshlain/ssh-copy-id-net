#!/bin/bash

# publish.linux.bash
# Script to create a standalone executable for Linux environments
# without requiring the .NET runtime to be installed

set -e  # Exit on any error

echo "🐧 Building standalone Linux executable..."

# Define variables
PROJECT_PATH="src/app/app.csproj"
OUTPUT_DIR="dist/linux"
RUNTIME_ID="linux-x64"    # For 64-bit Linux
RUNTIME_ID_ARM="linux-arm64"  # For ARM64 Linux (Raspberry Pi 4+, etc.)

# Function to extract version from csproj file
get_app_version() {
    if [ -f "$PROJECT_PATH" ]; then
        # Extract version using grep and sed
        version=$(grep '<Version>' "$PROJECT_PATH" | sed 's/.*<Version>\(.*\)<\/Version>.*/\1/' | tr -d ' ')
        if [ -n "$version" ]; then
            echo "$version"
        else
            echo "1.0.0"  # Default fallback
        fi
    else
        echo "1.0.0"  # Default fallback
    fi
}

APP_VERSION=$(get_app_version)
echo "📋 Application Version: $APP_VERSION"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
if [ -d "$OUTPUT_DIR" ]; then
    rm -rf "$OUTPUT_DIR"
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Check if project file exists
if [ ! -f "$PROJECT_PATH" ]; then
    echo "❌ Error: Project file not found at $PROJECT_PATH"
    exit 1
fi

# Function to publish for a specific runtime
publish_for_runtime() {
    local runtime=$1
    local output_subdir="$OUTPUT_DIR/$runtime"
    
    echo "📦 Publishing for $runtime..."
    
    dotnet publish "$PROJECT_PATH" \
        --configuration Release \
        --runtime "$runtime" \
        --self-contained true \
        --output "$output_subdir" \
        --verbosity minimal \
        -p:PublishSingleFile=true \
        -p:PublishTrimmed=true
    
    if [ $? -eq 0 ]; then
        echo "✅ Successfully published for $runtime"
        
        # Make the executable actually executable
        chmod +x "$output_subdir/app"
        
        # Show file size
        local file_size=$(du -h "$output_subdir/app" | cut -f1)
        echo "📁 Executable size: $file_size"
        echo "📂 Output location: $output_subdir/app"
    else
        echo "❌ Failed to publish for $runtime"
        return 1
    fi
}

# Publish for 64-bit Linux (most common)
publish_for_runtime "$RUNTIME_ID"

echo ""

# Publish for ARM64 Linux (Raspberry Pi 4+, ARM servers)
publish_for_runtime "$RUNTIME_ID_ARM"

echo ""
echo "🎉 Build complete! (Version: $APP_VERSION)"
echo ""
echo "📋 Usage instructions:"
echo "   64-bit Linux:  ./dist/linux/$RUNTIME_ID/app"
echo "   ARM64 Linux:   ./dist/linux/$RUNTIME_ID_ARM/app"
echo ""
echo "💡 To determine your Linux architecture, run: uname -m"
echo "   x86_64 = 64-bit Linux (use linux-x64 build)"
echo "   aarch64 = ARM64 Linux (use linux-arm64 build)"
echo ""
echo "🔧 To install system-wide (optional):"
echo "   sudo cp ./dist/linux/\$ARCH/app /usr/local/bin/ssh-copy-id-net"
echo "   sudo chmod +x /usr/local/bin/ssh-copy-id-net"
echo ""
echo "📦 To create a .deb package, run: ./publish/debian.bash"
