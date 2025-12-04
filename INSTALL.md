# StartTunnel VPS Installer - Logic Map & Documentation

This documentation provides a complete understanding of the installer script's logic, functionality, and system impact. It can be used as a reference for maintenance, troubleshooting, and understanding the installation process.

## 📋 Executive Summary

This script performs a **complete, turnkey installation** of StartTunnel on a Debian-based VPS, transforming a fresh server into a dedicated WireGuard VPN server with zero manual configuration required.

**What it does:**
- Validates Debian 12+ system
- Configures networking (DNS, firewall)
- Installs WireGuard and StartTunnel
- Automatically enables and starts the service
- Shows web interface setup instructions (fresh installs)
- Auto-displays web interface info on reinstall
- Handles both fresh installs and reinstalls seamlessly

**Installation Methods:**
```
# Method 1: One-line curl install (recommended)
curl -sSL http://start9labs.github.io/start-tunnel  | sh

# Method 2: Download and execute
curl -fsSL http://start9labs.github.io/start-tunnel  -o install.sh
chmod +x install.sh
./install.sh
```

---

## 🎨 User Interface Features

### Visual Box System
The installer uses a clean, color-coded ASCII box system for user communication:

- **🔴 Red boxes**: Error messages and system requirements
- **🔵 Blue boxes**: Information and configuration prompts  
- **🟡 Yellow boxes**: Warnings and system modifications
- **🟢 Green boxes**: Success messages and completion

All boxes are perfectly aligned with 63-character width for consistent terminal display.

### UTF-8 Special Characters
Supported symbols (one per line for proper alignment):
- ✓ Success/Complete
- ✗ Failed/Error
- ● Active status
- ○ Inactive status
- ★ Important/Premium
- ◆ ◇ Diamond markers
- ☆ Star outline

---

## 🗺️ High-Level Execution Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    SCRIPT EXECUTION START                   │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              STDIN FIX (curl | sh support)                  │
├─────────────────────────────────────────────────────────────┤
│ -  Detect if script is piped from curl                      │
│ -  Redirect stdin from /dev/tty for interactive prompts     │
│ -  Set cleanup trap to restore terminal state on exit       │
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
│          │                                  │               │
│          ▼                                  ▼               │
│   Show Blue Box:                      Set: FRESH_INSTALL    │
│   - Current version                                         │
│   - Service status                                          │
│   Options:                                                  │
│   [r] Reinstall                                             │
│   [c] Configure web UI                                      │
│   [n] Cancel                                                │
│          │                                                  │
│   ┌──────┼──────┐                                           │
│   │      │      │                                           │
│   ▼      ▼      ▼                                           │
│   r      c      n                                           │
│   │      │      │                                           │
│   │      │      └──> Exit (no changes)                      │
│   │      │                                                  │
│   │      └──> Configure/reconfigure web UI → Exit           │
│   │                                                         │
│   └──> Continue with reinstall                              │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                 SYSTEM PREPARATION                          │
│             (Fresh Install or Reinstall)                    │
├─────────────────────────────────────────────────────────────┤
│ 1. Install required packages (curl, wireguard-tools)        │
│ 2. Check and fix DNS resolution                             │
│    ├─> Yellow box if issue detected                         │
│    └─> Green box when fixed                                 │
│ 3. Detect and disable system firewalls                      │
│    └─> Yellow box for UFW/iptables removal                  │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              STARTTUNNEL INSTALLATION                       │
├─────────────────────────────────────────────────────────────┤
│ 1. Detect system architecture (x86_64/aarch64/riscv64)      │
│ 2. Download .deb package from GitHub releases               │
│    └─> Grey progress bar                                    │
│ 3. Install package with apt/dpkg                            │
│ 4. Verify installation (check binary exists)                │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│               SERVICE CONFIGURATION                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ ┌──────────────────┐              ┌────────────────────┐    │
│ │ Fresh Install    │              │ Reinstall Mode     │    │
│ └────────┬─────────┘              └─────────┬──────────┘    │
│          │                                  │               │
│          ▼                                  ▼               │
│ enable_and_start_service()     restart_service()            │
│ -  systemctl daemon-reload     -  Preserve previous state   │
│ -  systemctl enable            -  systemctl restart if was  │
│ -  systemctl start                running                   │
│ -  Verify service running      -  systemctl enable if was   │
│                                   enabled                   │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                    COMPLETION                                │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ ┌──────────────────┐              ┌────────────────────┐    │
│ │ Fresh Install    │              │ Reinstall Mode     │    │
│ └────────┬─────────┘              └─────────┬──────────┘    │
│          │                                  │               │
│          ▼                                  ▼               │
│   Green Box:                         Auto-run:              │
│   "Installation Complete"            start-tunnel web init  │
│   - Service status (if not running)  (if service running)   │
│   - Instruction: "To initialize      - Shows web UI info     │
│     the web interface, run:"         (URL, SSL cert, etc.)  │
│   - Command: start-tunnel web init                          │
│                                                             │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                  SUCCESS DISPLAY                            │
├─────────────────────────────────────────────────────────────┤
│ Green Box (centered):                                       │
│          ✓ Installation Complete                            │
│                                                             │
│ -  TTY redirection cleanup (exec 0<&-)                      │
│ -  Script exits cleanly                                     │
│ -  User returned to command prompt                          │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔧 Function Reference Guide

### **Core Box Functions**

| Function | Purpose | Parameters |
|----------|---------|------------|
| `fix_stdin()` | Enables keyboard input when piped from curl | None |
| `box_start(color)` | Renders top border and sets box color | Color (e.g., `$DIM$BLUE`) |
| `box_end()` | Renders bottom border | None |
| `box_empty()` | Renders empty line with borders | None |
| `box_line(text, align, style)` | Renders text line with auto-padding | text, alignment (left/center), text style |

**Box Usage Examples:**
```
# Simple left-aligned text
box_start "$DIM$BLUE"
box_line "This is a message"
box_end

# Centered with styling
box_start "$DIM$GREEN"
box_line "✓ Installation Complete" "center" "$GREEN$BOLD"
box_end
```

---

### **Phase 1: Pre-Flight Checks**

#### `fix_stdin()`
**Purpose:** Enables interactive prompts when script is piped from curl
**Flow:**
1. Check if stdin is a terminal (`[ ! -t 0 ]`)
2. If piped:
   - Save original stdin to file descriptor 3
   - Redirect stdin from /dev/tty
   - Set trap to restore stdin on exit
3. At script completion:
   - Close TTY redirection (`exec 0<&-`)
   - Ensures clean return to command prompt

**Critical for:** `curl | sh` installation method

---

#### `check_debian()`
**Purpose:** Validates the operating system with visual feedback
**Flow:**
1. Check if OS is Linux (uname -s)
2. Verify /etc/os-release exists
3. Read distribution ID from os-release
4. Confirm it's Debian-based (debian/ubuntu/raspbian)
5. For Debian: verify version is 12+
6. Display red error box if any check fails

**Exit Conditions:**
- Non-Linux OS → Red box: "StartTunnel requires Debian-based Linux"
- Missing /etc/os-release → Red box: "System does not appear to be Debian"
- Non-Debian distribution → Red box: Shows detected OS vs required
- Debian version < 12 → Red box: Shows version mismatch

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
- Non-root user without sudo → Error: "sudo is not available"

---

### **Phase 2: Installation Mode Detection**

#### `check_existing_installation()`
**Purpose:** Detects if StartTunnel is already installed with interactive menu
**Flow:**
1. Query dpkg for start-tunnel package
2. If found:
   - Get installed version
   - Check service status (running/stopped)
   - Display blue box with:
     - Current version
     - Service status
     - Options: [r] Reinstall, [c] Configure, [n] Cancel
   - Wait for user input
   - If 'r': Set REINSTALL_MODE=true, stop service
   - If 'c': Jump to web UI configuration, then exit
   - If 'n': Exit gracefully
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

#### `check_install_packages()`
**Purpose:** Ensures required packages are installed
**Flow:**
1. Check for curl and wireguard-tools
2. If missing:
   - Run apt-get update
   - Install missing packages
   - Report success

**Packages Required:**
- curl
- wireguard-tools

---


---

#### `check_dns()`
**Purpose:** Ensures DNS resolution works, fixes if broken
**Flow:**
1. Test DNS: `ping -c 1 -W 2 github.com`
2. If fails:
   - Display yellow box: "Cannot resolve github.com..."
   - Test connectivity: ping 1.1.1.1, 8.8.8.8
   - If network OK but DNS broken:
     - Backup /etc/resolv.conf → /etc/resolv.conf.backup
     - Create new resolv.conf with public DNS
     - Test again
     - Display green box: "DNS configured with public resolvers"

**DNS Servers Used:**
- Google: 8.8.8.8, 8.8.4.4
- Cloudflare: 1.1.1.1, 1.0.0.1
- Quad9: 9.9.9.9

**Exit Conditions:**
- No network connectivity → Error exit

---

#### `check_disable_firewall()`
**Purpose:** Disables system firewalls (StartTunnel manages its own)
**Flow:**
1. Check for UFW:
   - If active:
     - Display yellow box: "UFW detected, disabling..."
     - Disable, stop, disable service
2. Check for iptables rules:
   - If custom rules exist (> 8 lines):
     - Display yellow box: "Custom iptables detected..."
     - Flush all rules
     - Set default policies to ACCEPT
3. Report "System firewall disabled" if any action taken

**Firewalls Removed:**
- UFW (Uncomplicated Firewall)
- Custom iptables rules

---

### **Phase 4: StartTunnel Installation**

#### `detect_architecture()`
**Purpose:** Detects CPU architecture for correct package
**Flow:**
1. Run `uname -m`
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
**Purpose:** Downloads StartTunnel .deb package with progress bar
**Flow:**
1. Build package filename
2. Build download URL from GitHub releases
3. Display "Downloading StartTunnel..."
4. Download with curl (grey progress bar via `$DIM` color)
5. Save to temporary directory

**Progress Bar:**
- Color: Grey/dim (not yellow)
- Width: 65 columns (`COLUMNS=65`)
- Style: `curl --progress-bar`

**Example URL:**
```
https://github.com/Start9Labs/start-os/releases/download/v0.4.0-alpha.12/start-tunnel-0.4.0-alpha.12-unknown.dev_x86_64.deb
```

**Exit Conditions:**
- Download fails (404, network error) → Error exit

---

#### `install_package()`
**Purpose:** Installs the downloaded .deb package
**Flow:**
1. Display "Installing..." or "Reinstalling..."
2. Run apt-get update silently
3. If reinstall mode: use `apt-get --reinstall install`
4. If fresh install: use `apt install`
5. Fallback to `dpkg -i` if apt fails
6. Run `apt-get install -f` to resolve dependencies
7. Delete temporary files

**Exit Conditions:**
- Installation fails after all attempts → Error exit

---

#### `verify_installation()`
**Purpose:** Confirms StartTunnel is installed correctly
**Flow:**
1. Check if start-tunnel command exists
2. Try to get version (`start-tunnel --version`)
3. Fallback to dpkg query
4. Set INSTALLED_VERSION variable

**Exit Conditions:**
- Binary not found after installation → Error exit

---

### **Phase 5: Service Configuration**

#### `enable_and_start_service()`
**Purpose:** Automatically starts and enables service (fresh installs)
**Flow:**
1. Display "Enabling and starting service..."
2. Reload systemd daemon (`daemon-reload`)
3. Enable service for boot: `systemctl enable start-tunneld`
   - Report "Service enabled for auto-start on boot"
4. Start service now: `systemctl start start-tunneld`
   - Wait 2 seconds for initialization
   - Verify service is active
   - Report "Service started successfully"

**Service:** `start-tunneld.service`

**Exit Conditions:**
- Service fails to start → Warning only, continues

---

#### `restart_service()`
**Purpose:** Restarts service for reinstalls (preserves previous state)
**Flow:**
1. If service was running before:
   - Reload systemd daemon
   - Restart service
   - Wait 2 seconds
   - Verify still active
   - Show warning if issues
2. If service was enabled before:
   - Ensure it's still enabled

**Preserves:** Previous running/enabled state

---

### **Phase 6: Completion**

**Note:** The installer no longer prompts for web UI configuration. Instead:

**For Fresh Install:**
- Shows success message with instruction to run `start-tunnel web init`
- User manually runs the command to initialize web interface

**For Reinstall:**
- Automatically runs `start-tunnel web init` if service is running
- Displays web interface information (URL, SSL certificate, etc.)
- No success message box shown

**Commands:**
- `start-tunnel web init` - Initializes web interface (prompts for password on first run, shows info if already configured)
- `start-tunnel web reset` - Resets web interface configuration

---

#### `reconfigure_web_ui()`
**Purpose:** Web UI configuration from existing installation menu
**Flow:**
1. Display blue box with options:
   - [i] Display current web information
   - [r] Reset and reconfigure web UI
   - [n] Cancel
2. If 'i': Run `start-tunnel web init` (display mode)
3. If 'r': Reset → Init
4. If 'n': Return to prompt

**Triggered by:** Choosing [c] from existing installation menu

---

#### Success Display
**Purpose:** Show completion message and clean up
**Flow:**

**For Fresh Install:**
1. Display green box (centered):
   ```
   ┌───────────────────────────────────────────────────────────────┐
   │                                                               │
   │                  Installation Complete                        │
   │                                                               │
   │   To initialize the web interface, run:                       │
   │   start-tunnel web init                                       │
   │                                                               │
   └───────────────────────────────────────────────────────────────┘
   ```
2. Shows service status warning if service not running
3. Close TTY redirection: `exec 0<&- 2>/dev/null || true`
4. Script exits cleanly
5. User returned to command prompt automatically

**For Reinstall:**
1. Automatically runs `start-tunnel web init` (if service running)
2. Displays web interface information directly
3. No success message box shown
4. Close TTY redirection: `exec 0<&- 2>/dev/null || true`
5. Script exits cleanly

**Manual Step Required (Fresh Install Only):** User must run `start-tunnel web init` to initialize web interface

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
| `BOX_COLOR` | string | Current box border color | `box_start()` |

---

## 🔀 Decision Trees

### Installation Mode Decision

```
Is start-tunnel installed?
├─ No → FRESH_INSTALL=true → Continue
└─ Yes → Display blue box with:
         - Version: X.X.X
         - Service: Running/Stopped
         - Options: [r/c/n]
         
         User Input?
         ├─ r → REINSTALL_MODE=true → Stop service → Continue
         ├─ c → reconfigure_web_ui() → Exit
         └─ n → Exit (no changes made)
```

### Service Management Decision

```
Installation Mode?
├─ FRESH_INSTALL
│  └─> enable_and_start_service()
│      ├─ systemctl enable start-tunneld
│      ├─ systemctl start start-tunneld
│      └─ Verify running
│
└─ REINSTALL_MODE
   └─> restart_service()
       ├─ systemctl daemon-reload
       ├─ systemctl restart (if was running)
       └─ systemctl enable (if was enabled)
```

### Completion Decision

```
Mode: FRESH_INSTALL
└─ Green box: "Installation Complete"
   └─ Shows instruction: "To initialize the web interface, run:"
   └─ Shows command: "start-tunnel web init"
   └─ User runs command manually

Mode: REINSTALL_MODE
└─ Automatically runs: start-tunnel web init (if service running)
   └─ Displays web interface info (URL, SSL cert, etc.)
   └─ No success message box shown

Mode: EXISTING (from [c] option)
└─ Blue box: "Options: [i/r/n]"
   ├─ i → start-tunnel web init (display mode)
   ├─ r → start-tunnel web reset → init
   └─ n → Cancel
```

---

## ⚠️ Error Handling

### Fatal Errors (Script Exits with Red Box)

| Condition | Exit Code | Display |
|-----------|-----------|---------|
| Non-Linux OS | 1 | Red box: "StartTunnel requires Debian-based Linux" |
| Non-Debian distribution | 1 | Red box: Shows detected vs required OS |
| Debian version < 12 | 1 | Red box: Shows version mismatch |
| Not root, no sudo | 1 | Error: "sudo is not available" |
| Cannot install packages | 1 | Error: "Failed to install required packages" |
| Download fails | 1 | Error: "Failed to download package" |
| Installation verification fails | 1 | Error: "Installation verification failed" |

### Non-Fatal Warnings (Script Continues)

| Condition | Display | Action |
|-----------|---------|--------|
| DNS resolution fails | Yellow box | Fix with public DNS → Green box on success |
| Firewall detected | Yellow box | Disable UFW/iptables, continue |
| Service won't start | Yellow warning | Show troubleshooting command, continue |
| Web init fails | Yellow warning | Show manual command, continue |

---

## 📁 System Changes Made

### Files Created/Modified

| Path | Action | Purpose |
|------|--------|---------|
| `/etc/resolv.conf` | Created/Modified | Configure DNS servers |
| `/etc/resolv.conf.backup` | Created | Backup before DNS changes |

### Services Modified

| Service | Action | Reason |
|---------|--------|--------|
| `ufw` | Stopped, Disabled | StartTunnel manages firewall |
| `iptables` | Rules flushed | StartTunnel manages firewall |
| `start-tunneld` | Started, Enabled | Main VPN service (automatic) |

### Packages Modified

**Installed:**
- start-tunnel (from .deb)
- curl (if missing)
- wireguard-tools

**Network Configuration:**
- DNS: ✓ Configured (if needed)
- Firewall: ✓ Disabled (StartTunnel manages own rules)

---

## 🧪 Testing Scenarios

### Scenario 1: Fresh Debian 12 VPS
**Command:**
```
curl -sSL http://start9labs.github.io/start-tunnel  | sh
```

**Expected Flow:**
1. ✓ OS checks pass (Linux, Debian 12+)
2. ✓ Escalate to root via sudo (if needed)
3. ✓ Fresh install detected
4. ✓ System preparation:
   - Yellow box: DNS fixed (if needed)
   - Yellow box: Firewall disabled (if detected)
5. ✓ Download with grey progress bar
6. ✓ Package installs
7. ✓ Service automatically starts and enables
8. ✓ Green box: "Installation Complete"
   - Shows instruction to run `start-tunnel web init`
9. ✓ Returns to command prompt automatically
10. User runs `start-tunnel web init` manually

**Duration:** ~2-5 minutes  
**No manual steps required**

---

### Scenario 2: Reinstall on Existing Installation
**Command:**
```
curl -sSL http://start9labs.github.io/start-tunnel  | sh
```

**Expected Flow:**
1. ✓ OS checks pass
2. ✓ Blue box: Existing v0.4.0-alpha.12 detected
   - Shows service status
   - Options: [r/c/n]
3. User chooses 'r':
   - ✓ Service stopped (if running)
   - ✓ System preparation
   - ✓ Package reinstalled
   - ✓ Service restarted (preserves previous state)
   - ✓ Automatically runs `start-tunnel web init` (if service running)
   - ✓ Displays web interface info (URL, SSL cert, etc.)
   - ✓ Returns to prompt
4. User chooses 'c':
   - ✓ Blue box: Web UI options [i/r/n]
   - ✓ Configure → Exit
5. User chooses 'n':
   - ✓ "Installation cancelled" → Exit

**Duration:** ~2-5 minutes (if 'r')

---

### Scenario 3: Non-Debian System
**Command:**
```
curl -sSL http://start9labs.github.io/start-tunnel  | sh
```

**Expected Flow:**
1. ✗ OS check fails immediately
2. ✗ Red box: "Unsupported Linux Distribution"
   - Shows detected OS
   - Shows required OS
3. ✗ Script exits cleanly

**Duration:** < 1 second

---

### Scenario 4: Piped from curl (stdin fix test)
**Command:**
```
curl -sSL http://start9labs.github.io/start-tunnel  | sh
```

**Expected Behavior:**
- ✓ Script waits for keyboard input at all prompts
- ✓ Blue boxes display correctly
- ✓ User can type responses (y/n/r/c)
- ✓ After completion, returns to prompt automatically
- ✓ No need for Ctrl+C

**Critical Fix:** `fix_stdin()` with TTY cleanup

---

## 🔐 Security Considerations

### Elevated Privileges
- Script requires root for:
  - Package installation
  - Service management
  - Network configuration
  - System file modification
- Auto-escalates with sudo if not root

### Network Security
- Disables system firewalls (UFW, iptables)
- StartTunnel manages its own firewall rules
- Opens WireGuard ports as needed
- All downloads over HTTPS

### DNS Security
- Uses trusted public DNS (Google, Cloudflare, Quad9)
- Backs up original configuration
- Only modifies DNS if resolution fails

### Package Verification
- Downloads from official GitHub releases (start9labs/start-os)
- Uses HTTPS for all downloads
- Package signatures verified by dpkg/apt

---

## 🐛 Troubleshooting Guide

### Common Issues

**Issue:** Script hangs after prompts (when piped from curl)
- **Cause:** TTY redirection not working
- **Impact:** Cannot type responses
- **Solution:** ✓ Fixed with `fix_stdin()` function

**Issue:** Script doesn't return to prompt after completion
- **Cause:** TTY file descriptor not closed
- **Impact:** Need to press Ctrl+C
- **Solution:** ✓ Fixed with `exec 0<&-` at end of main()

**Issue:** "DNS resolution may not be working properly"
- **Cause:** Network issues or DNS servers blocked
- **Display:** Yellow warning box
- **Auto-fix:** Script configures public DNS and retries
- **Success:** Green confirmation box

**Issue:** "Service may not be running correctly"
- **Cause:** Port already in use, configuration error
- **Display:** Yellow warning with troubleshooting command
- **Impact:** VPN won't work
- **Solution:** Check logs: `journalctl -u start-tunneld -f`

**Issue:** Boxes not aligned correctly
- **Cause:** UTF-8 special character byte count issue
- **Solution:** ✓ Fixed with automatic detection (one special char per line)
- **Supported:** ✓✗●○◆◇★☆ (one per line)

**Issue:** Progress bar wrong color
- **Expected:** Grey/dim
- **Fix:** Uses `$DIM` color, not `$YELLOW`

---

## 📞 Post-Installation Commands

After successful installation, the service is already running. Users can:

```
# Check service status
systemctl status start-tunneld

# View live logs
journalctl -u start-tunneld -f

# Configure web interface (if skipped)
start-tunnel web init

# Reconfigure web interface
start-tunnel web reset
start-tunnel web init

# Check DNS resolution
ping github.com


# View firewall rules (managed by StartTunnel)
iptables -L -n
```

---

## 📝 Version Information

- **Script Version:** Based on StartTunnel 0.4.0-alpha.12
- **Compatible Systems:** Debian 12+, Ubuntu (Debian-based), Raspbian
- **Supported Architectures:** x86_64, aarch64, riscv64
- **Installation Methods:** 
  - One-line curl pipe: `curl -sSL <url> | sh`
  - Download and execute: `curl -fsSL <url> -o install.sh && chmod +x install.sh && ./install.sh`

---

## 🎯 Key Improvements in Latest Version

1. **✓ curl | sh Support**
   - `fix_stdin()` enables keyboard input when piped
   - Proper cleanup prevents terminal hanging
   - Automatic return to command prompt

2. **✓ Automatic Service Management**
   - Fresh installs: Service starts and enables automatically
   - Reinstalls: Preserves previous running/enabled state
   - No manual systemctl commands required

3. **✓ Universal Box System**
   - Color-coded visual feedback (red/blue/yellow/green)
   - Perfect 63-character alignment
   - UTF-8 symbol support (✓✗●○◆◇★☆)
   - Centered text option

4. **✓ Smart Installation Detection**
   - Interactive menu for existing installations
   - Options: Reinstall, Configure, Cancel
   - Preserves user choice and system state

5. **✓ Enhanced Error Handling**
   - Visual error boxes instead of plain text
   - Auto-fix for common issues (DNS, firewall)
   - Non-fatal warnings allow continuation

6. **✓ Progress Indicators**
   - Grey download progress bar
   - Status messages during each phase
   - Clear success/failure feedback

---

## 📄 License

This installer is part of the StartTunnel project by Start9 Labs.

---
