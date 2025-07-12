#!/bin/bash

# publish.win.bash
# Script to create a standalone executable for Windows environments
# without requiring the .NET runtime to be installed

set -e  # Exit on any error

echo "🚀 Building standalone Windows executable..."

# Define variables
PROJECT_PATH="src/app/app.csproj"
OUTPUT_DIR="dist/windows"
RUNTIME_ID="win-x64"  # For 64-bit Windows
RUNTIME_ID_X86="win-x86"  # For 32-bit Windows (optional)
RUNTIME_ID_ARM="win-arm64"  # For ARM64 Windows

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
        -p:PublishSingleFile=true
    
    if [ $? -eq 0 ]; then
        echo "✅ Successfully published for $runtime"
        
        # Show file size
        local file_size=$(du -h "$output_subdir/app.exe" | cut -f1)
        echo "📁 Executable size: $file_size"
        echo "📂 Output location: $output_subdir/app.exe"
    else
        echo "❌ Failed to publish for $runtime"
        return 1
    fi
}

# Publish for 64-bit Windows (most common)
publish_for_runtime "$RUNTIME_ID"

echo ""

# Publish for ARM64 Windows (newer Surface devices and ARM PCs)
publish_for_runtime "$RUNTIME_ID_ARM"

echo ""

# Optionally publish for 32-bit Windows (uncomment if needed)
# echo "Publishing for 32-bit Windows..."
# publish_for_runtime "$RUNTIME_ID_X86"
# echo ""

echo "🎉 Build complete!"
echo ""
echo "📋 Usage instructions:"
echo "   64-bit Windows:  ./dist/windows/$RUNTIME_ID/app.exe"
echo "   ARM64 Windows:   ./dist/windows/$RUNTIME_ID_ARM/app.exe"
echo ""
echo "💡 To determine your Windows architecture:"
echo "   - Open System Information (msinfo32)"
echo "   - Check 'System Type' field"
echo "   - x64-based PC = 64-bit Windows (use win-x64 build)"
echo "   - ARM64-based PC = ARM Windows (use win-arm64 build)"
echo ""
echo "🔧 To run on Windows:"
echo "   1. Copy the appropriate executable to your Windows machine"
echo "   2. Open Command Prompt or PowerShell"
echo "   3. Run: app.exe <host> <port> <username> <password> <public_key_file>"
