# ssh-copy-id-net

A .NET cross-platform implementation of the `ssh-copy-id` utility for copying SSH public keys to remote servers and setting up passwordless SSH authentication.

## Overview

This tool automates the process of copying your SSH public key to a remote server's `~/.ssh/authorized_keys` file, enabling passwordless SSH authentication. It's particularly useful when the standard `ssh-copy-id` utility is not available or when you need a cross-platform solution.

## Why

When working with newly created servers from macOS or Linux, developers can easily combine `sshpass` with `ssh-copy-id` commands to quickly setup key-based authentication. This workflow is perfect for automation and scripting:

```bash
# Easy setup on Unix-like systems
sshpass -p 'password' ssh-copy-id user@server.com
```

However, doing the same on Windows is impossible because there is no native `ssh-copy-id` utility for Windows. This creates a significant gap in cross-platform development workflows and server provisioning scripts.

**This tool is designed to fill that gap**, providing a unified, cross-platform solution that works identically on Windows, macOS, and Linux. Now you can use the same automation scripts across all platforms without worrying about OS-specific SSH utilities.

## Features

- ✅ **Cross-platform**: Works on Windows, macOS, and Linux
- ✅ **Automatic setup**: Creates `.ssh` directory and sets correct permissions
- ✅ **Connection validation**: Tests SSH connectivity before and after key installation
- ✅ **Error handling**: Provides clear error messages and troubleshooting guidance
- ✅ **Standalone executable**: No .NET runtime required (when published as self-contained)

## Prerequisites

- .NET 8.0 SDK (for building from source)
- SSH access to the target server with password authentication
- A valid SSH public key file

## Installation

### Option 1: Download Pre-built Binary

Pre-built binaries are automatically created for all supported platforms when a new release is tagged. Check the [Releases](../../releases) page for the latest binaries.

**Supported platforms:**
- **Windows**: x64, ARM64 (`.zip` archives)
- **macOS**: x64 (Intel), ARM64 (Apple Silicon) (`.tar.gz` archives)  
- **Linux**: x64, ARM64 (`.tar.gz` archives)

**Download and install:**
1. Go to the [Releases](../../releases) page
2. Download the appropriate archive for your platform
3. Extract the archive to get the `ssh-copy-id-net` executable
4. (Optional) Add the executable to your PATH for system-wide access

**Quick install examples:**
```bash
# macOS/Linux - Extract and make executable
tar -xzf ssh-copy-id-net-*-osx-arm64.tar.gz
chmod +x ssh-copy-id-net
sudo mv ssh-copy-id-net /usr/local/bin/

# Windows - Extract from zip and optionally add to PATH
# Extract ssh-copy-id-net.exe from the downloaded .zip file
```

#### macOS-Specific Setup

When downloading pre-built binaries from GitHub releases on macOS, you may encounter security restrictions due to Apple's Gatekeeper. Follow these steps to properly set up the executable:

**1. Extract and sign the binary:**
```bash
# Extract the downloaded archive
tar -xzf ssh-copy-id-net-*-osx-*.tar.gz

# Remove quarantine attribute (required for downloaded files)
xattr -d com.apple.quarantine ssh-copy-id-net

# Sign the binary to satisfy macOS security requirements
codesign --force --deep --sign - ssh-copy-id-net

# Make the binary executable
chmod +x ssh-copy-id-net

# Optional: Move to a directory in your PATH for system-wide access
sudo mv ssh-copy-id-net /usr/local/bin/
```

**2. Alternative: If you encounter "cannot be opened because it is from an unidentified developer":**
```bash
# Remove quarantine and sign in one step
xattr -d com.apple.quarantine ssh-copy-id-net && codesign --force --deep --sign - ssh-copy-id-net
```

**Why these steps are needed:**
- **Quarantine removal**: macOS automatically marks files downloaded from the internet with a quarantine attribute
- **Code signing**: Signing with an ad-hoc signature (`-`) satisfies macOS's requirement for executable code to be signed
- **Without these steps**: macOS will prevent the binary from running and show security warnings

**Note:** These steps are only required for binaries downloaded from GitHub releases. If you build from source locally, these security restrictions don't apply.

### Option 2: Build from Source

1. Clone the repository:
   ```bash
   git clone https://github.com/maxshlain/ssh-copy-id-net.git
   cd ssh-copy-id-net
   ```

2. Build the project:
   ```bash
   cd src/app
   dotnet build
   ```

3. Run the application:
   ```bash
   dotnet run -- <host> <port> <username> <password> <public_key_file>
   ```

### Option 3: Create Standalone Executable

#### Quick Start

For most users, the easiest approach is to use the cross-platform PowerShell script:

```powershell
# Build for all platforms
./publish/publish-all.ps1 -All

# Build for specific platforms
./publish/publish-all.ps1 -Windows -MacOS

# Get help
./publish/publish-all.ps1 -Help
```

#### Platform-Specific Scripts

**For macOS/Linux Developers (using Bash):**
```bash
# Build for macOS
chmod +x publish/mac.bash
./publish/mac.bash

# Build for Windows
chmod +x publish/win.bash  
./publish/win.bash
```

**For Windows Developers (using PowerShell):**
```powershell
# Build for Windows
.\publish\win.ps1

# Build for macOS
.\publish\mac.ps1

# Build for all platforms
.\publish\publish-all.ps1 -All
```

**For Cross-Platform (using PowerShell Core):**
```powershell
# Available on all platforms - build for any target
./publish/mac.ps1      # macOS executables
./publish/win.ps1      # Windows executables
./publish/linux.ps1    # Linux executables
./publish/publish-all.ps1 -Linux  # Linux executables
```

**For Linux/Debian Developers:**
```bash
# Build Linux binaries
./publish/linux.bash

# Create Debian packages (.deb)
./publish/debian.bash

# PowerShell alternatives
./publish/linux.ps1
./publish/debian.ps1
```

#### Output Locations

All build scripts create executables in the `dist/` directory:
- **Windows**: `dist/windows/win-x64/app.exe`, `dist/windows/win-arm64/app.exe`
- **macOS**: `dist/macos/osx-x64/app`, `dist/macos/osx-arm64/app` 
- **Linux**: `dist/linux/linux-x64/app`, `dist/linux/linux-arm64/app`
- **Debian**: `dist/debian/ssh-copy-id-net_1.0.0_amd64.deb`, `dist/debian/ssh-copy-id-net_1.0.0_arm64.deb`

#### Runtime Identification

**Windows:**
- **x64**: Most common Windows PCs and servers
- **ARM64**: Surface Pro X, newer ARM-based Windows devices

**macOS:**
- **x64**: Intel-based Macs (2020 and earlier)
- **ARM64**: Apple Silicon Macs (M1, M2, M3, etc.)

**Linux:**
- **x64**: Most Linux servers and desktops  
- **ARM64**: ARM-based Linux systems, Raspberry Pi 4+

## Usage

### Using Pre-built Binary

If you downloaded a pre-built binary from the releases:

```bash
ssh-copy-id-net <host> <port> <username> <password> <public_key_file>
```

### Using Development Build

If you built from source:

```bash
app <host> <port> <username> <password> <public_key_file>
```

### Parameters

- **host**: SSH server hostname or IP address
- **port**: SSH server port (1-65535)
- **username**: SSH username
- **password**: SSH password for authentication
- **public_key_file**: Path to your SSH public key file

### Examples

**Using pre-built binary:**
```bash
# Copy key to a server on standard SSH port
ssh-copy-id-net example.com 22 user secretpass ~/.ssh/id_rsa.pub

# Copy key to a server on custom port
ssh-copy-id-net 192.168.1.100 2222 deploy mypass /home/user/.ssh/deploy_key.pub

# Copy key to localhost for testing
ssh-copy-id-net 127.0.0.1 22 admin password /Users/admin/.ssh/id_ed25519.pub

# Windows example (using .exe extension)
ssh-copy-id-net.exe example.com 22 user secretpass C:\Users\user\.ssh\id_rsa.pub
```

**Using development build:**
```bash
# Copy key to a server on standard SSH port
app example.com 22 user secretpass ~/.ssh/id_rsa.pub

# Copy key to a server on custom port
app 192.168.1.100 2222 deploy mypass /home/user/.ssh/deploy_key.pub

# Copy key to localhost for testing
app 127.0.0.1 22 admin password /Users/admin/.ssh/id_ed25519.pub

# Windows example (using .exe extension)
app.exe example.com 22 user secretpass C:\Users\user\.ssh\id_rsa.pub
```

## How It Works

1. **Pre-check**: Tests if SSH key-based authentication is already working
2. **Connection**: Connects to the SSH server using password authentication
3. **Directory Setup**: Creates `~/.ssh` directory if it doesn't exist
4. **Permissions**: Sets correct permissions (700) for the `.ssh` directory
5. **Key Installation**: Appends the public key to `~/.ssh/authorized_keys`
6. **File Permissions**: Sets correct permissions (600) for the `authorized_keys` file
7. **Verification**: Tests the key-based authentication to confirm success

## Output Example

```
Launching SSH connection to example.com:22...
Connecting to SSH server...
✓ Successfully connected to SSH server!
✓ Successfully create remote .ssh directory if it doesn't exist...
✓ Successfully set correct permissions for .ssh directory...
✓ Successfully copy public key to remote .ssh directory...
✓ Successfully set correct permissions for authorized_keys file...
✓ SSH server is reachable with key-based authentication.

    You can connect to your server with
        ssh -p 22 user@example.com
```

## Error Handling

The application provides detailed error messages for common issues:

- **Authentication errors**: Suggests checking username and password
- **Connection errors**: Suggests checking host and port configuration
- **File not found**: Validates that the public key file exists before proceeding
- **Permission errors**: Reports SSH command execution failures with details

## Security Considerations

- Passwords are passed as command-line arguments (visible in process lists)
- Consider using environment variables or secure input methods for production use
- The tool only appends to `authorized_keys` (doesn't overwrite existing keys)
- Proper file permissions are set automatically (700 for `.ssh`, 600 for `authorized_keys`)

## Dependencies

- **SSH.NET** (2023.0.1): Provides SSH client functionality
- **.NET 8.0**: Target framework

## Project Structure

```
├── LICENSE                  # MIT license file
├── README.md               # This file
├── publish/                # Build scripts directory
│   ├── mac.bash            # macOS standalone build script (Bash)
│   ├── win.bash            # Windows standalone build script (Bash)
│   ├── linux.bash          # Linux standalone build script (Bash)
│   ├── mac.ps1             # macOS standalone build script (PowerShell)
│   ├── win.ps1             # Windows standalone build script (PowerShell)
│   ├── linux.ps1           # Linux standalone build script (PowerShell)
│   ├── debian.bash         # Debian package builder (Bash)
│   ├── debian.ps1          # Debian package builder (PowerShell)
│   └── publish-all.ps1     # Cross-platform build script with flexible options
└── src/
    └── app/
        ├── app.csproj           # Project file with dependencies
        ├── Program.cs           # Application entry point
        ├── SshApp.cs           # Main SSH operations logic
        ├── ArgumentsParser.cs   # Command-line argument parsing
        ├── ConnectionTester.cs  # SSH connection validation
        └── SshConnectionArgs.cs # Connection parameters model
```

## Publishing Scripts

The `publish/` directory contains multiple build scripts to create standalone executables:

### Available Scripts

- **Bash Scripts** (macOS/Linux): `mac.bash`, `win.bash`, `linux.bash`, `debian.bash`
- **PowerShell Scripts** (Cross-platform): `mac.ps1`, `win.ps1`, `linux.ps1`, `debian.ps1`, `publish-all.ps1`

### Script Features

All scripts provide:
- ✅ Error handling and validation
- 🧹 Automatic cleanup of previous builds
- 📁 File size reporting
- 🎯 Single-file executable generation
- 📋 Clear usage instructions
- 💡 Architecture detection guidance

The PowerShell scripts additionally offer:
- 🎨 Colored output for better readability
- 🔧 Cross-platform compatibility  
- ⚙️ Flexible build options (`publish-all.ps1`)
- 📊 Build summary reporting

### Prerequisites for Building

- .NET 8.0 SDK installed
- PowerShell Core (for .ps1 scripts) - included with Windows, available for macOS/Linux
- For Debian packages: `dpkg-dev` package on Linux systems

## Debian Package Installation

### Installing from .deb Package

1. Build the Debian package:
   ```bash
   ./publish/debian.bash
   ```

2. Install the package:
   ```bash
   # For x64 systems
   sudo dpkg -i dist/debian/ssh-copy-id-net_1.0.0_amd64.deb
   
   # For ARM64 systems  
   sudo dpkg -i dist/debian/ssh-copy-id-net_1.0.0_arm64.deb
   ```

3. Use the installed command:
   ```bash
   ssh-copy-id-net example.com 22 user password ~/.ssh/id_rsa.pub
   ```

### Uninstalling

```bash
sudo dpkg -r ssh-copy-id-net
```

### Package Features

The Debian package provides:
- ✅ System-wide installation in `/usr/local/bin/`
- ✅ Man page documentation (`man ssh-copy-id-net`)
- ✅ Proper Debian package metadata
- ✅ Clean uninstallation support
- ✅ Both x64 and ARM64 architecture support

## Releases and CI/CD

### Automated Releases

This project uses GitHub Actions to automatically build and release cross-platform binaries whenever a new version tag is pushed. All builds are performed on a single Ubuntu runner using .NET's excellent cross-compilation capabilities.

**Release Process:**
1. Tag a new version: `git tag v1.2.3`
2. Push the tag: `git push origin v1.2.3`
3. GitHub Actions will automatically:
   - Cross-compile binaries for all supported platforms from Ubuntu
   - Create release archives (.zip for Windows, .tar.gz for macOS/Linux)
   - Create a GitHub release with all artifacts
   - Generate release notes with download links

**Supported Build Targets:**
- **Windows**: win-x64, win-arm64
- **macOS**: osx-x64 (Intel), osx-arm64 (Apple Silicon)
- **Linux**: linux-x64, linux-arm64

**Build Features:**
- Cross-platform compilation from single Ubuntu runner
- Self-contained executables (no .NET runtime required)
- Single-file deployment
- Consistent build environment across all platforms

### Creating a New Release

To create a new release with version tag v0.1.5 and a custom message:

1. **Create the tag with a message:**
   ```bash
   git tag -a v0.1.5 -m "message"
   ```

2. **Push the tag to trigger the release:**
   ```bash
   git push origin v0.1.5
   ```


### Manual Building

For development or custom builds, you can still use the PowerShell scripts in the `publish/` directory:

```powershell
# Build for all platforms
./publish/publish-all.ps1 -All

# Build for specific platforms
./publish/publish-all.ps1 -Windows -MacOS

# Platform-specific builds
./publish/win.ps1     # Windows only
./publish/mac.ps1     # macOS only  
./publish/linux.ps1   # Linux only
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Inspired by the classic Unix `ssh-copy-id` utility
- Built with [SSH.NET](https://github.com/sshnet/SSH.NET) library
- Compatible with OpenSSH and most SSH server implementations

## Troubleshooting

### Common Issues

**"Connection failed"**
- Verify the hostname/IP and port are correct
- Check if the SSH service is running on the target server
- Ensure network connectivity to the target server

**"Authentication failed"**
- Double-check the username and password
- Verify the user account exists on the target server

**"Public key file not found"**
- Ensure the path to your public key file is correct
- Generate SSH keys if you don't have them: `ssh-keygen -t rsa -b 4096`

**"Permission denied after key installation"**
- Check if the SSH server allows key-based authentication
- Verify `PubkeyAuthentication yes` is set in `/etc/ssh/sshd_config`
- Ensure the user's home directory permissions are correct

### Platform-Specific Notes

**Windows Users:**
- Use backslashes (`\`) in file paths or escape forward slashes
- SSH client must be available (install OpenSSH or use Git Bash/WSL)
- When using Windows paths, enclose in quotes if they contain spaces
- Example: `app.exe example.com 22 user pass "C:\Users\My User\.ssh\id_rsa.pub"`

**macOS/Linux Users:**
- Standard Unix file paths with forward slashes work as expected
- Ensure the executable has proper permissions (`chmod +x app`)
