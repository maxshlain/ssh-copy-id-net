#!/usr/bin/env pwsh

# debian.ps1
# PowerShell script to create Debian (.deb) packages for ssh-copy-id-net
# Supports both x64 and ARM64 architectures

$ErrorActionPreference = "Stop"

Write-Host "📦 Building Debian packages for ssh-copy-id-net..." -ForegroundColor Green

# Define variables
$PROJECT_PATH = "src/app/app.csproj"
$PACKAGE_NAME = "ssh-copy-id-net"
$MAINTAINER = "maxshlain <maxshlain@users.noreply.github.com>"
$DESCRIPTION = "A .NET cross-platform implementation of ssh-copy-id utility"
$HOMEPAGE = "https://github.com/maxshlain/ssh-copy-id-net"

# Function to extract version from csproj file
function Get-AppVersion {
    if (Test-Path $PROJECT_PATH) {
        try {
            [xml]$projectXml = Get-Content $PROJECT_PATH
            $version = $projectXml.Project.PropertyGroup.Version
            if ($version) {
                return $version.Trim()
            }
        }
        catch {
            # Fallback to regex parsing if XML parsing fails
            $content = Get-Content $PROJECT_PATH -Raw
            if ($content -match '<Version>(.*?)</Version>') {
                return $matches[1].Trim()
            }
        }
    }
    return "1.0.0"  # Default fallback
}

$VERSION = Get-AppVersion
Write-Host "📋 Application Version: $VERSION" -ForegroundColor Cyan

# Architecture mappings
$ArchMap = @{
    "linux-x64" = "amd64"
    "linux-arm64" = "arm64"
}

# Runtime identifiers to build
$Runtimes = @("linux-x64", "linux-arm64")

# Check if we're running on a system that can create .deb packages
if (-not $IsLinux) {
    Write-Host "⚠️  Warning: This script is designed to run on Linux systems" -ForegroundColor Yellow
    Write-Host "   You can still build Linux binaries, but .deb creation requires dpkg-deb" -ForegroundColor Yellow
    
    if (-not (Get-Command dpkg-deb -ErrorAction SilentlyContinue)) {
        Write-Host "❌ Error: dpkg-deb is required but not available" -ForegroundColor Red
        Write-Host "   On Ubuntu/Debian: sudo apt-get install dpkg-dev" -ForegroundColor Gray
        Write-Host "   On Windows/macOS: Use WSL or a Linux container" -ForegroundColor Gray
        exit 1
    }
}

# Clean previous builds
Write-Host "🧹 Cleaning previous Debian builds..." -ForegroundColor Yellow
if (Test-Path "dist/debian") {
    Remove-Item -Recurse -Force "dist/debian"
}
New-Item -ItemType Directory -Path "dist/debian" -Force | Out-Null

# Check if project file exists
if (-not (Test-Path $PROJECT_PATH)) {
    Write-Host "❌ Error: Project file not found at $PROJECT_PATH" -ForegroundColor Red
    exit 1
}

# Function to create a Debian package for a specific runtime
function New-DebianPackage {
    param(
        [string]$Runtime
    )
    
    $DebArch = $ArchMap[$Runtime]
    $PackageDir = "dist/debian/${PACKAGE_NAME}_${VERSION}_${DebArch}"
    $BinarySource = "dist/linux/$Runtime/app"
    
    Write-Host "📦 Creating Debian package for $Runtime ($DebArch)..." -ForegroundColor Blue
    
    # First, ensure the binary exists
    if (-not (Test-Path $BinarySource)) {
        Write-Host "🔨 Building $Runtime binary first..." -ForegroundColor Yellow
        
        $OutputDir = "dist/linux/$Runtime"
        New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
        
        dotnet publish $PROJECT_PATH `
            --configuration Release `
            --runtime $Runtime `
            --self-contained true `
            --output $OutputDir `
            --verbosity minimal `
            -p:PublishSingleFile=true
        
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to build $Runtime binary"
        }
        
        if ($IsLinux) {
            chmod +x $BinarySource
        }
    }
    
    # Create package directory structure
    $Directories = @(
        "$PackageDir/DEBIAN",
        "$PackageDir/usr/local/bin",
        "$PackageDir/usr/share/doc/$PACKAGE_NAME",
        "$PackageDir/usr/share/man/man1"
    )
    
    foreach ($Dir in $Directories) {
        New-Item -ItemType Directory -Path $Dir -Force | Out-Null
    }
    
    # Copy the binary
    Copy-Item $BinarySource "$PackageDir/usr/local/bin/ssh-copy-id-net"
    
    # Create control file
    $ControlContent = @"
Package: $PACKAGE_NAME
Version: $VERSION
Section: net
Priority: optional
Architecture: $DebArch
Maintainer: $MAINTAINER
Description: $DESCRIPTION
 A .NET cross-platform implementation of the ssh-copy-id utility for copying
 SSH public keys to remote servers and setting up passwordless SSH authentication.
 .
 This tool automates the process of copying your SSH public key to a remote
 server's ~/.ssh/authorized_keys file, enabling passwordless SSH authentication.
Homepage: $HOMEPAGE
"@
    
    Set-Content -Path "$PackageDir/DEBIAN/control" -Value $ControlContent -Encoding UTF8
    
    # Create copyright file
    $Year = (Get-Date).Year
    $CopyrightContent = @"
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: $PACKAGE_NAME
Upstream-Contact: $MAINTAINER
Source: $HOMEPAGE

Files: *
Copyright: $Year maxshlain
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
"@
    
    Set-Content -Path "$PackageDir/usr/share/doc/$PACKAGE_NAME/copyright" -Value $CopyrightContent -Encoding UTF8
    
    # Create changelog
    $Date = Get-Date -Format "ddd, dd MMM yyyy HH:mm:ss zzz"
    $ChangelogContent = @"
$PACKAGE_NAME ($VERSION) unstable; urgency=medium

  * Initial Debian package release
  * Cross-platform SSH key copying utility
  * Supports passwordless SSH authentication setup

 -- $MAINTAINER  $Date
"@
    
    Set-Content -Path "$PackageDir/usr/share/doc/$PACKAGE_NAME/changelog.Debian" -Value $ChangelogContent -Encoding UTF8
    
    # Compress changelog (if gzip is available)
    if (Get-Command gzip -ErrorAction SilentlyContinue) {
        gzip -9 "$PackageDir/usr/share/doc/$PACKAGE_NAME/changelog.Debian"
    }
    
    # Create simple man page
    $ManDate = Get-Date -Format "MMMM yyyy"
    $ManContent = @"
.TH SSH-COPY-ID-NET 1 "$ManDate" "ssh-copy-id-net $VERSION" "User Commands"
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
"@
    
    Set-Content -Path "$PackageDir/usr/share/man/man1/ssh-copy-id-net.1" -Value $ManContent -Encoding UTF8
    
    # Compress man page (if gzip is available)
    if (Get-Command gzip -ErrorAction SilentlyContinue) {
        gzip -9 "$PackageDir/usr/share/man/man1/ssh-copy-id-net.1"
    }
    
    # Set correct permissions (if running on Linux)
    if ($IsLinux) {
        chmod 755 "$PackageDir/usr/local/bin/ssh-copy-id-net"
        # Set directory permissions
        Get-ChildItem -Path $PackageDir -Recurse -Directory | ForEach-Object {
            chmod 755 $_.FullName
        }
        # Set file permissions
        Get-ChildItem -Path $PackageDir -Recurse -File | ForEach-Object {
            chmod 644 $_.FullName
        }
        chmod 755 "$PackageDir/usr/local/bin/ssh-copy-id-net"
    }
    
    # Build the package
    $DebFile = "dist/debian/${PACKAGE_NAME}_${VERSION}_${DebArch}.deb"
    dpkg-deb --build $PackageDir $DebFile
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Successfully created $DebFile" -ForegroundColor Green
        
        # Show package info
        $FileInfo = Get-Item $DebFile
        $FileSizeMB = [math]::Round($FileInfo.Length / 1MB, 2)
        Write-Host "📁 Package size: $FileSizeMB MB" -ForegroundColor Cyan
        Write-Host "📂 Location: $DebFile" -ForegroundColor Cyan
        
        # Validate package
        Write-Host "🔍 Validating package..." -ForegroundColor Blue
        dpkg-deb --info $DebFile
    } else {
        Write-Host "❌ Failed to create Debian package for $Runtime" -ForegroundColor Red
        throw "Package creation failed"
    }
    
    # Clean up build directory
    Remove-Item -Recurse -Force $PackageDir
}

# Create packages for each architecture
$SuccessfulPackages = 0
foreach ($Runtime in $Runtimes) {
    try {
        New-DebianPackage -Runtime $Runtime
        $SuccessfulPackages++
        Write-Host ""
    }
    catch {
        Write-Host "❌ Failed to create package for $Runtime" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        Write-Host ""
    }
}

Write-Host "🎉 Debian package creation complete!" -ForegroundColor Green
Write-Host "📊 Created $SuccessfulPackages out of $($Runtimes.Count) packages successfully" -ForegroundColor Cyan

if ($SuccessfulPackages -gt 0) {
    Write-Host ""
    Write-Host "📋 Created packages:" -ForegroundColor White
    Get-ChildItem "dist/debian/*.deb" | ForEach-Object {
        $Size = [math]::Round($_.Length / 1MB, 2)
        Write-Host "   $($_.Name) ($Size MB)" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "🔧 Installation instructions:" -ForegroundColor Yellow
    Write-Host "   sudo dpkg -i dist/debian/ssh-copy-id-net_${VERSION}_amd64.deb" -ForegroundColor Gray
    Write-Host "   sudo dpkg -i dist/debian/ssh-copy-id-net_${VERSION}_arm64.deb" -ForegroundColor Gray
    Write-Host ""
    Write-Host "💡 To uninstall:" -ForegroundColor Yellow
    Write-Host "   sudo dpkg -r ssh-copy-id-net" -ForegroundColor Gray
    Write-Host ""
    Write-Host "📦 To add to a repository, you can use:" -ForegroundColor Yellow
    Write-Host "   dpkg-scanpackages dist/debian /dev/null | gzip -9c > dist/debian/Packages.gz" -ForegroundColor Gray
}
