<p align="center">
  <img src="icon.png" alt="StartTunnel" width="120">
</p>

<h1 align="center">StartTunnel</h1>

<p align="center">
  A self-hosted WireGuard VPN optimized for creating VLANs and reverse tunneling to personal servers.
</p>

## About

This repo hosts the StartTunnel installer script via GitHub Pages. The source code and release binaries live in the [StartOS monorepo](https://github.com/Start9Labs/start-os).

For full documentation — features, security, CLI reference, and a detailed comparison with Cloudflare Tunnel and Tailscale — see the [StartTunnel docs](https://docs.start9.com/start-tunnel).

## Install

SSH into a Debian 12+ VPS and run:

```bash
curl -sSL https://start9labs.github.io/start-tunnel/install.sh | sh
```

Then initialize the web interface:

```bash
start-tunnel web init
```

You will be guided through setup and shown your web URL, password, and Root CA certificate.

## Update

Re-run the install command. The installer detects the existing installation, prompts for confirmation, and restarts the service.

## Requirements

- Debian 12+ (Bookworm or newer)
- x86_64, aarch64, or riscv64
- Root access
- Dedicated VPS (the installer manages firewall rules — do not run alongside other services)
- Public IP (required for clearnet port forwarding; not required for private VPN use)

## Links

- [StartTunnel Documentation](https://docs.start9.com/start-tunnel)
- [Source Code](https://github.com/Start9Labs/start-os)
- [Report an Issue](https://github.com/Start9Labs/start-os/issues)
- [Start9 Website](https://start9.com)
