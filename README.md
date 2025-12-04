<p align="center">
  <img src="icon.png" alt="Project Logo" width="21%">
</p>

# Start Tunnel Setup Script

This repository contains the installer script for StartTunnel, a self-hosted WireGuard VPN server optimized for reverse tunneling access. The script provides a complete, turnkey installation on Debian-based VPS systems.

## Quick Install

The easiest way to install StartTunnel on your VPS:

```bash
curl -sSL https://start9labs.github.io/start-tunnel | sh
```

This one-line command will:
- Validate your system (Debian 12+ required)
- Configure networking (DNS, firewall)
- Download and install StartTunnel
- Automatically start and enable the service
- Show instructions to initialize the web interface (fresh installs)
- Auto-display web interface info on reinstall

## Alternative Installation Methods

### Download and Execute

```bash
curl -fsSL https://start9labs.github.io/start-tunnel -o install.sh
chmod +x install.sh
./install.sh
```

### Manual Script Execution

If you've cloned this repository:

```bash
chmod +x start-tunnel-setup.sh
sudo ./start-tunnel-setup.sh
```

## Requirements

- **Operating System:** Debian 12+ (Bookworm or newer)
- **Architecture:** x86_64, aarch64, or riscv64
- **Access:** Root privileges (script will auto-escalate with sudo if needed)
- **Network:** Internet connectivity for package downloads

## Features

- ✅ Automatic system validation and preparation
- ✅ DNS configuration (if needed)
- ✅ Firewall management (disables system firewalls, StartTunnel manages its own)
- ✅ IP forwarding (handled automatically by the deb package)
- ✅ Service auto-start and enable on boot
- ✅ Clear instructions for web interface setup (fresh installs)
- ✅ Auto-display web interface info on reinstall
- ✅ Support for fresh installs and reinstalls
- ✅ Clean, color-coded terminal interface

## Documentation

For detailed documentation about the installer's logic, functionality, and system impact, see [INSTALL.md](INSTALL.md).

## Contributing

Your contributions make this project better! Pull requests and issues are welcome.
