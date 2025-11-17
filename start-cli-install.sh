#!/bin/sh
# start-tunnel installer for Debian VPS systems
# Downloads and installs start-tunnel from official GitHub releases

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
printf "%s└───────────────────────────────────────────────────────────────┘%s\n" "$DIM$RED" "$RESET"
printf "\n"

err() { printf "%sError:%s %s\n" "$RED$BOLD" "$RESET" "$1" >&2; exit 1; }

# Configuration
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

# Verify this is a Debian system (run first, before root check)
check_debian() {
    printf "%s•%s Checking operating system...\n" "$YELLOW" "$RESET"
    
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
        # Get major version from VERSION_ID
        if [ -n "${VERSION_ID:-}" ]; then
            DEBIAN_MAJOR=$(echo "$VERSION_ID" | cut -d. -f1)
        elif [ -f /etc/debian_version ]; then
            # Fallback to /etc/debian_version
            DEBIAN_MAJOR=$(cat /etc/debian_version | cut -d. -f1)
        else
            DEBIAN_MAJOR="unknown"
        fi
        
        # Validate it's a number and check minimum version
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
    
    printf "%s✓%s Operating system verified: %s\n" "$GREEN" "$RESET" "$NAME"
}

# Check if running as root, escalate if needed
ensure_root() {
    if [ "$(id -u)" -ne 0 ]; then
        printf "%s•%s This script requires root privileges. Attempting to use sudo...\n" "$YELLOW" "$RESET"
        
        if ! command -v sudo >/dev/null 2>&1; then
            err "sudo is not available and script is not running as root"
        fi
        
        # Re-run script with sudo
        exec sudo sh "$0" "$@"
    fi
}

# Check service status
check_service_status() {
    # Check if service is running
    if systemctl is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
        SERVICE_WAS_RUNNING=true
        printf "%s•%s Service %s%s%s is currently running\n" "$YELLOW" "$RESET" "$BOLD" "$SERVICE_NAME" "$RESET"
    fi
    
    # Check if service is enabled
    if systemctl is-enabled --quiet "$SERVICE_NAME" 2>/dev/null; then
        SERVICE_WAS_ENABLED=true
    fi
}

# Stop service gracefully
stop_service() {
    if [ "$SERVICE_WAS_RUNNING" = true ]; then
        printf "%s•%s Stopping %s gracefully...\n" "$YELLOW" "$RESET" "$SERVICE_NAME"
        
        if systemctl stop "$SERVICE_NAME" 2>/dev/null; then
            printf "%s✓%s Service stopped successfully\n" "$GREEN" "$RESET"
        else
            printf "%sWarning:%s Could not stop service gracefully\n" "$YELLOW$BOLD" "$RESET"
        fi
    fi
}

# Restart service after installation
restart_service() {
    if [ "$SERVICE_WAS_RUNNING" = true ]; then
        printf "%s•%s Restarting %s...\n" "$YELLOW" "$RESET" "$SERVICE_NAME"
        
        # Reload systemd daemon in case service file changed
        systemctl daemon-reload 2>/dev/null || true
        
        if systemctl start "$SERVICE_NAME" 2>/dev/null; then
            printf "%s✓%s Service restarted successfully\n" "$GREEN" "$RESET"
            
            # Brief status check
            sleep 2
            if systemctl is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
                printf "%s✓%s Service is running\n" "$GREEN" "$RESET"
            else
                printf "%sWarning:%s Service started but may have issues. Check: systemctl status %s\n" "$YELLOW$BOLD" "$RESET" "$SERVICE_NAME"
            fi
        else
            printf "%sWarning:%s Could not restart service. Check: systemctl status %s\n" "$YELLOW$BOLD" "$RESET" "$SERVICE_NAME"
        fi
    fi
    
    # Re-enable if it was enabled before
    if [ "$SERVICE_WAS_ENABLED" = true ]; then
        if ! systemctl is-enabled --quiet "$SERVICE_NAME" 2>/dev/null; then
            printf "%s•%s Re-enabling service on boot...\n" "$YELLOW" "$RESET"
            systemctl enable "$SERVICE_NAME" 2>/dev/null || true
            printf "%s✓%s Service enabled\n" "$GREEN" "$RESET"
        fi
    fi
}

# Check if start-tunnel is already installed
check_existing_installation() {
    printf "%s•%s Checking for existing installation...\n" "$YELLOW" "$RESET"
    
    # Check using dpkg (only if dpkg exists)
    if command -v dpkg >/dev/null 2>&1 && dpkg -l 2>/dev/null | grep -q "^ii.*$PACKAGE_NAME_BASE" 2>/dev/null; then
        INSTALLED_VERSION=$(dpkg -s "$PACKAGE_NAME_BASE" 2>/dev/null | grep '^Version:' | awk '{print $2}')
        printf "%s!%s StartTunnel is already installed (version: %s%s%s)\n" "$YELLOW" "$RESET" "$BOLD" "$INSTALLED_VERSION" "$RESET"
        
        # Check service status before prompting
        check_service_status
        
        # Prompt user for reinstall
        printf "\n"
        printf "%s┌─ Reinstall Confirmation ──────────────────────────────────────┐%s\n" "$DIM$BLUE" "$RESET"
        printf "%s│%s                                                               %s│%s\n" "$DIM$BLUE" "$RESET" "$DIM$BLUE" "$RESET"
        printf "%s│%s  An existing installation was detected.                       %s│%s\n" "$DIM$BLUE" "$RESET" "$DIM$BLUE" "$RESET"
        
        if [ "$SERVICE_WAS_RUNNING" = true ]; then
            printf "%s│%s  The service is currently running and will be restarted.      %s│%s\n" "$DIM$BLUE" "$RESET" "$DIM$BLUE" "$RESET"
        fi
        
        printf "%s│%s  Would you like to reinstall StartTunnel?                     %s│%s\n" "$DIM$BLUE" "$RESET" "$DIM$BLUE" "$RESET"
        printf "%s│%s                                                               %s│%s\n" "$DIM$BLUE" "$RESET" "$DIM$BLUE" "$RESET"
        printf "%s└───────────────────────────────────────────────────────────────┘%s\n" "$DIM$BLUE" "$RESET"
        printf "\n"
        printf "  %sReinstall StartTunnel? [y/N]:%s " "$BOLD" "$RESET"
        
        # Read user input
        read -r REINSTALL_RESPONSE < /dev/tty
        
        case "$REINSTALL_RESPONSE" in
            [yY]|[yY][eE][sS])
                printf "%s•%s Proceeding with reinstallation...\n" "$YELLOW" "$RESET"
                REINSTALL_MODE=true
                
                # Stop service before reinstall
                stop_service
                ;;
            *)
                printf "%s•%s Installation cancelled by user\n" "$DIM" "$RESET"
                printf "\n"
                printf "%sStartTunnel %s is already installed.%s\n" "$GREEN" "$INSTALLED_VERSION" "$RESET"
                printf "Run with reinstall option if you want to update or repair the installation.\n"
                printf "\n"
                exit 0
                ;;
        esac
    else
        printf "%s✓%s No existing installation found\n" "$GREEN" "$RESET"
    fi
}

# Detect system architecture
detect_architecture() {
    printf "%s•%s Detecting system architecture...\n" "$YELLOW" "$RESET"
    
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
    
    printf "%s✓%s Architecture detected: %s\n" "$GREEN" "$RESET" "$DISPLAY_ARCH"
}

# Check firewall status
check_firewall() {
    printf "%s•%s Checking firewall configuration...\n" "$YELLOW" "$RESET"
    
    # Check if UFW is installed
    if ! command -v ufw >/dev/null 2>&1; then
        printf "%s✓%s UFW is not installed (no firewall to configure)\n" "$GREEN" "$RESET"
        return 0
    fi
    
    # Check UFW status
    UFW_STATUS=$(ufw status 2>/dev/null | head -1 | awk '{print $2}')
    
    if [ "$UFW_STATUS" = "inactive" ]; then
        printf "%s✓%s UFW is installed but inactive\n" "$GREEN" "$RESET"
    else
        printf "%s!%s UFW is active - firewall configuration may be required\n" "$YELLOW" "$RESET"
        printf "    %sStartTunnel uses WireGuard (UDP port 51820 by default)%s\n" "$DIM" "$RESET"
        printf "    %sTo allow traffic: sudo ufw allow 51820/udp%s\n" "$DIM" "$RESET"
    fi
}

# System information display
display_system_info() {
    BOX_WIDTH=63
    
    # Platform line
    PLATFORM_TEXT="Debian (${DISPLAY_ARCH})"
    PLATFORM_LABEL="  Platform: "
    PLATFORM_SPACES=$((BOX_WIDTH - ${#PLATFORM_LABEL} - ${#PLATFORM_TEXT}))
    
    # Version line
    VERSION_TEXT="${VERSION#v}"
    VERSION_LABEL="  Version:  "
    VERSION_SPACES=$((BOX_WIDTH - ${#VERSION_LABEL} - ${#VERSION_TEXT}))
    
    printf "%s┌─ System Information ──────────────────────────────────────────┐%s\n" "$DIM" "$RESET"
    printf "%s│%s%s%s%s%*s%s│%s\n" "$DIM" "$RESET" "$PLATFORM_LABEL" "$GREEN" "$PLATFORM_TEXT" "$PLATFORM_SPACES" "" "$RESET$DIM" "$RESET"
    printf "%s│%s%s%s%s%*s%s│%s\n" "$DIM" "$RESET" "$VERSION_LABEL" "$GREEN" "$VERSION_TEXT" "$VERSION_SPACES" "" "$RESET$DIM" "$RESET"
    printf "%s└───────────────────────────────────────────────────────────────┘%s\n" "$DIM" "$RESET"
}

# Download package
download_package() {
    printf "%s•%s Downloading StartTunnel package...\n" "$YELLOW" "$RESET"
    
    PACKAGE_NAME="${PACKAGE_PREFIX}_${ARCH}.deb"
    DOWNLOAD_URL="${BASE_URL}/${PACKAGE_NAME}"
    TEMP_DIR=$(mktemp -d)
    PACKAGE_PATH="${TEMP_DIR}/${PACKAGE_NAME}"
    
    # Check if wget or curl is available
    if command -v curl >/dev/null 2>&1; then
        if COLUMNS=65 curl --progress-bar -fL "$DOWNLOAD_URL" -o "$PACKAGE_PATH"; then
            printf "%s✓%s Download completed\n" "$GREEN" "$RESET"
        else
            rm -rf "$TEMP_DIR"
            err "Failed to download package from $DOWNLOAD_URL"
        fi
    elif command -v wget >/dev/null 2>&1; then
        if wget -q --show-progress --progress=bar:force "$DOWNLOAD_URL" -O "$PACKAGE_PATH" 2>&1 | grep -v "^$"; then
            printf "%s✓%s Download completed\n" "$GREEN" "$RESET"
        else
            rm -rf "$TEMP_DIR"
            err "Failed to download package from $DOWNLOAD_URL"
        fi
    else
        rm -rf "$TEMP_DIR"
        err "Neither wget nor curl is available. Please install one of them."
    fi
}

# Install or reinstall package
install_package() {
    if [ "$REINSTALL_MODE" = true ]; then
        printf "%s•%s Reinstalling StartTunnel...\n" "$YELLOW" "$RESET"
    else
        printf "%s•%s Installing StartTunnel...\n" "$YELLOW" "$RESET"
    fi
    
    # Update package lists
    apt-get update -qq 2>/dev/null || true
    
    # If reinstalling, use --reinstall flag
    if [ "$REINSTALL_MODE" = true ]; then
        if apt-get --reinstall install -y "$PACKAGE_PATH" >/dev/null 2>&1; then
            printf "%s✓%s StartTunnel reinstalled successfully\n" "$GREEN" "$RESET"
        else
            # Fallback to dpkg
            if dpkg -i "$PACKAGE_PATH" >/dev/null 2>&1; then
                printf "%s✓%s StartTunnel reinstalled successfully\n" "$GREEN" "$RESET"
            else
                printf "%s•%s Resolving dependencies...\n" "$YELLOW" "$RESET"
                apt-get install -f -y >/dev/null 2>&1
                printf "%s✓%s StartTunnel reinstalled successfully\n" "$GREEN" "$RESET"
            fi
        fi
    else
        # Fresh install
        if apt install -y "$PACKAGE_PATH" >/dev/null 2>&1; then
            printf "%s✓%s StartTunnel installed successfully\n" "$GREEN" "$RESET"
        elif dpkg -i "$PACKAGE_PATH" >/dev/null 2>&1; then
            printf "%s✓%s StartTunnel installed successfully\n" "$GREEN" "$RESET"
        else
            printf "%s•%s Resolving dependencies...\n" "$YELLOW" "$RESET"
            apt-get install -f -y >/dev/null 2>&1
            printf "%s✓%s StartTunnel installed successfully\n" "$GREEN" "$RESET"
        fi
    fi
    
    # Cleanup
    rm -rf "$TEMP_DIR"
}

# Verify installation
verify_installation() {
    printf "%s•%s Verifying installation...\n" "$YELLOW" "$RESET"
    
    if command -v start-tunnel >/dev/null 2>&1; then
        INSTALLED_VERSION=$(start-tunnel --version 2>/dev/null || echo "installed")
        printf "%s✓%s Installation verified: %s\n" "$GREEN" "$RESET" "$INSTALLED_VERSION"
    elif dpkg -l | grep -q start-tunnel; then
        INSTALLED_VERSION=$(dpkg -s "$PACKAGE_NAME_BASE" 2>/dev/null | grep '^Version:' | awk '{print $2}')
        printf "%s✓%s Installation verified via dpkg (version: %s)\n" "$GREEN" "$RESET" "$INSTALLED_VERSION"
    else
        err "StartTunnel installation could not be verified"
    fi
}

# Main execution
main() {
    # Check OS FIRST before anything else (including root check)
    check_debian
    
    # Now check for root privileges
    ensure_root "$@"
    
    # Continue with remaining checks
    check_existing_installation
    detect_architecture
    display_system_info
    check_firewall
    download_package
    install_package
    verify_installation
    
    # Restart service if it was running before
    if [ "$REINSTALL_MODE" = true ]; then
        restart_service
    fi
    
    # Success message
    printf "\n"
    printf "%s┌───────────────────────────────────────────────────────────────┐%s\n" "$DIM$GREEN" "$RESET"
    if [ "$REINSTALL_MODE" = true ]; then
        printf "%s│%s%19s%s%sREINSTALLATION SUCCESSFUL%s%s%19s%s│%s\n" "$DIM$GREEN" "$RESET" "" "$RESET" "$GREEN" "$RESET" "$DIM$GREEN" "" "$DIM$GREEN" "$RESET"
    else
        printf "%s│%s%20s%s%sINSTALLATION SUCCESSFUL%s%s%20s%s│%s\n" "$DIM$GREEN" "$RESET" "" "$RESET" "$GREEN" "$RESET" "$DIM$GREEN" "" "$DIM$GREEN" "$RESET"
    fi
    printf "%s└───────────────────────────────────────────────────────────────┘%s\n" "$DIM$GREEN" "$RESET"
    printf "\n"
    printf "%sStartTunnel has been installed on your system.%s\n" "$BOLD" "$RESET"
    printf "\n"
    
    printf "%sNext Steps:%s\n" "$BOLD" "$RESET"
    printf "%s────────────────────────────────────────────────────────────────%s\n" "$DIM" "$RESET"
    
    if [ "$REINSTALL_MODE" = false ]; then
        printf "  %s1.%s Configure StartTunnel for your network\n" "$GREEN$BOLD" "$RESET"
        printf "  %s2.%s Start the service: %ssystemctl start start-tunneld%s\n" "$GREEN$BOLD" "$RESET" "$DIM" "$RESET"
        printf "  %s3.%s Enable on boot:    %ssystemctl enable start-tunneld%s\n" "$GREEN$BOLD" "$RESET" "$DIM" "$RESET"
    else
        if [ "$SERVICE_WAS_RUNNING" = true ]; then
            printf "  %s•%s Service has been restarted\n" "$GREEN" "$RESET"
            printf "  %s•%s Check service status: %ssystemctl status start-tunneld%s\n" "$GREEN" "$RESET" "$DIM" "$RESET"
        else
            printf "  %s•%s Start the service: %ssystemctl start start-tunneld%s\n" "$GREEN" "$RESET" "$DIM" "$RESET"
        fi
    fi
    
    printf "\n"
    printf "%sConfiguration:%s\n" "$BOLD" "$RESET"
    printf "  Edit: %s~/.startos/config???%s\n" "$BLUE" "$RESET"
    printf "\n"
    printf "%sService Management:%s\n" "$BOLD" "$RESET"
    printf "  Status:  %ssystemctl status start-tunneld%s\n" "$DIM" "$RESET"
    printf "  Logs:    %sjournalctl -u start-tunneld -f%s\n" "$DIM" "$RESET"
    printf "\n"
    printf "%sDocumentation:%s https://staging.docs.start9.com\n" "$BLUE" "$RESET"
    printf "\n"
}

# Run main function
main "$@"