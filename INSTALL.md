# StartTunnel VPS Installer - Logic Map & Documentation

This documentation provides a complete understanding of the installer script's logic, functionality, and system impact. It can be used as a reference for maintenance, troubleshooting, and understanding the installation process.

## 📋 Executive Summary

This script performs a **complete, turnkey installation** of StartTunnel on a Debian-based VPS, transforming a fresh server into a dedicated WireGuard VPN server with zero manual configuration required.

**What it does:**
- Validates Debian 12+ system
- Optimizes VPS by removing unnecessary packages
- Configures networking (IP forwarding, DNS)
- Installs WireGuard and StartTunnel
- Configures web interface
- Starts and enables the VPN service

---

## 🗺️ High-Level Execution Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    SCRIPT EXECUTION START                   │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                   PRE-FLIGHT CHECKS                         │
├─────────────────────────────────────────────────────────────┤
│ 1. Check OS Type (Linux only)                               │
│ 2. Verify Debian-based (Debian/Ubuntu/Raspbian)             │
│ 3. Check Debian version (12+)                               │
│ 4. Verify root privileges (escalate with sudo if needed)    │
│ 5. Ensure curl or wget exists (install curl if missing)     │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              INSTALLATION MODE DETECTION                    │
├─────────────────────────────────────────────────────────────┤
│ Check if StartTunnel is already installed                   │
│                                                             │
│ ┌──────────────────┐              ┌────────────────────┐    │
│ │ Already Installed│              │ Not Installed      │    │
│ │ (Reinstall Mode) │              │ (Fresh Install)    │    │
│ └────────┬─────────┘              └─────────┬──────────┘    │
│          │                                   │              │
│          ▼                                   ▼              │
│   Ask: Reinstall? [y/N]              Set: FRESH_INSTALL     │
│          │                                                  │
│   ┌──────┴──────┐                                           │
│   │             │                                           │
│   ▼             ▼                                           │
│  Yes           No                                           │
│   │             │                                           │
│   │             └──> Exit (no changes)                      │
│   │                                                         │
│   └──> Continue with reinstall                              │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                 SYSTEM PREPARATION                          │
│             (Fresh Install or Reinstall)                    │
├─────────────────────────────────────────────────────────────┤
│ 1. Update package lists (apt-get update)                    │
│ 2. Upgrade all packages (apt-get upgrade)                   │
│ 3. Configure DNS (systemd-resolved or /etc/resolv.conf)     │
│ 4. Verify DNS resolution works                              │
│ 5. Disable all firewalls (UFW, firewalld, etc.)             │
│ 6. Remove unnecessary packages (web servers, mail, etc.)    │
│ 7. Install required packages (WireGuard, iptables, etc.)    │
│ 8. Configure IP forwarding (IPv4 & IPv6)                    │
│ 9. Re-verify DNS after changes                              │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              STARTTUNNEL INSTALLATION                       │
├─────────────────────────────────────────────────────────────┤
│ 1. Detect system architecture (x86_64/aarch64/riscv64)      │
│ 2. Download .deb package from GitHub releases               │
│ 3. Install package with apt/dpkg                            │
│ 4. Verify installation (check binary exists)                │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│               SERVICE CONFIGURATION                         │
├─────────────────────────────────────────────────────────────┤
│ 1. Reload systemd daemon                                    │
│ 2. Enable start-tunneld.service (boot persistence)          │
│ 3. Start start-tunneld.service                              │
│ 4. Wait 3 seconds for initialization                        │
│ 5. Verify service is running                                │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│            WEB INTERFACE CONFIGURATION                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ ┌──────────────────┐              ┌────────────────────┐    │
│ │ Fresh Install    │              │ Reinstall Mode     │    │
│ └────────┬─────────┘              └─────────┬──────────┘    │
│          │                                   │              │
│          ▼                                   ▼              │
│   Ask: Configure? [Y/n]          Ask: Reconfigure? [y/N]    │
│          │                                   │              │
│   ┌──────┴──────┐                     ┌──────┴──────┐       │
│   │             │                     │             │       │
│   ▼             ▼                     ▼             ▼       │
│  Yes           No                    Yes           No       │
│   │             │                     │             │       │
│   │             └──> Skip             │             └──>    │
│   │                                   │              Keep   │
│   │                                   │             Existing│
│   ▼                                   ▼                     │
│ Run:                           1. start-tunnel web reset    │
│ start-tunnel web init          2. start-tunnel web init     │
│                                                             │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                SYSTEM VERIFICATION                          │
├─────────────────────────────────────────────────────────────┤
│ ✓ DNS resolution working                                    │
│ ✓ WireGuard tools installed                                 │
│ ✓ IPv4 forwarding enabled                                   │
│ ✓ Firewalls disabled                                        │
│ ✓ start-tunnel binary available                             │
│ ✓ start-tunneld service running                             │
│ ✓ Service enabled on boot                                   │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                  SUCCESS DISPLAY                            │
├─────────────────────────────────────────────────────────────┤
│ • Show server IP address                                    │
│ • Display service management commands                       │
│ • Show configuration paths                                  │
│ • Provide documentation links                               │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔧 Function Reference Guide

### **Utility Functions**

| Function | Purpose | Dependencies |
|----------|---------|--------------|
| `err()` | Display error message and exit | None |
| `warn()` | Display warning message | None |
| `info()` | Display informational message | None |
| `success()` | Display success message | None |

---

### **Phase 1: Pre-Flight Checks**

#### `check_debian()`
**Purpose:** Validates the operating system
**Flow:**
1. Check if OS is Linux (uname -s)
2. Verify /etc/os-release exists
3. Read distribution ID from os-release
4. Confirm it's Debian-based (debian/ubuntu/raspbian)
5. For Debian: verify version is 12+
6. Exit with error if any check fails

**Exit Conditions:**
- Non-Linux OS
- Missing /etc/os-release
- Non-Debian distribution
- Debian version < 12

---

#### `ensure_root()`
**Purpose:** Ensures script runs with root privileges
**Flow:**
1. Check if current user ID is 0 (root)
2. If not root:
   - Check if sudo is available
   - Re-execute script with sudo
   - Original process is replaced

**Exit Conditions:**
- Non-root user without sudo

---

#### `ensure_download_tool()`
**Purpose:** Ensures curl or wget is available for downloads
**Flow:**
1. Check if curl exists → Success
2. Check if wget exists → Success
3. If neither exists:
   - Run apt-get update
   - Install curl silently
   - Verify installation

**Exit Conditions:**
- Cannot install curl

---

### **Phase 2: Installation Mode Detection**

#### `check_existing_installation()`
**Purpose:** Detects if StartTunnel is already installed
**Flow:**
1. Query dpkg for start-tunnel package
2. If found:
   - Get installed version
   - Check service status
   - Prompt user: "Reinstall? [y/N]"
   - If Yes: Set REINSTALL_MODE=true, stop service
   - If No: Exit gracefully
3. If not found:
   - Set FRESH_INSTALL=true

**Variables Set:**
- `REINSTALL_MODE` (true/false)
- `FRESH_INSTALL` (true/false)
- `INSTALLED_VERSION` (version string)

---

#### `check_service_status()`
**Purpose:** Checks current state of start-tunneld service
**Flow:**
1. Check if service is active (running)
2. Check if service is enabled (boot persistence)

**Variables Set:**
- `SERVICE_WAS_RUNNING` (true/false)
- `SERVICE_WAS_ENABLED` (true/false)

---

#### `stop_service()`
**Purpose:** Gracefully stops the service if it was running
**Dependencies:** `SERVICE_WAS_RUNNING` must be set
**Flow:**
1. If service was running:
   - Execute systemctl stop
   - Report success or warning

---

### **Phase 3: System Preparation**

#### `update_system()`
**Purpose:** Updates all system packages
**Flow:**
1. Run apt-get update (refresh package lists)
2. Run apt-get upgrade (upgrade all packages)

**Network Required:** Yes

---

#### `configure_dns()`
**Purpose:** Configures reliable DNS resolution
**Flow:**
1. Check if systemd-resolved is active:
   - **If active:**
     - Backup /etc/systemd/resolved.conf
     - Add DNS servers: 8.8.8.8, 1.1.1.1, etc.
     - Restart systemd-resolved
     - Fix /etc/resolv.conf symlink
   - **If not active:**
     - Backup /etc/resolv.conf
     - Create new resolv.conf with public DNS
     - Make file immutable (chattr +i)

**DNS Servers Used:**
- Primary: 8.8.8.8 (Google), 1.1.1.1 (Cloudflare)
- Fallback: 8.8.4.4, 1.0.0.1, 9.9.9.9 (Quad9)

---

#### `verify_dns()`
**Purpose:** Tests DNS resolution is working
**Flow:**
1. Try getent hosts github.com
2. If fails, try host github.com
3. If fails, try nslookup github.com
4. If fails, try ping github.com
5. Report success or warning

**Returns:** 0 (success) or 1 (warning)

---

#### `disable_firewalls()`
**Purpose:** Disables system firewalls (StartTunnel manages its own)
**Flow:**
1. Check for UFW:
   - If active: disable, stop, disable service
2. Check for firewalld:
   - If active: stop, disable service
3. Check for netfilter-persistent:
   - If enabled: stop, disable service

**Firewalls Removed:**
- UFW (Uncomplicated Firewall)
- firewalld
- netfilter-persistent

---

#### `remove_unnecessary_packages()`
**Purpose:** Removes packages not needed for VPN server
**Flow:**
1. Build list of unnecessary packages
2. Check which are actually installed
3. Remove with apt-get remove --purge
4. Run autoremove and autoclean

**Packages Removed:**
- Desktop environments (X11, GNOME, KDE, XFCE)
- Web servers (Apache, Nginx, Lighttpd)
- Mail servers (Postfix, Exim, Sendmail)
- Database servers (MySQL, MariaDB, PostgreSQL)
- FTP servers (vsftpd, proftpd)
- DNS servers (bind9, named, dnsmasq)
- Development tools (gcc, make, build-essential)
- Other services (Samba, CUPS, Bluetooth)

**Packages KEPT:**
- DNS client tools (dnsutils, host, nslookup)
- System essentials
- SSH server

---

#### `install_dependencies()`
**Purpose:** Installs packages required for WireGuard/StartTunnel
**Flow:**
1. Install package list with apt-get
2. Load WireGuard kernel module (modprobe wireguard)
3. Verify module loaded

**Packages Installed:**
- ca-certificates
- gnupg
- wireguard
- wireguard-tools
- iptables
- iproute2
- openresolv
- dnsutils
- iputils-ping

---

#### `configure_ip_forwarding()`
**Purpose:** Enables IP forwarding for VPN routing
**Flow:**
1. Edit /etc/sysctl.conf:
   - Set net.ipv4.ip_forward=1
   - Set net.ipv6.conf.all.forwarding=1
2. Apply changes with sysctl -p

**System Files Modified:**
- /etc/sysctl.conf

---

### **Phase 4: StartTunnel Installation**

#### `detect_architecture()`
**Purpose:** Detects CPU architecture for correct package
**Flow:**
1. Run uname -m
2. Map to package architecture:
   - x86_64 → x86_64 (Intel/AMD64)
   - aarch64 → aarch64 (ARM64)
   - riscv64 → riscv64 (RISC-V 64)
3. Error if unsupported

**Variables Set:**
- `ARCH` (package suffix)
- `DISPLAY_ARCH` (human-readable)

---

#### `download_package()`
**Purpose:** Downloads StartTunnel .deb package
**Flow:**
1. Build package filename: `start-tunnel-{VERSION}-{HASH}.dev_{ARCH}.deb`
2. Build download URL from GitHub releases
3. Download with curl or wget
4. Save to temporary directory

**Example URL:**
```
https://github.com/Start9Labs/start-os/releases/download/v0.4.0-alpha.13/start-tunnel-0.4.0-alpha.13-2fbaaeb.dev_aarch64.deb
```

**Exit Conditions:**
- Download fails (404, network error)

---

#### `install_package()`
**Purpose:** Installs the downloaded .deb package
**Flow:**
1. If reinstall mode: use apt-get --reinstall
2. If fresh install: use apt install
3. Fallback to dpkg -i if apt fails
4. Run apt-get install -f to resolve dependencies
5. Delete temporary files

**Exit Conditions:**
- Installation fails after all attempts

---

#### `verify_installation()`
**Purpose:** Confirms StartTunnel is installed correctly
**Flow:**
1. Check if start-tunnel command exists
2. Try to get version (start-tunnel --version)
3. Fallback to dpkg query
4. Error if not found

**Exit Conditions:**
- Binary not found after installation

---

### **Phase 5: Service Configuration**

#### `enable_and_start_service()`
**Purpose:** Starts and enables the StartTunnel service
**Flow:**
1. Reload systemd daemon (daemon-reload)
2. Enable service for boot (systemctl enable)
3. Start or restart service:
   - If already running: restart
   - If not running: start
4. Wait 3 seconds for initialization
5. Verify service is active

**Service:** `start-tunneld.service`

**Exit Conditions:**
- Service fails to start (warning only, continues)

---

### **Phase 6: Web Interface Configuration**

#### `configure_web_interface()`
**Purpose:** Interactive web UI setup
**Flow:**

**Prerequisites:**
- Service MUST be running (checked at function start)

**For Fresh Install:**
1. Prompt: "Configure Web Interface now? [Y/n]"
2. If Yes: Run `start-tunnel web init` (interactive)
3. If No: Skip with message

**For Reinstall:**
1. Prompt: "Reconfigure Web Interface? [y/N]"
2. If Yes:
   - Run `start-tunnel web reset` (wipes config)
   - Wait 2 seconds
   - Run `start-tunnel web init` (interactive)
3. If No: Keep existing configuration

**Interactive Commands:**
- `start-tunnel web init` - Prompts for password, sets up SSL cert
- `start-tunnel web reset` - Silently wipes all web config

**Exit Conditions:**
- Web init fails (warning only, continues)
- Service not running (tries to start it first)

---

### **Phase 7: Verification**

#### `verify_system()`
**Purpose:** Runs final checks on system configuration
**Checks:**
1. ✓ DNS resolution working
2. ✓ WireGuard tools installed (wg command)
3. ✓ IPv4 forwarding enabled
4. ✓ System firewalls disabled
5. ✓ start-tunnel binary available
6. ✓ start-tunneld service running
7. ✓ Service enabled on boot

**Output:** Success/warning for each check

---

#### `get_server_ip()`
**Purpose:** Retrieves public IP address of server
**Flow:**
1. Try curl ifconfig.me
2. Fallback to icanhazip.com
3. Fallback to api.ipify.org
4. Fallback to local IP from `ip addr`

**Returns:** IP address string or empty

---

#### `display_success()`
**Purpose:** Shows final success message with info
**Output:**
- Success banner
- Server IP address
- Service management commands
- Configuration file paths
- Documentation links
- Firewall notes

---

## 📊 State Management

### Global Variables

| Variable | Type | Purpose | Set By |
|----------|------|---------|--------|
| `REINSTALL_MODE` | boolean | True if reinstalling existing installation | `check_existing_installation()` |
| `FRESH_INSTALL` | boolean | True if no previous installation | `check_existing_installation()` |
| `SERVICE_WAS_RUNNING` | boolean | Service state before script ran | `check_service_status()` |
| `SERVICE_WAS_ENABLED` | boolean | Service enabled before script ran | `check_service_status()` |
| `INSTALLED_VERSION` | string | Previously installed version | `check_existing_installation()` |
| `ARCH` | string | System architecture (x86_64/aarch64/riscv64) | `detect_architecture()` |
| `DISPLAY_ARCH` | string | Human-readable architecture | `detect_architecture()` |
| `PACKAGE_PATH` | string | Path to downloaded .deb file | `download_package()` |

---

## 🔀 Decision Trees

### Installation Mode Decision

```
Is start-tunnel installed?
├─ No → FRESH_INSTALL=true → Continue
└─ Yes → Display current version
         └─ Prompt: "Reinstall? [y/N]"
            ├─ Yes → REINSTALL_MODE=true
            │        └─ Stop service
            │           └─ Continue
            └─ No → Exit (no changes made)
```

### System Preparation Decision

```
Is FRESH_INSTALL or REINSTALL_MODE true?
├─ Yes → Run full system preparation:
│        ├─ Update packages
│        ├─ Configure DNS
│        ├─ Disable firewalls
│        ├─ Remove unnecessary packages
│        ├─ Install dependencies
│        └─ Configure IP forwarding
└─ No → Skip system preparation
```

### Web Interface Configuration Decision

```
Mode: FRESH_INSTALL
└─ Prompt: "Configure Web Interface now? [Y/n]"
   ├─ Yes (default) → start-tunnel web init
   └─ No → Skip

Mode: REINSTALL_MODE
└─ Prompt: "Reconfigure Web Interface? [y/N]"
   ├─ Yes → start-tunnel web reset
   │        → start-tunnel web init
   └─ No (default) → Keep existing config
```

---

## ⚠️ Error Handling

### Fatal Errors (Script Exits)

| Condition | Exit Code | Message |
|-----------|-----------|---------|
| Non-Linux OS | 1 | "StartTunnel requires a Debian-based Linux system" |
| Non-Debian distribution | 1 | "Unsupported Linux Distribution" |
| Debian version < 12 | 1 | "StartTunnel requires Debian 12+" |
| Not root, no sudo | 1 | "sudo is not available" |
| Cannot install curl | 1 | "Failed to install curl" |
| Download fails | 1 | "Failed to download package" |
| Installation verification fails | 1 | "StartTunnel installation could not be verified" |

### Non-Fatal Warnings (Script Continues)

| Condition | Action |
|-----------|--------|
| DNS resolution fails | Warn, continue (may fail at download) |
| WireGuard module won't load | Warn, continue (may use userspace) |
| Cannot stop service | Warn, continue |
| Cannot start service | Warn, display troubleshooting |
| Web interface config fails | Warn, show manual command |
| Firewall still active | Warn, note in verification |

---

## 📁 System Changes Made

### Files Created/Modified

| Path | Action | Purpose |
|------|--------|---------|
| `/etc/sysctl.conf` | Modified | Enable IP forwarding |
| `/etc/resolv.conf` | Created/Modified | Configure DNS servers |
| `/etc/systemd/resolved.conf` | Modified | Configure systemd-resolved DNS |
| `/etc/systemd/resolved.conf.backup` | Created | Backup before changes |
| `/etc/resolv.conf.backup` | Created | Backup before changes |

### Services Modified

| Service | Action | Reason |
|---------|--------|--------|
| `ufw` | Stopped, Disabled | StartTunnel manages firewall |
| `firewalld` | Stopped, Disabled | StartTunnel manages firewall |
| `netfilter-persistent` | Stopped, Disabled | StartTunnel manages firewall |
| `systemd-resolved` | Restarted | Apply DNS config |
| `start-tunneld` | Started, Enabled | Main VPN service |

### Packages Modified

**Installed:**
- start-tunnel (from .deb)
- ca-certificates
- gnupg
- wireguard
- wireguard-tools
- iptables
- iproute2
- openresolv
- dnsutils
- iputils-ping
- curl (if missing)

**Removed:**
- Desktop environments
- Web servers
- Mail servers
- Database servers
- FTP servers
- DNS servers (bind9, dnsmasq)
- Development tools
- Unnecessary services

---

## 🧪 Testing Scenarios

### Scenario 1: Fresh Debian 12 VPS
**Expected Flow:**
1. ✓ OS checks pass
2. ✓ Escalate to root via sudo
3. ✓ Fresh install detected
4. ✓ System preparation runs
5. ✓ Package downloads and installs
6. ✓ Service starts
7. ✓ Web config prompts (Y/n)
8. ✓ Success display

**Duration:** ~5-10 minutes

---

### Scenario 2: Reinstall on Existing Installation
**Expected Flow:**
1. ✓ OS checks pass
2. ✓ Existing version detected
3. ? User prompted to reinstall
4. If Yes:
   - ✓ Service stopped
   - ✓ System preparation runs
   - ✓ Package reinstalled
   - ✓ Service restarted
   - ? Web reconfig prompted (y/N)
   - ✓ Success display
5. If No:
   - ✓ Clean exit

**Duration:** ~5-10 minutes (if Yes)

---

### Scenario 3: Non-Debian System
**Expected Flow:**
1. ✗ OS check fails
2. ✗ Error message displayed
3. ✗ Script exits

**Duration:** < 1 second

---

## 🔐 Security Considerations

### Elevated Privileges
- Script requires root for:
  - Package installation
  - Service management
  - Network configuration
  - System file modification

### Network Security
- Disables system firewalls
- StartTunnel manages its own firewall rules
- Opens WireGuard ports as needed

### DNS Security
- Uses trusted public DNS (Google, Cloudflare, Quad9)
- Makes resolv.conf immutable to prevent tampering

### Package Verification
- Downloads from official GitHub releases
- Uses HTTPS for all downloads
- Package signatures verified by dpkg/apt

---

## 🐛 Troubleshooting Guide

### Common Issues

**Issue:** "DNS resolution may not be working properly"
- **Cause:** Network issues or DNS servers blocked
- **Impact:** May fail at package download
- **Solution:** Check network connectivity, try different DNS

**Issue:** "Service may not be running correctly"
- **Cause:** Port already in use, configuration error
- **Impact:** VPN won't work
- **Solution:** Check logs: `journalctl -u start-tunneld -f`

**Issue:** "Web interface configuration exited with code 1"
- **Cause:** Service not running when web init executed
- **Impact:** Web UI not accessible
- **Solution:** Run manually: `start-tunnel web init`

**Issue:** "Firewall is still active"
- **Cause:** Unknown firewall type or permission issue
- **Impact:** VPN traffic may be blocked
- **Solution:** Manually disable: `ufw disable` or `systemctl stop firewalld`

---

## 📞 Support Commands

After installation, users can:

```bash
# Check service status
systemctl status start-tunneld

# View live logs
journalctl -u start-tunneld -f

# Configure web interface
start-tunnel web init

# Reset web interface
start-tunnel web reset

# Check DNS resolution
nslookup github.com

# Check IP forwarding
sysctl net.ipv4.ip_forward
```

---

## 📝 Version Information

- **Script Version:** Based on StartTunnel 0.4.0-alpha.13
- **Compatible Systems:** Debian 12+, Ubuntu (Debian-based), Raspbian
- **Supported Architectures:** x86_64, aarch64, riscv64

---
