# ssh-copy-id-net

A .NET cross-platform implementation of the `ssh-copy-id` utility for copying SSH public keys to remote servers and setting up passwordless SSH authentication.

## Overview

This tool automates the process of copying your SSH public key to a remote server's `~/.ssh/authorized_keys` file, enabling passwordless SSH authentication. It's particularly useful when the standard `ssh-copy-id` utility is not available or when you need a cross-platform solution.

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

Check the [Releases](../../releases) page for pre-built binaries for your platform.

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
