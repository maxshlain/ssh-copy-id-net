#!/usr/bin/env pwsh

# publish.win.ps1
# PowerShell script to create a standalone executable for Windows environments
# without requiring the .NET runtime to be installed

$ErrorActionPreference = "Stop"  # Exit on any error

Write-Host "🚀 Building standalone Windows executable..." -ForegroundColor Green

# Define variables
$PROJECT_PATH = "src/app/app.csproj"
$OUTPUT_DIR = "dist/windows"
$RUNTIME_ID = "win-x64"        # For 64-bit Windows
$RUNTIME_ID_X86 = "win-x86"    # For 32-bit Windows (optional)
$RUNTIME_ID_ARM = "win-arm64"  # For ARM64 Windows

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
            -p:PublishSingleFile=true `
            -p:PublishTrimmed=true
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Successfully published for $Runtime" -ForegroundColor Green
            
            # Show file size
            $ExecutablePath = Join-Path $OutputSubDir "app.exe"
            if (Test-Path $ExecutablePath) {
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

# Publish for 64-bit Windows (most common)
Publish-ForRuntime -Runtime $RUNTIME_ID

Write-Host ""

# Publish for ARM64 Windows (newer Surface devices and ARM PCs)
Publish-ForRuntime -Runtime $RUNTIME_ID_ARM

Write-Host ""

# Optionally publish for 32-bit Windows (uncomment if needed)
# Write-Host "Publishing for 32-bit Windows..."
# Publish-ForRuntime -Runtime $RUNTIME_ID_X86
# Write-Host ""

Write-Host "🎉 Build complete! (Version: $APP_VERSION)" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Usage instructions:" -ForegroundColor White
Write-Host "   64-bit Windows:  .\dist\windows\$RUNTIME_ID\app.exe" -ForegroundColor Gray
Write-Host "   ARM64 Windows:   .\dist\windows\$RUNTIME_ID_ARM\app.exe" -ForegroundColor Gray
Write-Host ""
Write-Host "💡 To determine your Windows architecture:" -ForegroundColor Yellow
Write-Host "   - Open System Information (msinfo32)" -ForegroundColor Gray
Write-Host "   - Check 'System Type' field" -ForegroundColor Gray
Write-Host "   - x64-based PC = 64-bit Windows (use win-x64 build)" -ForegroundColor Gray
Write-Host "   - ARM64-based PC = ARM Windows (use win-arm64 build)" -ForegroundColor Gray
Write-Host ""
Write-Host "🔧 To run on Windows:" -ForegroundColor Yellow
Write-Host "   1. Copy the appropriate executable to your Windows machine" -ForegroundColor Gray
Write-Host "   2. Open Command Prompt or PowerShell" -ForegroundColor Gray
Write-Host "   3. Run: app.exe <host> <port> <username> <password> <public_key_file>" -ForegroundColor Gray
