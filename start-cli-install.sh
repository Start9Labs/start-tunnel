#!/bin/sh
# start-tunnel complete installer for Debian VPS systems
# Downloads, installs, and configures start-tunnel from official GitHub releases
# Optimizes VPS specifically for WireGuard/StartTunnel operation

set -e
set -u

# Color scheme
if command -v tput >/dev/null 2>&1; then
    BOLD=$(tput bold 2>/dev/null || echo '')
    BLUE=$(tput setaf 4 2>/dev/null || echo '')
    GREEN=$(tput setaf 2 2>/dev/null || echo '')
    YELLOW=$(tput setaf 3 2>/dev/null || echo '')
    RED=$(tput setaf 1 2>/dev/null || echo '')
    WHITE=$(tput setaf 7 2>/dev/null || echo '')
    RESET=$(tput sgr0 2>/dev/null || echo '')
    DIM=$(tput dim 2>/dev/null || echo '')
else
    BOLD='' BLUE='' GREEN='' YELLOW='' RED='' WHITE='' RESET='' DIM=''
fi

# ASCII Header
printf "\n"
printf "%s┌───────────────────────────────────────────────────────────────┐%s\n" "$DIM$RED" "$RESET"
printf "%s│%s                                                               %s│%s\n" "$DIM$RED" "$RESET" "$DIM$RED" "$RESET"
printf "%s│%s                        %sstart-tunnel%s                           %s│%s\n" "$DIM$RED" "$RESET" "$WHITE$BOLD" "$RESET" "$DIM$RED" "$RESET"
printf "%s│%s                                                               %s│%s\n" "$DIM$RED" "$RESET" "$DIM$RED" "$RESET"
printf "%s│%s               %sSelf-Hosted WireGuard VPN Server%s                %s│%s\n" "$DIM$RED" "$RESET" "$DIM" "$RESET" "$DIM$RED" "$RESET"
printf "%s│%s             %sOptimized for reverse tunneling access%s            %s│%s\n" "$DIM$RED" "$RESET" "$DIM" "$RESET" "$DIM$RED" "$RESET"
printf "%s│%s                                                               %s│%s\n" "$DIM$RED" "$RESET" "$DIM$RED" "$RESET"
printf "%s│%s                %sDedicated VPS Setup Script%s                     %s│%s\n" "$DIM$RED" "$RESET" "$DIM$BLUE" "$RESET" "$DIM$RED" "$RESET"
printf "%s│%s                                                               %s│%s\n" "$DIM$RED" "$RESET" "$DIM$RED" "$RESET"
printf "%s└───────────────────────────────────────────────────────────────┘%s\n" "$DIM$RED" "$RESET"
printf "\n"

err() { printf "%sError:%s %s\n" "$RED$BOLD" "$RESET" "$1" >&2; exit 1; }
warn() { printf "%sWarning:%s %s\n" "$YELLOW$BOLD" "$RESET" "$1"; }
info() { printf "%s•%s %s\n" "$YELLOW" "$RESET" "$1"; }
success() { printf "%s✓%s %s\n" "$GREEN" "$RESET" "$1"; }

# Configuration - FIXED VERSION FORMAT
VERSION="0.4.0-alpha.12"
BASE_URL="https://github.com/Start9Labs/start-os/releases/download/v${VERSION}"
PACKAGE_PREFIX="start-tunnel-${VERSION}-unknown.dev"
PACKAGE_NAME_BASE="start-tunnel"
SERVICE_NAME="start-tunneld.service"
MIN_DEBIAN_VERSION=12

# Global variables
REINSTALL_MODE=false
INSTALLED_VERSION=""
SERVICE_WAS_RUNNING=false
SERVICE_WAS_ENABLED=false
FRESH_INSTALL=false

# Verify this is a Debian system (run first, before root check)
check_debian() {
    info "Checking operating system..."
    
    # Check if this is a Linux system
    OS_TYPE=$(uname -s)
    if [ "$OS_TYPE" != "Linux" ]; then
        printf "\n"
        printf "%s┌─ Unsupported Operating System ────────────────────────────────┐%s\n" "$DIM$RED" "$RESET"
        printf "%s│%s                                                               %s│%s\n" "$DIM$RED" "$RESET" "$DIM$RED" "$RESET"
        printf "%s│%s  StartTunnel requires a Debian-based Linux system.            %s│%s\n" "$DIM$RED" "$RESET" "$DIM$RED" "$RESET"
        printf "%s│%s                                                               %s│%s\n" "$DIM$RED" "$RESET" "$DIM$RED" "$RESET"
        printf "%s│%s  %sDetected OS:%s %-48s%s│%s\n" "$DIM$RED" "$RESET" "$BOLD" "$RESET" "$OS_TYPE" "$DIM$RED" "$RESET"
        printf "%s│%s  %sSupported:%s  Debian 12+ (Bookworm or newer)                   %s│%s\n" "$DIM$RED" "$RESET" "$BOLD" "$RESET" "$DIM$RED" "$RESET"
        printf "%s│%s                                                               %s│%s\n" "$DIM$RED" "$RESET" "$DIM$RED" "$RESET"
        printf "%s└───────────────────────────────────────────────────────────────┘%s\n" "$DIM$RED" "$RESET"
        printf "\n"
        exit 1
    fi
    
    # Check for /etc/os-release
    if [ ! -f /etc/os-release ]; then
        printf "\n"
        printf "%s┌─ Unsupported Linux Distribution ──────────────────────────────┐%s\n" "$DIM$RED" "$RESET"
        printf "%s│%s                                                               %s│%s\n" "$DIM$RED" "$RESET" "$DIM$RED" "$RESET"
        printf "%s│%s  StartTunnel requires Debian 12+ (Bookworm or newer).         %s│%s\n" "$DIM$RED" "$RESET" "$DIM$RED" "$RESET"
        printf "%s│%s                                                               %s│%s\n" "$DIM$RED" "$RESET" "$DIM$RED" "$RESET"
        printf "%s│%s  Your system does not appear to be a standard Debian-based    %s│%s\n" "$DIM$RED" "$RESET" "$DIM$RED" "$RESET"
        printf "%s│%s  distribution (/etc/os-release not found).                    %s│%s\n" "$DIM$RED" "$RESET" "$DIM$RED" "$RESET"
        printf "%s│%s                                                               %s│%s\n" "$DIM$RED" "$RESET" "$DIM$RED" "$RESET"
        printf "%s└───────────────────────────────────────────────────────────────┘%s\n" "$DIM$RED" "$RESET"
        printf "\n"
        exit 1
    fi
    
    # Source os-release to get distribution info
    . /etc/os-release
    
    # Check if it's a Debian-based system
    if ! echo "$ID" | grep -qE '^(debian|ubuntu|raspbian)$' && ! echo "${ID_LIKE:-}" | grep -q debian; then
        printf "\n"
        printf "%s┌─ Unsupported Linux Distribution ──────────────────────────────┐%s\n" "$DIM$RED" "$RESET"
        printf "%s│%s                                                               %s│%s\n" "$DIM$RED" "$RESET" "$DIM$RED" "$RESET"
        printf "%s│%s  StartTunnel requires Debian 12+ (Bookworm or newer).         %s│%s\n" "$DIM$RED" "$RESET" "$DIM$RED" "$RESET"
        printf "%s│%s                                                               %s│%s\n" "$DIM$RED" "$RESET" "$DIM$RED" "$RESET"
        printf "%s│%s  %sDetected:%s %-50s%s│%s\n" "$DIM$RED" "$RESET" "$BOLD" "$RESET" "$NAME" "$DIM$RED" "$RESET"
        printf "%s│%s  %sSupported:%s Debian, Ubuntu, Raspbian (Debian-based only)   %s│%s\n" "$DIM$RED" "$RESET" "$BOLD" "$RESET" "$DIM$RED" "$RESET"
        printf "%s│%s                                                               %s│%s\n" "$DIM$RED" "$RESET" "$DIM$RED" "$RESET"
        printf "%s└───────────────────────────────────────────────────────────────┘%s\n" "$DIM$RED" "$RESET"
        printf "\n"
        exit 1
    fi
    
    # Check Debian version (for pure Debian systems)
    if [ "$ID" = "debian" ]; then
        if [ -n "${VERSION_ID:-}" ]; then
            DEBIAN_MAJOR=$(echo "$VERSION_ID" | cut -d. -f1)
        elif [ -f /etc/debian_version ]; then
            DEBIAN_MAJOR=$(cat /etc/debian_version | cut -d. -f1)
        else
            DEBIAN_MAJOR="unknown"
        fi
        
        if echo "$DEBIAN_MAJOR" | grep -qE '^[0-9]+$'; then
            if [ "$DEBIAN_MAJOR" -lt "$MIN_DEBIAN_VERSION" ]; then
                printf "\n"
                printf "%s┌─ Unsupported Debian Version ──────────────────────────────────┐%s\n" "$DIM$RED" "$RESET"
                printf "%s│%s                                                               %s│%s\n" "$DIM$RED" "$RESET" "$DIM$RED" "$RESET"
                printf "%s│%s  StartTunnel requires Debian 12 (Bookworm) or newer.          %s│%s\n" "$DIM$RED" "$RESET" "$DIM$RED" "$RESET"
                printf "%s│%s                                                               %s│%s\n" "$DIM$RED" "$RESET" "$DIM$RED" "$RESET"
                printf "%s│%s  %sDetected:%s Debian %s%-39s%s│%s\n" "$DIM$RED" "$RESET" "$BOLD" "$RESET" "$DEBIAN_MAJOR" "" "$DIM$RED" "$RESET"
                printf "%s│%s  %sRequired:%s Debian 12 or higher                             %s│%s\n" "$DIM$RED" "$RESET" "$BOLD" "$RESET" "$DIM$RED" "$RESET"
                printf "%s│%s                                                               %s│%s\n" "$DIM$RED" "$RESET" "$DIM$RED" "$RESET"
                printf "%s└───────────────────────────────────────────────────────────────┘%s\n" "$DIM$RED" "$RESET"
                printf "\n"
                exit 1
            fi
        fi
    fi
    
    success "Operating system verified: $NAME"
}

# Check if running as root, escalate if needed
ensure_root() {
    if [ "$(id -u)" -ne 0 ]; then
        info "This script requires root privileges. Attempting to use sudo..."
        
        if ! command -v sudo >/dev/null 2>&1; then
            err "sudo is not available and script is not running as root"
        fi
        
        # Re-run script with sudo
        exec sudo sh "$0" "$@"
    fi
}

# Configure DNS resolution
configure_dns() {
    info "Configuring DNS resolution..."
    
    # Check if systemd-resolved is available and running
    if command -v systemctl >/dev/null 2>&1 && systemctl is-active --quiet systemd-resolved 2>/dev/null; then
        success "systemd-resolved is active and handling DNS"
        
        # Ensure resolved.conf has fallback DNS servers
        if [ -f /etc/systemd/resolved.conf ]; then
            # Backup original
            if [ ! -f /etc/systemd/resolved.conf.backup ]; then
                cp /etc/systemd/resolved.conf /etc/systemd/resolved.conf.backup
            fi
            
            # Check if DNS servers are configured
            if ! grep -q "^DNS=" /etc/systemd/resolved.conf 2>/dev/null; then
                info "Adding fallback DNS servers to systemd-resolved..."
                cat >> /etc/systemd/resolved.conf << EOF

# Added by StartTunnel installer
DNS=8.8.8.8 1.1.1.1 8.8.4.4 1.0.0.1
FallbackDNS=9.9.9.9 149.112.112.112
EOF
                systemctl restart systemd-resolved 2>/dev/null || true
                success "Fallback DNS servers configured"
            fi
        fi
        
        # Ensure /etc/resolv.conf is properly symlinked
        if [ -L /etc/resolv.conf ]; then
            RESOLV_TARGET=$(readlink -f /etc/resolv.conf)
            if echo "$RESOLV_TARGET" | grep -q "systemd/resolve"; then
                success "DNS configuration is correct"
            else
                info "Fixing /etc/resolv.conf symlink..."
                rm -f /etc/resolv.conf
                ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
                success "DNS configuration fixed"
            fi
        fi
    else
        # systemd-resolved not available, configure traditional DNS
        warn "systemd-resolved not active, configuring traditional DNS"
        
        # Backup original resolv.conf if it exists and hasn't been backed up
        if [ -f /etc/resolv.conf ] && [ ! -f /etc/resolv.conf.backup ]; then
            cp /etc/resolv.conf /etc/resolv.conf.backup
        fi
        
        # Create new resolv.conf with reliable DNS servers
        info "Configuring /etc/resolv.conf with public DNS servers..."
        cat > /etc/resolv.conf << EOF
# Generated by StartTunnel installer
# Google DNS
nameserver 8.8.8.8
nameserver 8.8.4.4
# Cloudflare DNS
nameserver 1.1.1.1
nameserver 1.0.0.1
# Quad9 DNS
nameserver 9.9.9.9

options timeout:2 attempts:3 rotate
EOF
        
        # Make it immutable to prevent DHCP or other services from overwriting
#        chattr +i /etc/resolv.conf 2>/dev/null || true
        success "DNS configuration updated"
    fi
}

# Verify DNS resolution is working
verify_dns() {
    info "Verifying DNS resolution..."
    
    # Test DNS resolution with multiple methods
    DNS_WORKING=false
    
    # Try with getent if available
    if command -v getent >/dev/null 2>&1; then
        if getent hosts github.com >/dev/null 2>&1; then
            DNS_WORKING=true
        fi
    fi
    
    # Try with host if available
    if [ "$DNS_WORKING" = false ] && command -v host >/dev/null 2>&1; then
        if host github.com >/dev/null 2>&1; then
            DNS_WORKING=true
        fi
    fi
    
    # Try with nslookup if available
    if [ "$DNS_WORKING" = false ] && command -v nslookup >/dev/null 2>&1; then
        if nslookup github.com >/dev/null 2>&1; then
            DNS_WORKING=true
        fi
    fi
    
    # Try with ping if nothing else works
    if [ "$DNS_WORKING" = false ] && command -v ping >/dev/null 2>&1; then
        if ping -c 1 -W 2 github.com >/dev/null 2>&1; then
            DNS_WORKING=true
        fi
    fi
    
    if [ "$DNS_WORKING" = true ]; then
        success "DNS resolution is working correctly"
        return 0
    else
        warn "DNS resolution may not be working properly"
        warn "Will attempt to continue, but downloads may fail"
        return 1
    fi
}

# Ensure curl or wget is available
ensure_download_tool() {
    info "Checking for download tools..."
    
    if command -v curl >/dev/null 2>&1; then
        success "curl is available"
        return 0
    fi
    
    if command -v wget >/dev/null 2>&1; then
        success "wget is available"
        return 0
    fi
    
    # Neither curl nor wget available, install curl
    warn "Neither curl nor wget found, installing curl..."
    
    # Update package list first
    if apt-get update -qq 2>&1 | grep -v "^$" > /dev/null; then
        :
    fi
    
    # Install curl
    if DEBIAN_FRONTEND=noninteractive apt-get install -y -qq curl 2>&1 | grep -v "^$" > /dev/null; then
        success "curl installed successfully"
    else
        err "Failed to install curl"
    fi
}

# Check service status
check_service_status() {
    if systemctl is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
        SERVICE_WAS_RUNNING=true
        info "Service $BOLD$SERVICE_NAME$RESET is currently running"
    fi
    
    if systemctl is-enabled --quiet "$SERVICE_NAME" 2>/dev/null; then
        SERVICE_WAS_ENABLED=true
    fi
}

# Stop service gracefully
stop_service() {
    if [ "$SERVICE_WAS_RUNNING" = true ]; then
        info "Stopping $SERVICE_NAME gracefully..."
        
        if systemctl stop "$SERVICE_NAME" 2>/dev/null; then
            success "Service stopped successfully"
        else
            warn "Could not stop service gracefully"
        fi
    fi
}

# Check if start-tunnel is already installed
check_existing_installation() {
    info "Checking for existing installation..."
    
    if command -v dpkg >/dev/null 2>&1 && dpkg -l 2>/dev/null | grep -q "^ii.*$PACKAGE_NAME_BASE" 2>/dev/null; then
        INSTALLED_VERSION=$(dpkg -s "$PACKAGE_NAME_BASE" 2>/dev/null | grep '^Version:' | awk '{print $2}')
        warn "StartTunnel is already installed (version: $BOLD$INSTALLED_VERSION$RESET)"
        
        check_service_status
        
        printf "\n"
        printf "%s┌─ Reinstall Confirmation ──────────────────────────────────────┐%s\n" "$DIM$BLUE" "$RESET"
        printf "%s│%s                                                               %s│%s\n" "$DIM$BLUE" "$RESET" "$DIM$BLUE" "$RESET"
        printf "%s│%s  An existing installation was detected.                       %s│%s\n" "$DIM$BLUE" "$RESET" "$DIM$BLUE" "$RESET"
        
        if [ "$SERVICE_WAS_RUNNING" = true ]; then
            printf "%s│%s  The service is currently running and will be restarted.      %s│%s\n" "$DIM$BLUE" "$RESET" "$DIM$BLUE" "$RESET"
        fi
        
        printf "%s│%s  Would you like to reinstall and reconfigure?                 %s│%s\n" "$DIM$BLUE" "$RESET" "$DIM$BLUE" "$RESET"
        printf "%s│%s                                                               %s│%s\n" "$DIM$BLUE" "$RESET" "$DIM$BLUE" "$RESET"
        printf "%s└───────────────────────────────────────────────────────────────┘%s\n" "$DIM$BLUE" "$RESET"
        printf "\n"
        printf "  %sReinstall StartTunnel? [y/N]:%s " "$BOLD" "$RESET"
        
        read -r REINSTALL_RESPONSE < /dev/tty
        
        case "$REINSTALL_RESPONSE" in
            [yY]|[yY][eE][sS])
                info "Proceeding with reinstallation..."
                REINSTALL_MODE=true
                stop_service
                ;;
            *)
                info "Installation cancelled by user"
                printf "\n"
                printf "%sStartTunnel %s is already installed.%s\n" "$GREEN" "$INSTALLED_VERSION" "$RESET"
                printf "Service status: %ssystemctl status start-tunneld%s\n" "$DIM" "$RESET"
                printf "\n"
                exit 0
                ;;
        esac
    else
        success "No existing installation found"
        FRESH_INSTALL=true
    fi
}

# Detect system architecture
detect_architecture() {
    info "Detecting system architecture..."
    
    MACHINE_ARCH=$(uname -m)
    
    case "$MACHINE_ARCH" in
        x86_64)
            ARCH="x86_64"
            DISPLAY_ARCH="Intel/AMD64"
            ;;
        aarch64)
            ARCH="aarch64"
            DISPLAY_ARCH="ARM64"
            ;;
        riscv64)
            ARCH="riscv64"
            DISPLAY_ARCH="RISC-V 64"
            ;;
        *)
            err "Unsupported architecture: $MACHINE_ARCH. Supported: x86_64, aarch64, riscv64"
            ;;
    esac
    
    success "Architecture detected: $DISPLAY_ARCH"
}

# System information display
display_system_info() {
    BOX_WIDTH=63
    
    PLATFORM_TEXT="Debian (${DISPLAY_ARCH})"
    PLATFORM_LABEL="  Platform: "
    PLATFORM_SPACES=$((BOX_WIDTH - ${#PLATFORM_LABEL} - ${#PLATFORM_TEXT}))
    
    VERSION_TEXT="${VERSION}"
    VERSION_LABEL="  Version:  "
    VERSION_SPACES=$((BOX_WIDTH - ${#VERSION_LABEL} - ${#VERSION_TEXT}))
    
    printf "%s┌─ System Information ──────────────────────────────────────────┐%s\n" "$DIM" "$RESET"
    printf "%s│%s%s%s%s%*s%s│%s\n" "$DIM" "$RESET" "$PLATFORM_LABEL" "$GREEN" "$PLATFORM_TEXT" "$PLATFORM_SPACES" "" "$RESET$DIM" "$RESET"
    printf "%s│%s%s%s%s%*s%s│%s\n" "$DIM" "$RESET" "$VERSION_LABEL" "$GREEN" "$VERSION_TEXT" "$VERSION_SPACES" "" "$RESET$DIM" "$RESET"
    printf "%s└───────────────────────────────────────────────────────────────┘%s\n" "$DIM" "$RESET"
}

# Disable existing firewalls
disable_firewalls() {
    info "Checking for existing firewalls..."
    
    FIREWALL_DISABLED=false
    
    # Check and disable UFW
    if command -v ufw >/dev/null 2>&1; then
        if ufw status 2>/dev/null | grep -q "Status: active"; then
            info "Disabling UFW (StartTunnel will manage firewall rules)..."
            ufw --force disable > /dev/null 2>&1
            systemctl disable ufw > /dev/null 2>&1 || true
            systemctl stop ufw > /dev/null 2>&1 || true
            success "UFW disabled"
            FIREWALL_DISABLED=true
        fi
    fi
    
    # Check and disable firewalld
    if command -v firewall-cmd >/dev/null 2>&1; then
        if systemctl is-active --quiet firewalld 2>/dev/null; then
            info "Disabling firewalld (StartTunnel will manage firewall rules)..."
            systemctl stop firewalld > /dev/null 2>&1 || true
            systemctl disable firewalld > /dev/null 2>&1 || true
            success "firewalld disabled"
            FIREWALL_DISABLED=true
        fi
    fi
    
    # Check for iptables-persistent
    if systemctl is-enabled --quiet netfilter-persistent 2>/dev/null; then
        info "Disabling netfilter-persistent (StartTunnel will manage firewall rules)..."
        systemctl stop netfilter-persistent > /dev/null 2>&1 || true
        systemctl disable netfilter-persistent > /dev/null 2>&1 || true
        success "netfilter-persistent disabled"
        FIREWALL_DISABLED=true
    fi
    
    if [ "$FIREWALL_DISABLED" = true ]; then
        success "Existing firewalls disabled - StartTunnel will manage all firewall rules"
    else
        success "No active firewalls detected"
    fi
}

# Remove unnecessary packages
remove_unnecessary_packages() {
    info "Removing unnecessary packages to optimize VPS..."
    
    # List of package categories to remove (but keep system essentials and DNS clients)
    PACKAGES_TO_REMOVE=""
    
    # Desktop environments
    PACKAGES_TO_REMOVE="$PACKAGES_TO_REMOVE xserver-xorg* x11-common gdm3 lightdm gnome* kde* xfce*"
    
    # Web servers
    PACKAGES_TO_REMOVE="$PACKAGES_TO_REMOVE apache2* nginx* lighttpd"
    
    # Mail servers
    PACKAGES_TO_REMOVE="$PACKAGES_TO_REMOVE postfix exim4* sendmail* dovecot*"
    
    # Database servers
    PACKAGES_TO_REMOVE="$PACKAGES_TO_REMOVE mysql-server* mariadb-server* postgresql*"
    
    # FTP servers
    PACKAGES_TO_REMOVE="$PACKAGES_TO_REMOVE vsftpd proftpd*"
    
    # DNS servers (but NOT DNS client tools - we need those!)
    PACKAGES_TO_REMOVE="$PACKAGES_TO_REMOVE bind9 named dnsmasq"
    
    # Development tools (not needed on production VPN server)
    PACKAGES_TO_REMOVE="$PACKAGES_TO_REMOVE build-essential gcc g++ make"
    
    # Other services
    PACKAGES_TO_REMOVE="$PACKAGES_TO_REMOVE samba* cups* bluetooth* avahi-daemon"
    
    # Print servers and related
    PACKAGES_TO_REMOVE="$PACKAGES_TO_REMOVE printer-driver-* hplip*"
    
    # Check which packages are actually installed before attempting removal
    INSTALLED_TO_REMOVE=""
    for pkg in $PACKAGES_TO_REMOVE; do
        if dpkg -l 2>/dev/null | grep -q "^ii.*$pkg" 2>/dev/null; then
            INSTALLED_TO_REMOVE="$INSTALLED_TO_REMOVE $pkg"
        fi
    done
    
    if [ -n "$INSTALLED_TO_REMOVE" ]; then
        info "Removing unnecessary packages (this may take a moment)..."
        DEBIAN_FRONTEND=noninteractive apt-get remove --purge -y $INSTALLED_TO_REMOVE > /dev/null 2>&1 || true
        DEBIAN_FRONTEND=noninteractive apt-get autoremove -y > /dev/null 2>&1 || true
        DEBIAN_FRONTEND=noninteractive apt-get autoclean -y > /dev/null 2>&1 || true
        success "Unnecessary packages removed"
    else
        success "No unnecessary packages found"
    fi
}

# Update system packages
update_system() {
    printf "\n"
    printf "%s┌─ System Preparation ──────────────────────────────────────────┐%s\n" "$DIM$BLUE" "$RESET"
    printf "%s└───────────────────────────────────────────────────────────────┘%s\n" "$DIM$BLUE" "$RESET"
    printf "\n"
    
    info "Updating package lists..."
    if DEBIAN_FRONTEND=noninteractive apt-get update -qq 2>&1 | grep -v "^$" > /dev/null; then
        success "Package lists updated"
    else
        success "Package lists updated"
    fi
    
    info "Upgrading existing packages (this may take a few minutes)..."
    if DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq 2>&1 | grep -v "^$" > /dev/null; then
        success "System packages upgraded"
    else
        success "System packages upgraded"
    fi
}

# Install required dependencies
install_dependencies() {
    info "Installing required dependencies for WireGuard..."
    
    # Minimal required packages for WireGuard and StartTunnel
    # IMPORTANT: Include DNS client tools
    REQUIRED_PACKAGES="ca-certificates gnupg wireguard wireguard-tools iptables iproute2 openresolv dnsutils iputils-ping"
    
    if DEBIAN_FRONTEND=noninteractive apt-get install -y -qq $REQUIRED_PACKAGES 2>&1 | grep -v "^$" > /dev/null; then
        success "Dependencies installed"
    else
        success "Dependencies installed"
    fi
    
    # Verify WireGuard kernel module
    if ! lsmod | grep -q wireguard; then
        info "Loading WireGuard kernel module..."
        if modprobe wireguard 2>/dev/null; then
            success "WireGuard kernel module loaded"
        else
            warn "WireGuard module may not be available, but will continue (may work with userspace implementation)"
        fi
    else
        success "WireGuard kernel module already loaded"
    fi
}

# Configure IP forwarding
configure_ip_forwarding() {
    info "Configuring IP forwarding for VPN..."
    
    # Enable IPv4 forwarding
    if grep -q "^net.ipv4.ip_forward=1" /etc/sysctl.conf; then
        success "IPv4 forwarding already enabled"
    else
        if grep -q "^#net.ipv4.ip_forward=1" /etc/sysctl.conf; then
            sed -i 's/^#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
        else
            echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
        fi
        sysctl -p /etc/sysctl.conf > /dev/null 2>&1
        success "IPv4 forwarding enabled"
    fi
    
    # Enable IPv6 forwarding
    if grep -q "^net.ipv6.conf.all.forwarding=1" /etc/sysctl.conf; then
        success "IPv6 forwarding already enabled"
    else
        if grep -q "^#net.ipv6.conf.all.forwarding=1" /etc/sysctl.conf; then
            sed -i 's/^#net.ipv6.conf.all.forwarding=1/net.ipv6.conf.all.forwarding=1/' /etc/sysctl.conf
        else
            echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf
        fi
        sysctl -p /etc/sysctl.conf > /dev/null 2>&1
        success "IPv6 forwarding enabled"
    fi
}

# Download package
download_package() {
    printf "\n"
    printf "%s┌─ StartTunnel Installation ────────────────────────────────────┐%s\n" "$DIM$BLUE" "$RESET"
    printf "%s└───────────────────────────────────────────────────────────────┘%s\n" "$DIM$BLUE" "$RESET"
    printf "\n"
    
    info "Downloading StartTunnel package..."
    
    PACKAGE_NAME="${PACKAGE_PREFIX}_${ARCH}.deb"
    DOWNLOAD_URL="${BASE_URL}/${PACKAGE_NAME}"
    TEMP_DIR=$(mktemp -d)
    PACKAGE_PATH="${TEMP_DIR}/${PACKAGE_NAME}"
    
    if command -v curl >/dev/null 2>&1; then
        if COLUMNS=65 curl --progress-bar -fL "$DOWNLOAD_URL" -o "$PACKAGE_PATH"; then
            success "Download completed"
        else
            rm -rf "$TEMP_DIR"
            err "Failed to download package"
        fi
    elif command -v wget >/dev/null 2>&1; then
        if wget -q --show-progress --progress=bar:force "$DOWNLOAD_URL" -O "$PACKAGE_PATH" 2>&1 | grep -v "^$"; then
            success "Download completed"
        else
            rm -rf "$TEMP_DIR"
            err "Failed to download package"
        fi
    else
        rm -rf "$TEMP_DIR"
        err "Neither wget nor curl is available"
    fi
}

# Install package
install_package() {
    if [ "$REINSTALL_MODE" = true ]; then
        info "Reinstalling StartTunnel..."
    else
        info "Installing StartTunnel..."
    fi
    
    if [ "$REINSTALL_MODE" = true ]; then
        if apt-get --reinstall install -y "$PACKAGE_PATH" >/dev/null 2>&1; then
            success "StartTunnel reinstalled successfully"
        else
            if dpkg -i "$PACKAGE_PATH" >/dev/null 2>&1; then
                success "StartTunnel reinstalled successfully"
            else
                info "Resolving dependencies..."
                apt-get install -f -y >/dev/null 2>&1
                success "StartTunnel reinstalled successfully"
            fi
        fi
    else
        if apt install -y "$PACKAGE_PATH" >/dev/null 2>&1; then
            success "StartTunnel installed successfully"
        elif dpkg -i "$PACKAGE_PATH" >/dev/null 2>&1; then
            success "StartTunnel installed successfully"
        else
            info "Resolving dependencies..."
            apt-get install -f -y >/dev/null 2>&1
            success "StartTunnel installed successfully"
        fi
    fi
    
    rm -rf "$TEMP_DIR"
}

# Verify installation
verify_installation() {
    info "Verifying installation..."
    
    if command -v start-tunnel >/dev/null 2>&1; then
        INSTALLED_VERSION=$(start-tunnel --version 2>/dev/null || echo "installed")
        success "Installation verified: $INSTALLED_VERSION"
    elif dpkg -l | grep -q start-tunnel; then
        INSTALLED_VERSION=$(dpkg -s "$PACKAGE_NAME_BASE" 2>/dev/null | grep '^Version:' | awk '{print $2}')
        success "Installation verified via dpkg (version: $INSTALLED_VERSION)"
    else
        err "StartTunnel installation could not be verified"
    fi
}

# Enable and start service
enable_and_start_service() {
    printf "\n"
    printf "%s┌─ Service Configuration ───────────────────────────────────────┐%s\n" "$DIM$BLUE" "$RESET"
    printf "%s└───────────────────────────────────────────────────────────────┘%s\n" "$DIM$BLUE" "$RESET"
    printf "\n"
    
    # Reload systemd daemon
    info "Reloading systemd daemon..."
    systemctl daemon-reload 2>/dev/null
    success "Systemd daemon reloaded"
    
    # Enable service
    if ! systemctl is-enabled --quiet "$SERVICE_NAME" 2>/dev/null; then
        info "Enabling $SERVICE_NAME to start on boot..."
        if systemctl enable "$SERVICE_NAME" 2>/dev/null; then
            success "Service enabled on boot"
        else
            warn "Could not enable service on boot"
        fi
    else
        success "Service already enabled on boot"
    fi
    
    # Start service
    if systemctl is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
        info "Restarting $SERVICE_NAME..."
        if systemctl restart "$SERVICE_NAME" 2>/dev/null; then
            success "Service restarted"
        else
            warn "Could not restart service"
        fi
    else
        info "Starting $SERVICE_NAME..."
        if systemctl start "$SERVICE_NAME" 2>/dev/null; then
            success "Service started"
        else
            warn "Could not start service"
        fi
    fi
    
    # Wait a moment for service to initialize
    sleep 3
    
    # Check service status
    if systemctl is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
        success "Service is running"
    else
        warn "Service may not be running correctly"
        printf "    %sCheck status with: systemctl status start-tunneld%s\n" "$DIM" "$RESET"
        printf "    %sView logs with: journalctl -u start-tunneld -f%s\n" "$DIM" "$RESET"
    fi
}

# Configure web interface
configure_web_interface() {
    printf "\n"
    printf "%s┌─ Web Interface Configuration ─────────────────────────────────┐%s\n" "$DIM$BLUE" "$RESET"
    printf "%s│%s                                                               %s│%s\n" "$DIM$BLUE" "$RESET" "$DIM$BLUE" "$RESET"
    printf "%s│%s  StartTunnel includes a web-based management interface.       %s│%s\n" "$DIM$BLUE" "$RESET" "$DIM$BLUE" "$RESET"
    printf "%s│%s  This is required for managing your VPN connections.          %s│%s\n" "$DIM$BLUE" "$RESET" "$DIM$BLUE" "$RESET"
    printf "%s│%s                                                               %s│%s\n" "$DIM$BLUE" "$RESET" "$DIM$BLUE" "$RESET"
    printf "%s└───────────────────────────────────────────────────────────────┘%s\n" "$DIM$BLUE" "$RESET"
    printf "\n"
    
    # Ensure service is running before attempting web configuration
    if ! systemctl is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
        warn "Service is not running. Starting service before web configuration..."
        if systemctl start "$SERVICE_NAME" 2>/dev/null; then
            sleep 3
            success "Service started"
        else
            warn "Could not start service. Web configuration may fail."
        fi
    fi
    
    if [ "$FRESH_INSTALL" = true ]; then
        printf "  %sConfigure Web Interface now? [Y/n]:%s " "$BOLD" "$RESET"
        read -r WEB_CONFIG_RESPONSE < /dev/tty
        
        case "$WEB_CONFIG_RESPONSE" in
            [nN]|[nN][oO])
                warn "Skipping web interface configuration"
                printf "    %sYou can configure it later with: start-tunnel web init%s\n" "$DIM" "$RESET"
                return 0
                ;;
        esac
        
        info "Launching web interface configuration..."
        printf "\n"
        
        if command -v start-tunnel >/dev/null 2>&1; then
            if start-tunnel web init < /dev/tty; then
                printf "\n"
                success "Web interface configured successfully"
                return 0
            else
                WEB_INIT_EXIT=$?
                printf "\n"
                if [ $WEB_INIT_EXIT -ne 0 ]; then
                    warn "Web interface configuration exited with code $WEB_INIT_EXIT"
                    printf "    %sYou can configure it later with: start-tunnel web init%s\n" "$DIM" "$RESET"
                fi
                return 0
            fi
        else
            err "start-tunnel command not found after installation"
        fi
    else
        # Reinstall mode - check if web interface is already configured
        printf "  %sReconfigure Web Interface? [y/N]:%s " "$BOLD" "$RESET"
        read -r WEB_CONFIG_RESPONSE < /dev/tty
        
        case "$WEB_CONFIG_RESPONSE" in
            [yY]|[yY][eE][sS])
                info "Resetting existing web interface configuration..."
                
                # Run web reset to clear existing configuration
                # WARNING: This command wipes settings without confirmation!
                if command -v start-tunnel >/dev/null 2>&1; then
                    if start-tunnel web reset > /dev/null 2>&1; then
                        success "Web interface reset successfully"
                    else
                        warn "Could not reset web interface (may not have been configured)"
                    fi
                    
                    # Wait a moment for reset to complete
                    sleep 2
                    
                    # Now run init for fresh configuration
                    info "Launching web interface configuration..."
                    printf "\n"
                    
                    if start-tunnel web init < /dev/tty; then
                        printf "\n"
                        success "Web interface configured successfully"
                        return 0
                    else
                        WEB_INIT_EXIT=$?
                        printf "\n"
                        if [ $WEB_INIT_EXIT -ne 0 ]; then
                            warn "Web interface configuration exited with code $WEB_INIT_EXIT"
                            printf "    %sYou can configure it later with: start-tunnel web init%s\n" "$DIM" "$RESET"
                        fi
                        return 0
                    fi
                else
                    err "start-tunnel command not found"
                fi
                ;;
            *)
                info "Keeping existing web interface configuration"
                return 0
                ;;
        esac
    fi
}

# Verify everything is working
verify_system() {
    printf "\n"
    printf "%s┌─ System Verification ─────────────────────────────────────────┐%s\n" "$DIM$BLUE" "$RESET"
    printf "%s└───────────────────────────────────────────────────────────────┘%s\n" "$DIM$BLUE" "$RESET"
    printf "\n"
    
    # Check DNS
    if verify_dns > /dev/null 2>&1; then
        success "DNS resolution is working"
    else
        warn "DNS resolution may have issues"
    fi
    
    # Check WireGuard
    if command -v wg >/dev/null 2>&1; then
        success "WireGuard tools installed"
    else
        warn "WireGuard tools not found"
    fi
    
    # Check IP forwarding
    if sysctl net.ipv4.ip_forward | grep -q "= 1"; then
        success "IPv4 forwarding enabled"
    else
        warn "IPv4 forwarding may not be enabled"
    fi
    
    # Check that firewalls are disabled
    FIREWALL_ACTIVE=false
    if command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -q "Status: active"; then
        warn "UFW is still active (should be disabled)"
        FIREWALL_ACTIVE=true
    fi
    
    if command -v firewall-cmd >/dev/null 2>&1 && systemctl is-active --quiet firewalld 2>/dev/null; then
        warn "firewalld is still active (should be disabled)"
        FIREWALL_ACTIVE=true
    fi
    
    if [ "$FIREWALL_ACTIVE" = false ]; then
        success "System firewalls disabled (StartTunnel manages firewall rules)"
    fi
    
    # Check start-tunnel binary
    if command -v start-tunnel >/dev/null 2>&1; then
        success "start-tunnel command available"
    else
        warn "start-tunnel command not found in PATH"
    fi
    
    # Check service
    if systemctl is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
        success "start-tunneld service is running"
    else
        warn "start-tunneld service is not running"
    fi
    
    if systemctl is-enabled --quiet "$SERVICE_NAME" 2>/dev/null; then
        success "start-tunneld service enabled on boot"
    else
        warn "start-tunneld service not enabled on boot"
    fi
}

# Get server IP
get_server_ip() {
    # Try multiple methods to get public IP
    SERVER_IP=""
    
    if command -v curl >/dev/null 2>&1; then
        SERVER_IP=$(curl -s -4 ifconfig.me 2>/dev/null || curl -s -4 icanhazip.com 2>/dev/null || curl -s -4 api.ipify.org 2>/dev/null)
    elif command -v wget >/dev/null 2>&1; then
        SERVER_IP=$(wget -qO- -4 ifconfig.me 2>/dev/null || wget -qO- -4 icanhazip.com 2>/dev/null)
    fi
    
    # Fallback to ip command if external IP lookup fails
    if [ -z "$SERVER_IP" ]; then
        SERVER_IP=$(ip -4 addr show scope global | grep inet | head -1 | awk '{print $2}' | cut -d/ -f1)
    fi
    
    echo "$SERVER_IP"
}

# Display success and next steps
display_success() {
    SERVER_IP=$(get_server_ip)
    
    printf "\n"
    printf "%s┌───────────────────────────────────────────────────────────────┐%s\n" "$DIM$GREEN" "$RESET"
    if [ "$REINSTALL_MODE" = true ]; then
        printf "%s│%s%19s%s%sREINSTALLATION SUCCESSFUL%s%s%19s%s│%s\n" "$DIM$GREEN" "$RESET" "" "$RESET" "$GREEN$BOLD" "$RESET" "$DIM$GREEN" "" "$DIM$GREEN" "$RESET"
    else
        printf "%s│%s%20s%s%sSETUP COMPLETE%s%s%21s%s│%s\n" "$DIM$GREEN" "$RESET" "" "$RESET" "$GREEN$BOLD" "$RESET" "$DIM$GREEN" "" "$DIM$GREEN" "$RESET"
    fi
    printf "%s└───────────────────────────────────────────────────────────────┘%s\n" "$DIM$GREEN" "$RESET"
    printf "\n"
    
    printf "%sYour StartTunnel VPN server is now running!%s\n" "$BOLD" "$RESET"
    printf "\n"
    
    printf "%s┌─ Server Information ──────────────────────────────────────────┐%s\n" "$DIM" "$RESET"
    if [ -n "$SERVER_IP" ]; then
        printf "%s│%s  Server IP:    %s%-47s%s│%s\n" "$DIM" "$RESET" "$GREEN" "$SERVER_IP" "$DIM" "$RESET"
    fi
    printf "%s│%s  WireGuard:    %s%-47s%s│%s\n" "$DIM" "$RESET" "$GREEN" "Managed by StartTunnel" "$DIM" "$RESET"
    printf "%s│%s  Service:      %s%-47s%s│%s\n" "$DIM" "$RESET" "$GREEN" "start-tunneld (running)" "$DIM" "$RESET"
    printf "%s│%s  Firewall:     %s%-47s%s│%s\n" "$DIM" "$RESET" "$GREEN" "Managed by StartTunnel" "$DIM" "$RESET"
    printf "%s│%s  DNS:          %s%-47s%s│%s\n" "$DIM" "$RESET" "$GREEN" "Configured (8.8.8.8, 1.1.1.1)" "$DIM" "$RESET"
    printf "%s└───────────────────────────────────────────────────────────────┘%s\n" "$DIM" "$RESET"
    printf "\n"
    
    printf "%sService Management:%s\n" "$BOLD" "$RESET"
    printf "%s────────────────────────────────────────────────────────────────%s\n" "$DIM" "$RESET"
    printf "  Status:  %ssystemctl status start-tunneld%s\n" "$DIM" "$RESET"
    printf "  Stop:    %ssystemctl stop start-tunneld%s\n" "$DIM" "$RESET"
    printf "  Start:   %ssystemctl start start-tunneld%s\n" "$DIM" "$RESET"
    printf "  Restart: %ssystemctl restart start-tunneld%s\n" "$DIM" "$RESET"
    printf "  Logs:    %sjournalctl -u start-tunneld -f%s\n" "$DIM" "$RESET"
    printf "\n"
    
    printf "%sConfiguration:%s\n" "$BOLD" "$RESET"
    printf "%s────────────────────────────────────────────────────────────────%s\n" "$DIM" "$RESET"
    printf "  Web Interface: %sstart-tunnel web init%s\n" "$DIM" "$RESET"
    printf "  Reset Web UI:  %sstart-tunnel web reset%s\n" "$DIM" "$RESET"
    printf "  Config Files:  %s~/.startos/%s\n" "$DIM" "$RESET"
    printf "\n"
    
    printf "%sFirewall:%s\n" "$BOLD" "$RESET"
    printf "%s────────────────────────────────────────────────────────────────%s\n" "$DIM" "$RESET"
    printf "  %sStartTunnel manages all firewall rules automatically%s\n" "$GREEN" "$RESET"
    printf "  System firewalls (UFW, firewalld) have been disabled\n"
    printf "\n"
    
    printf "%sDocumentation:%s\n" "$BOLD" "$RESET"
    printf "%s────────────────────────────────────────────────────────────────%s\n" "$DIM" "$RESET"
    printf "  %shttps://staging.docs.start9.com%s\n" "$BLUE" "$RESET"
    printf "\n"
    
    printf "%sNOTE:%s This VPS has been optimized specifically for StartTunnel.\n" "$YELLOW$BOLD" "$RESET"
    printf "Unnecessary services have been removed for security and performance.\n"
    printf "\n"
}

# Main execution
main() {
    # Pre-flight checks
    check_debian
    ensure_root "$@"
    
    # Ensure we have download tools early
    ensure_download_tool
    
    # Check for existing installation
    check_existing_installation
    detect_architecture
    display_system_info
    
    # System preparation (only on fresh install or if user confirms)
    if [ "$FRESH_INSTALL" = true ] || [ "$REINSTALL_MODE" = true ]; then
        update_system
        
        # Configure DNS BEFORE removing packages
        configure_dns
        verify_dns
        
        disable_firewalls
        remove_unnecessary_packages
        install_dependencies
        configure_ip_forwarding
        
        # Verify DNS again after package changes
        configure_dns
        verify_dns
    fi
    
    # Install StartTunnel
    download_package
    install_package
    verify_installation
    
    # IMPORTANT: Start service BEFORE web configuration
    # The web init/reset commands need the service to be running
    enable_and_start_service
    
    # Configure web interface (now that service is running)
    configure_web_interface
    
    # Verify everything
    verify_system
    
    # Success!
    display_success
}

# Run main function
main "$@"