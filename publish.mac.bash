#!/bin/bash

# publish.mac.bash
# Script to create a standalone executable for macOS environments
# without requiring the .NET runtime to be installed

set -e  # Exit on any error

echo "🚀 Building standalone macOS executable..."

# Define variables
PROJECT_PATH="src/app/app.csproj"
OUTPUT_DIR="dist/macos"
RUNTIME_ID="osx-x64"  # For Intel Macs
RUNTIME_ID_ARM="osx-arm64"  # For Apple Silicon Macs

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
        -p:PublishTrimmed=true \
        -p:TrimMode=link
    
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

# Publish for Intel Macs (x64)
publish_for_runtime "$RUNTIME_ID"

echo ""

# Publish for Apple Silicon Macs (ARM64)
publish_for_runtime "$RUNTIME_ID_ARM"

echo ""
echo "🎉 Build complete!"
echo ""
echo "📋 Usage instructions:"
echo "   Intel Macs:      ./dist/macos/$RUNTIME_ID/app"
echo "   Apple Silicon:   ./dist/macos/$RUNTIME_ID_ARM/app"
echo ""
echo "💡 To determine your Mac architecture, run: uname -m"
echo "   x86_64 = Intel Mac (use osx-x64 build)"
echo "   arm64  = Apple Silicon Mac (use osx-arm64 build)"
