<p align="center">
  <img src="icon.png" alt="StartTunnel" width="120">
</p>

<h1 align="center">StartTunnel</h1>

<p align="center">
  A self-hosted WireGuard VPN optimized for creating VLANs and reverse tunneling to personal servers.
</p>

## Why StartTunnel?

Think of it as a "virtual router in the cloud." Use it for private remote access to self-hosted services, or to expose services to the public Internet without revealing your server's IP address.

- **Clearnet hosting** like Cloudflare Tunnels, but you control the server
- **Private access** like Tailscale, but fully self-hosted
- **Dead simple** — one command to install, one command to connect
- **Open source** — audit it, fork it, own it

## Features

- **Create Subnets** — Each subnet creates a private VLAN, similar to the LAN created by a home router
- **Add Devices** — Servers, phones, laptops get a LAN IP and unique WireGuard config
- **Forward Ports** — Expose specific ports on specific devices to the public Internet

## Install

### 1. Get a VPS

Rent a cheap Debian 12+ VPS with a dedicated public IP. Minimum CPU/RAM/disk is fine. For bandwidth, no need to exceed your home Internet's upload speed.

### 2. Run the installer

SSH into your VPS and run:

```bash
curl -sSL https://start9labs.github.io/start-tunnel/install.sh | sh
```

### 3. Initialize the web interface

```bash
start-tunnel web init
```

You'll receive a URL, password, and Root CA certificate. To access the web interface without browser warnings, [trust the Root CA on your device](https://docs.start9.com).

## Updating

Re-run the install command:

```bash
curl -sSL https://start9labs.github.io/start-tunnel/install.sh | sh
```

## CLI

StartTunnel can be fully managed from the command line:

```bash
start-tunnel --help
```

## Requirements

- Debian 12+ (Bookworm or newer)
- x86_64, aarch64, or riscv64
- Root access
- Dedicated public IP

## Source Code

This repo contains the installer and release automation. The StartTunnel source code lives in the [StartOS monorepo](https://github.com/Start9Labs/start-os).

## Learn More

- [StartOS Documentation](https://docs.start9.com)
- [Start9 Website](https://start9.com)
