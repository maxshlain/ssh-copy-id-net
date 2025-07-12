#!/usr/bin/env pwsh

# publish-all.ps1
# PowerShell script to create standalone executables for all supported platforms
# without requiring the .NET runtime to be installed

param(
    [switch]$Windows,
    [switch]$MacOS,
    [switch]$Linux,
    [switch]$All,
    [switch]$Help
)

$ErrorActionPreference = "Stop"

# Show help if requested
if ($Help) {
    Write-Host "SSH Copy ID .NET Publisher" -ForegroundColor Green
    Write-Host ""
    Write-Host "Usage: .\publish-all.ps1 [options]" -ForegroundColor White
    Write-Host ""
    Write-Host "Options:" -ForegroundColor Yellow
    Write-Host "  -Windows    Build Windows executables (x64, ARM64)" -ForegroundColor Gray
    Write-Host "  -MacOS      Build macOS executables (x64, ARM64)" -ForegroundColor Gray
    Write-Host "  -Linux      Build Linux executables (x64, ARM64)" -ForegroundColor Gray
    Write-Host "  -All        Build for all platforms" -ForegroundColor Gray
    Write-Host "  -Help       Show this help message" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Yellow
    Write-Host "  .\publish-all.ps1 -Windows" -ForegroundColor Gray
    Write-Host "  .\publish-all.ps1 -MacOS -Linux" -ForegroundColor Gray
    Write-Host "  .\publish-all.ps1 -All" -ForegroundColor Gray
    exit 0
}

# If no specific platform is selected, default to All
if (-not $Windows -and -not $MacOS -and -not $Linux) {
    $All = $true
}

if ($All) {
    $Windows = $true
    $MacOS = $true
    $Linux = $true
}

Write-Host "🚀 Building standalone executables..." -ForegroundColor Green

# Define variables
$PROJECT_PATH = "src/app/app.csproj"
$BASE_OUTPUT_DIR = "dist"

# Runtime identifiers
$WindowsRuntimes = @("win-x64", "win-arm64")
$MacOSRuntimes = @("osx-x64", "osx-arm64") 
$LinuxRuntimes = @("linux-x64", "linux-arm64")

# Check if project file exists
if (-not (Test-Path $PROJECT_PATH)) {
    Write-Host "❌ Error: Project file not found at $PROJECT_PATH" -ForegroundColor Red
    exit 1
}

# Function to publish for a specific runtime
function Publish-ForRuntime {
    param(
        [string]$Runtime,
        [string]$Platform
    )
    
    $OutputDir = Join-Path $BASE_OUTPUT_DIR $Platform.ToLower()
    $OutputSubDir = Join-Path $OutputDir $Runtime
    
    Write-Host "📦 Publishing $Platform for $Runtime..." -ForegroundColor Blue
    
    try {
        # Create output directory
        New-Item -ItemType Directory -Path $OutputSubDir -Force | Out-Null
        
        dotnet publish $PROJECT_PATH `
            --configuration Release `
            --runtime $Runtime `
            --self-contained true `
            --output $OutputSubDir `
            --verbosity minimal `
            -p:PublishSingleFile=true
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Successfully published $Platform for $Runtime" -ForegroundColor Green
            
            # Determine executable name based on platform
            $ExecutableName = if ($Platform -eq "Windows") { "app.exe" } else { "app" }
            $ExecutablePath = Join-Path $OutputSubDir $ExecutableName
            
            if (Test-Path $ExecutablePath) {
                # Make executable on Unix-like systems
                if (($Platform -eq "MacOS" -or $Platform -eq "Linux") -and ($IsLinux -or $IsMacOS)) {
                    chmod +x $ExecutablePath
                }
                
                # Show file size
                $FileInfo = Get-Item $ExecutablePath
                $FileSizeMB = [math]::Round($FileInfo.Length / 1MB, 2)
                Write-Host "   📁 Size: $FileSizeMB MB" -ForegroundColor Cyan
                Write-Host "   📂 Location: $ExecutablePath" -ForegroundColor Cyan
            }
        } else {
            Write-Host "❌ Failed to publish $Platform for $Runtime" -ForegroundColor Red
            throw "Publication failed"
        }
    }
    catch {
        Write-Host "❌ Failed to publish $Platform for $Runtime" -ForegroundColor Red
        throw
    }
}

# Clean previous builds
Write-Host "🧹 Cleaning previous builds..." -ForegroundColor Yellow
if (Test-Path $BASE_OUTPUT_DIR) {
    Remove-Item -Recurse -Force $BASE_OUTPUT_DIR
}

$TotalBuilds = 0
$SuccessfulBuilds = 0

# Build Windows executables
if ($Windows) {
    Write-Host ""
    Write-Host "🪟 Building Windows executables..." -ForegroundColor Magenta
    foreach ($runtime in $WindowsRuntimes) {
        try {
            $TotalBuilds++
            Publish-ForRuntime -Runtime $runtime -Platform "Windows"
            $SuccessfulBuilds++
        }
        catch {
            Write-Host "Failed to build Windows $runtime" -ForegroundColor Red
        }
    }
}

# Build macOS executables
if ($MacOS) {
    Write-Host ""
    Write-Host "🍎 Building macOS executables..." -ForegroundColor Magenta
    foreach ($runtime in $MacOSRuntimes) {
        try {
            $TotalBuilds++
            Publish-ForRuntime -Runtime $runtime -Platform "MacOS"
            $SuccessfulBuilds++
        }
        catch {
            Write-Host "Failed to build macOS $runtime" -ForegroundColor Red
        }
    }
}

# Build Linux executables
if ($Linux) {
    Write-Host ""
    Write-Host "🐧 Building Linux executables..." -ForegroundColor Magenta
    foreach ($runtime in $LinuxRuntimes) {
        try {
            $TotalBuilds++
            Publish-ForRuntime -Runtime $runtime -Platform "Linux"
            $SuccessfulBuilds++
        }
        catch {
            Write-Host "Failed to build Linux $runtime" -ForegroundColor Red
        }
    }
}

Write-Host ""
Write-Host "🎉 Build process complete!" -ForegroundColor Green
Write-Host "📊 Built $SuccessfulBuilds out of $TotalBuilds targets successfully" -ForegroundColor Cyan

if ($SuccessfulBuilds -gt 0) {
    Write-Host ""
    Write-Host "📋 Built executables are located in:" -ForegroundColor White
    if ($Windows) {
        Write-Host "   Windows: .\dist\windows\" -ForegroundColor Gray
    }
    if ($MacOS) {
        Write-Host "   macOS:   .\dist\macos\" -ForegroundColor Gray
    }
    if ($Linux) {
        Write-Host "   Linux:   .\dist\linux\" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "💡 Usage example:" -ForegroundColor Yellow
    Write-Host "   app(.exe) <host> <port> <username> <password> <public_key_file>" -ForegroundColor Gray
}
