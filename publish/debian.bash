#!/bin/bash

# debian.bash
# Script to create Debian (.deb) packages for ssh-copy-id-net
# Supports both x64 and ARM64 architectures

set -e  # Exit on any error

echo "📦 Building Debian packages for ssh-copy-id-net..."

# Define variables
PROJECT_PATH="src/app/app.csproj"
VERSION="1.0.0"  # You can extract this from the project file or pass as parameter
PACKAGE_NAME="ssh-copy-id-net"
MAINTAINER="maxshlain <maxshlain@users.noreply.github.com>"
DESCRIPTION="A .NET cross-platform implementation of ssh-copy-id utility"
HOMEPAGE="https://github.com/maxshlain/ssh-copy-id-net"

# Architecture mappings
declare -A ARCH_MAP
ARCH_MAP["linux-x64"]="amd64"
ARCH_MAP["linux-arm64"]="arm64"

# Runtime identifiers to build
RUNTIMES=("linux-x64" "linux-arm64")

# Clean previous builds
echo "🧹 Cleaning previous Debian builds..."
rm -rf dist/debian
mkdir -p dist/debian

# Check if project file exists
if [ ! -f "$PROJECT_PATH" ]; then
    echo "❌ Error: Project file not found at $PROJECT_PATH"
    exit 1
fi

# Check if required tools are available
if ! command -v dpkg-deb &> /dev/null; then
    echo "❌ Error: dpkg-deb is required but not installed"
    echo "   On Ubuntu/Debian: sudo apt-get install dpkg-dev"
    exit 1
fi

# Function to create a Debian package for a specific runtime
create_debian_package() {
    local runtime=$1
    local deb_arch=${ARCH_MAP[$runtime]}
    local package_dir="dist/debian/${PACKAGE_NAME}_${VERSION}_${deb_arch}"
    local binary_source="dist/linux/$runtime/app"
    
    echo "📦 Creating Debian package for $runtime ($deb_arch)..."
    
    # First, ensure the binary exists
    if [ ! -f "$binary_source" ]; then
        echo "🔨 Building $runtime binary first..."
        dotnet publish "$PROJECT_PATH" \
            --configuration Release \
            --runtime "$runtime" \
            --self-contained true \
            --output "dist/linux/$runtime" \
            --verbosity minimal \
            -p:PublishSingleFile=true
        
        chmod +x "$binary_source"
    fi
    
    # Create package directory structure
    mkdir -p "$package_dir/DEBIAN"
    mkdir -p "$package_dir/usr/local/bin"
    mkdir -p "$package_dir/usr/share/doc/$PACKAGE_NAME"
    mkdir -p "$package_dir/usr/share/man/man1"
    
    # Copy the binary
    cp "$binary_source" "$package_dir/usr/local/bin/ssh-copy-id-net"
    chmod 755 "$package_dir/usr/local/bin/ssh-copy-id-net"
    
    # Create control file
    cat > "$package_dir/DEBIAN/control" << EOF
Package: $PACKAGE_NAME
Version: $VERSION
Section: net
Priority: optional
Architecture: $deb_arch
Maintainer: $MAINTAINER
Description: $DESCRIPTION
 A .NET cross-platform implementation of the ssh-copy-id utility for copying
 SSH public keys to remote servers and setting up passwordless SSH authentication.
 .
 This tool automates the process of copying your SSH public key to a remote
 server's ~/.ssh/authorized_keys file, enabling passwordless SSH authentication.
Homepage: $HOMEPAGE
EOF

    # Create copyright file
    cat > "$package_dir/usr/share/doc/$PACKAGE_NAME/copyright" << EOF
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: $PACKAGE_NAME
Upstream-Contact: $MAINTAINER
Source: $HOMEPAGE

Files: *
Copyright: $(date +%Y) maxshlain
License: MIT

License: MIT
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 .
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 .
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
EOF

    # Create changelog
    cat > "$package_dir/usr/share/doc/$PACKAGE_NAME/changelog.Debian" << EOF
$PACKAGE_NAME ($VERSION) unstable; urgency=medium

  * Initial Debian package release
  * Cross-platform SSH key copying utility
  * Supports passwordless SSH authentication setup

 -- $MAINTAINER  $(date -R)
EOF

    # Compress changelog
    gzip -9 "$package_dir/usr/share/doc/$PACKAGE_NAME/changelog.Debian"
    
    # Create simple man page
    cat > "$package_dir/usr/share/man/man1/ssh-copy-id-net.1" << EOF
.TH SSH-COPY-ID-NET 1 "$(date '+%B %Y')" "ssh-copy-id-net $VERSION" "User Commands"
.SH NAME
ssh-copy-id-net \- install SSH public key on remote server
.SH SYNOPSIS
.B ssh-copy-id-net
.I host port username password public_key_file
.SH DESCRIPTION
.B ssh-copy-id-net
is a .NET cross-platform implementation of the ssh-copy-id utility.
It copies SSH public keys to remote servers and sets up passwordless SSH authentication.
.SH EXAMPLES
.B ssh-copy-id-net example.com 22 user secretpass ~/.ssh/id_rsa.pub
.br
Copy SSH key to example.com on port 22 with given credentials.
.SH AUTHOR
Written by maxshlain.
.SH "SEE ALSO"
.BR ssh (1),
.BR ssh-keygen (1),
.BR ssh-copy-id (1)
EOF

    # Compress man page
    gzip -9 "$package_dir/usr/share/man/man1/ssh-copy-id-net.1"
    
    # Set correct permissions
    find "$package_dir" -type d -exec chmod 755 {} \;
    find "$package_dir" -type f -exec chmod 644 {} \;
    chmod 755 "$package_dir/usr/local/bin/ssh-copy-id-net"
    
    # Build the package
    local deb_file="dist/debian/${PACKAGE_NAME}_${VERSION}_${deb_arch}.deb"
    dpkg-deb --build "$package_dir" "$deb_file"
    
    if [ $? -eq 0 ]; then
        echo "✅ Successfully created $deb_file"
        
        # Show package info
        local file_size=$(du -h "$deb_file" | cut -f1)
        echo "📁 Package size: $file_size"
        echo "📂 Location: $deb_file"
        
        # Validate package
        echo "🔍 Validating package..."
        dpkg-deb --info "$deb_file"
    else
        echo "❌ Failed to create Debian package for $runtime"
        return 1
    fi
    
    # Clean up build directory
    rm -rf "$package_dir"
}

# Create packages for each architecture
for runtime in "${RUNTIMES[@]}"; do
    create_debian_package "$runtime"
    echo ""
done

echo "🎉 Debian package creation complete!"
echo ""
echo "📋 Created packages:"
ls -la dist/debian/*.deb
echo ""
echo "🔧 Installation instructions:"
echo "   sudo dpkg -i dist/debian/ssh-copy-id-net_${VERSION}_amd64.deb"
echo "   sudo dpkg -i dist/debian/ssh-copy-id-net_${VERSION}_arm64.deb"
echo ""
echo "💡 To uninstall:"
echo "   sudo dpkg -r ssh-copy-id-net"
echo ""
echo "📦 To add to a repository, you can use:"
echo "   dpkg-scanpackages dist/debian /dev/null | gzip -9c > dist/debian/Packages.gz"
