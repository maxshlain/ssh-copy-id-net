#!/usr/bin/env pwsh

# publish.linux.ps1
# PowerShell script to create a standalone executable for Linux environments
# without requiring the .NET runtime to be installed

$ErrorActionPreference = "Stop"  # Exit on any error

Write-Host "🐧 Building standalone Linux executable..." -ForegroundColor Green

# Define variables
$PROJECT_PATH = "src/app/app.csproj"
$OUTPUT_DIR = "dist/linux"
$RUNTIME_ID = "linux-x64"      # For 64-bit Linux
$RUNTIME_ID_ARM = "linux-arm64" # For ARM64 Linux (Raspberry Pi 4+, etc.)

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

$APP_VERSION = Get-AppVersion
Write-Host "📋 Application Version: $APP_VERSION" -ForegroundColor Cyan

# Clean previous builds
Write-Host "🧹 Cleaning previous builds..." -ForegroundColor Yellow
if (Test-Path $OUTPUT_DIR) {
    Remove-Item -Recurse -Force $OUTPUT_DIR
}

# Create output directory
New-Item -ItemType Directory -Path $OUTPUT_DIR -Force | Out-Null

# Check if project file exists
if (-not (Test-Path $PROJECT_PATH)) {
    Write-Host "❌ Error: Project file not found at $PROJECT_PATH" -ForegroundColor Red
    exit 1
}

# Function to publish for a specific runtime
function Publish-ForRuntime {
    param(
        [string]$Runtime
    )
    
    $OutputSubDir = Join-Path $OUTPUT_DIR $Runtime
    
    Write-Host "📦 Publishing for $Runtime..." -ForegroundColor Blue
    
    try {
        dotnet publish $PROJECT_PATH `
            --configuration Release `
            --runtime $Runtime `
            --self-contained true `
            --output $OutputSubDir `
            --verbosity minimal `
            -p:PublishSingleFile=true
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Successfully published for $Runtime" -ForegroundColor Green
            
            # Make the executable actually executable (on Unix-like systems)
            $ExecutablePath = Join-Path $OutputSubDir "app"
            if (Test-Path $ExecutablePath) {
                if ($IsLinux -or $IsMacOS) {
                    chmod +x $ExecutablePath
                }
                
                # Show file size
                $FileInfo = Get-Item $ExecutablePath
                $FileSizeMB = [math]::Round($FileInfo.Length / 1MB, 2)
                Write-Host "📁 Executable size: $FileSizeMB MB" -ForegroundColor Cyan
                Write-Host "📂 Output location: $ExecutablePath" -ForegroundColor Cyan
            }
        } else {
            Write-Host "❌ Failed to publish for $Runtime" -ForegroundColor Red
            throw "Publication failed"
        }
    }
    catch {
        Write-Host "❌ Failed to publish for $Runtime" -ForegroundColor Red
        throw
    }
}

# Publish for 64-bit Linux (most common)
Publish-ForRuntime -Runtime $RUNTIME_ID

Write-Host ""

# Publish for ARM64 Linux (Raspberry Pi 4+, ARM servers)
Publish-ForRuntime -Runtime $RUNTIME_ID_ARM

Write-Host ""
Write-Host "🎉 Build complete! (Version: $APP_VERSION)" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Usage instructions:" -ForegroundColor White
Write-Host "   64-bit Linux:  ./dist/linux/$RUNTIME_ID/app" -ForegroundColor Gray
Write-Host "   ARM64 Linux:   ./dist/linux/$RUNTIME_ID_ARM/app" -ForegroundColor Gray
Write-Host ""
Write-Host "💡 To determine your Linux architecture, run: uname -m" -ForegroundColor Yellow
Write-Host "   x86_64 = 64-bit Linux (use linux-x64 build)" -ForegroundColor Gray
Write-Host "   aarch64 = ARM64 Linux (use linux-arm64 build)" -ForegroundColor Gray
Write-Host ""
Write-Host "🔧 To install system-wide (optional):" -ForegroundColor Yellow
Write-Host "   sudo cp ./dist/linux/`$ARCH/app /usr/local/bin/ssh-copy-id-net" -ForegroundColor Gray
Write-Host "   sudo chmod +x /usr/local/bin/ssh-copy-id-net" -ForegroundColor Gray
Write-Host ""
Write-Host "📦 To create a .deb package, run: ./publish/debian.bash" -ForegroundColor Yellow
