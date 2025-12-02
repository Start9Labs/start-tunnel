#!/usr/bin/env sh
# start-tunnel installer for Debian 12+ VPS systems
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
    GREY=$(tput setaf 8 2>/dev/null || echo '')
    RESET=$(tput sgr0 2>/dev/null || echo '')
    DIM=$(tput dim 2>/dev/null || echo '')
else
    BOLD='' BLUE='' GREEN='' YELLOW='' RED='' WHITE='' GREY='' RESET='' DIM=''
fi

BOX_WIDTH=63
BOX_COLOR="$DIM"

box_start() {
    BOX_COLOR="${1:-$DIM}"
    printf "%s┌───────────────────────────────────────────────────────────────┐%s\n" "$BOX_COLOR" "$RESET"
}
box_end() {
    printf "%s└───────────────────────────────────────────────────────────────┘%s\n" "$BOX_COLOR" "$RESET"
}
box_empty() {
    printf "%s│%s                                                               %s│%s\n" "$BOX_COLOR" "$RESET" "$BOX_COLOR" "$RESET"
}
box_line() {
    text="$1"
    align="${2:-left}"
    text_style="${3:-}"
    text_len=$(printf "%s" "$text" | wc -m | tr -d ' ')
    if printf "%s" "$text" | grep -q "[✓✗●○◆◇★☆]"; then
        text_len=$((text_len))
    fi
    if [ "$align" = "center" ]; then
        left_pad=$(( (61 - text_len) / 2 ))
        right_pad=$(( 63 - text_len - left_pad ))
        printf "%s│%s%*s%s%s%s%*s%s│%s\n" \
            "$BOX_COLOR" "$RESET" \
            "$left_pad" "" \
            "$text_style" "$text" "$RESET" \
            "$right_pad" "" \
            "$BOX_COLOR" "$RESET"
    else
        padding=$(( 61 - text_len ))
        printf "%s│%s  %s%s%s%*s%s│%s\n" \
            "$BOX_COLOR" "$RESET" \
            "$text_style" "$text" "$RESET" \
            "$padding" "" \
            "$BOX_COLOR" "$RESET"
    fi
}

err() {
    printf "%sError:%s %s\n" "$RED$BOLD" "$RESET" "$1" >&2
    exit 1
}

fix_stdin() {
    if [ ! -t 0 ]; then
        exec < /dev/tty
    fi
}

# Support only Debian 12+, inform early if not and exit
check_debian() {
    if [ ! -f /etc/os-release ]; then
        printf "\n"
        box_start "$DIM$RED"
        box_empty
        box_line "StartTunnel requires Debian 12+ (Bookworm or newer)." center "$BOLD"
        box_empty
        box_line "Could not find /etc/os-release: unsupported system." center
        box_empty
        box_end
        printf "\n"
        exit 1
    fi
    . /etc/os-release
    if [ "$ID" != "debian" ]; then
        printf "\n"
        box_start "$DIM$RED"
        box_empty
        box_line "StartTunnel installer supports ONLY Debian 12+ (Bookworm or newer)." center "$BOLD"
        box_empty
        box_line "Detected: $NAME" center
        box_line "Please run this script on Debian 12+ VPS." center
        box_empty
        box_end
        printf "\n"
        exit 1
    fi
    if [ -n "${VERSION_ID:-}" ]; then
        DEBIAN_MAJOR=$(echo "$VERSION_ID" | cut -d. -f1)
    elif [ -f /etc/debian_version ]; then
        DEBIAN_MAJOR=$(cat /etc/debian_version | cut -d. -f1)
    else
        DEBIAN_MAJOR="unknown"
    fi
    if ! echo "$DEBIAN_MAJOR" | grep -qE '^[0-9]+$'; then
        printf "\n"
        box_start "$DIM$RED"
        box_empty
        box_line "Unable to detect Debian major version." center
        box_line "Please run this script on Debian 12+ VPS." center
        box_empty
        box_end
        printf "\n"
        exit 1
    fi
    if [ "$DEBIAN_MAJOR" -lt 12 ]; then
        printf "\n"
        box_start "$DIM$RED"
        box_empty
        box_line "Detected: Debian $DEBIAN_MAJOR" center
        box_line "Required: Debian 12+ (Bookworm or newer)" center
        box_line "Please upgrade and run again." center
        box_empty
        box_end
        printf "\n"
        exit 1
    fi
}

ascii_banner() {
    printf "\n"
    box_start "$DIM$RED"
    box_empty
    box_line "start-tunnel" "center" "$WHITE$BOLD"
    box_empty
    box_line "Self-Hosted WireGuard VPN Server" "center" "$DIM"
    box_line "Optimized for reverse tunneling access" "center" "$DIM"
    box_empty
    box_end
    printf "\n"
}

ensure_root() {
    if [ "$(id -u)" -ne 0 ]; then
        if ! command -v sudo >/dev/null 2>&1; then
            err "This script requires root privileges but sudo is not available"
        fi
        TEMP_SCRIPT=$(mktemp /tmp/start-tunnel-installer.XXXXXX.sh)
        trap 'rm -f "$TEMP_SCRIPT"' EXIT INT TERM
        if [ ! -t 0 ] || [ "$0" = "sh" ] || [ "$0" = "bash" ]; then
            cat - > "$TEMP_SCRIPT"
        else
            cp "$0" "$TEMP_SCRIPT"
        fi
        chmod +x "$TEMP_SCRIPT"
        printf "\n"
        box_start "$DIM$YELLOW"
        box_empty
        box_line "Root privileges required. Re-running with sudo." center
        box_empty
        box_end
        printf "\n"
        exec sudo sh "$TEMP_SCRIPT" "$@"
        exit 1
    fi
}

# Installer configuration
VERSION="0.4.0-alpha.15"
BASE_URL="https://github.com/Start9Labs/start-os/releases/download/v${VERSION}"
PACKAGE_PREFIX="start-tunnel-${VERSION}-a53b15f.dev"
PACKAGE_NAME_BASE="start-tunnel"
SERVICE_NAME="start-tunneld.service"
MIN_DEBIAN_VERSION=12

REINSTALL_MODE=false
FRESH_INSTALL=true
INSTALLED_VERSION=""
SERVICE_WAS_RUNNING=false
SERVICE_WAS_ENABLED=false
SERVICE_IS_RUNNING=false
DNS_FIXED=false
CONFIGURE_WEB_UI=false

check_install_packages() {
    REQUIRED_PACKAGES="curl wireguard-tools"
    MISSING_PACKAGES=""
    for pkg in $REQUIRED_PACKAGES; do
        if ! dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
            MISSING_PACKAGES="$MISSING_PACKAGES $pkg"
        fi
    done
    if [ -n "$MISSING_PACKAGES" ]; then
        printf "Installing required packages:%s\n" "$MISSING_PACKAGES"
        apt-get update -qq 2>/dev/null || true
        if ! apt-get install -y $MISSING_PACKAGES >/dev/null 2>&1; then
            err "Failed to install required packages:$MISSING_PACKAGES"
        fi
    fi
}

check_dns() {
    if ! ping -c 1 -W 2 github.com >/dev/null 2>&1; then
        printf "\n"
        box_start "$DIM$YELLOW"
        box_empty
        box_line "Cannot resolve github.com. Checking connectivity..."
        box_end
        if ping -c 1 -W 2 1.1.1.1 >/dev/null 2>&1 || ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
            printf "Fixing DNS configuration...\n"
            if [ -f /etc/resolv.conf ]; then
                cp /etc/resolv.conf /etc/resolv.conf.backup 2>/dev/null || true
            fi
            cat > /etc/resolv.conf << 'EOF'
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
            DNS_FIXED=true
            if ! ping -c 1 -W 2 github.com >/dev/null 2>&1; then
                err "DNS configuration failed. Please check network connectivity"
            fi
            printf "\n"
            box_start "$DIM$GREEN"
            box_empty
            box_line "DNS configured with public resolvers."
            box_line "Backup saved to: /etc/resolv.conf.backup"
            box_empty
            box_end
            printf "\n"
        else
            err "No internet connectivity detected. Please check network connection"
        fi
    fi
}

check_disable_firewall() {
    FIREWALL_DISABLED=false
    
    if command -v ufw >/dev/null 2>&1; then
        UFW_STATUS=$(ufw status 2>/dev/null | head -1 | awk '{print $2}')
        if [ "$UFW_STATUS" != "inactive" ]; then
            printf "\n"
            box_start "$DIM$YELLOW"
            box_empty
            box_line "UFW firewall detected. StartTunnel manages its own"
            box_line "firewall rules. Disabling UFW..."
            box_empty
            box_end
            
            ufw disable >/dev/null 2>&1 || true
            systemctl disable ufw 2>/dev/null || true
            systemctl stop ufw 2>/dev/null || true
            FIREWALL_DISABLED=true
        fi
    fi
    
    if command -v iptables >/dev/null 2>&1; then
        if [ "$(iptables -L -n 2>/dev/null | wc -l)" -gt 8 ]; then
            if [ "$FIREWALL_DISABLED" = false ]; then
                printf "\n"
                box_start "$DIM$YELLOW"
                box_empty
                box_line "Custom iptables rules detected. Flushing rules..."
                box_line "StartTunnel will manage firewall rules."
                box_empty
                box_end
            fi
            
            iptables -P INPUT ACCEPT 2>/dev/null || true
            iptables -P FORWARD ACCEPT 2>/dev/null || true
            iptables -P OUTPUT ACCEPT 2>/dev/null || true
            iptables -F 2>/dev/null || true
            iptables -X 2>/dev/null || true
            FIREWALL_DISABLED=true
        fi
    fi
    
    if [ "$FIREWALL_DISABLED" = true ]; then
        printf "System firewall disabled\n"
    fi
}

check_service_status() {
    if systemctl is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
        SERVICE_WAS_RUNNING=true
    fi
    
    if systemctl is-enabled --quiet "$SERVICE_NAME" 2>/dev/null; then
        SERVICE_WAS_ENABLED=true
    fi
}

stop_service() {
    if [ "$SERVICE_WAS_RUNNING" = true ]; then
        if ! systemctl stop "$SERVICE_NAME" 2>/dev/null; then
            printf "%sWarning:%s Could not stop service gracefully\n" "$YELLOW$BOLD" "$RESET"
        fi
    fi
}

restart_service() {
    if [ "$SERVICE_WAS_RUNNING" = true ]; then
        systemctl daemon-reload 2>/dev/null || true
        
        if systemctl start "$SERVICE_NAME" 2>/dev/null; then
            sleep 2
            if systemctl is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
                SERVICE_IS_RUNNING=true
                printf "Service restarted successfully\n"
            else
                SERVICE_IS_RUNNING=false
                printf "\n%sWarning:%s Service restarted but may have issues.\n" "$YELLOW$BOLD" "$RESET"
                printf "         Check status: %ssystemctl status %s%s\n" "$DIM" "$SERVICE_NAME" "$RESET"
            fi
        else
            SERVICE_IS_RUNNING=false
            printf "\n%sWarning:%s Could not restart service.\n" "$YELLOW$BOLD" "$RESET"
            printf "         Manual start needed: %ssystemctl start %s%s\n" "$DIM" "$SERVICE_NAME" "$RESET"
        fi
    else
        # Service wasn't running before, try to start it anyway
        systemctl daemon-reload 2>/dev/null || true
        if systemctl start "$SERVICE_NAME" 2>/dev/null; then
            sleep 2
            if systemctl is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
                SERVICE_IS_RUNNING=true
                printf "Service started successfully\n"
            else
                SERVICE_IS_RUNNING=false
            fi
        else
            SERVICE_IS_RUNNING=false
        fi
    fi
    
    if [ "$SERVICE_WAS_ENABLED" = true ]; then
        if ! systemctl is-enabled --quiet "$SERVICE_NAME" 2>/dev/null; then
            systemctl enable "$SERVICE_NAME" 2>/dev/null || true
        fi
    fi
}

enable_and_start_service() {
    printf "Enabling and starting service...\n"
    
    systemctl daemon-reload 2>/dev/null || true
    
    # Enable service to start on boot
    if systemctl enable "$SERVICE_NAME" 2>/dev/null; then
        printf "Service enabled for auto-start on boot\n"
    else
        printf "%sWarning:%s Could not enable service\n" "$YELLOW$BOLD" "$RESET"
    fi
    
    # Start service now
    if systemctl start "$SERVICE_NAME" 2>/dev/null; then
        sleep 2
        if systemctl is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
            SERVICE_IS_RUNNING=true
            printf "Service started successfully\n"
        else
            SERVICE_IS_RUNNING=false
            printf "%sWarning:%s Service may not be running properly\n" "$YELLOW$BOLD" "$RESET"
            printf "         Check status: %ssystemctl status %s%s\n" "$DIM" "$SERVICE_NAME" "$RESET"
        fi
    else
        SERVICE_IS_RUNNING=false
        printf "%sWarning:%s Could not start service\n" "$YELLOW$BOLD" "$RESET"
        printf "         Manual start: %ssystemctl start %s%s\n" "$DIM" "$SERVICE_NAME" "$RESET"
    fi
}

display_web_info() {
    printf "\n"
    box_start "$DIM$BLUE"
    box_empty
    box_line "Displaying current web interface configuration..." "center"
    box_empty
    box_end
    printf "\n"
    
    if command -v start-tunnel >/dev/null 2>&1; then
        start-tunnel web init
    else
        printf "%sWarning:%s start-tunnel command not found\n" "$YELLOW$BOLD" "$RESET"
    fi
}

reconfigure_web_ui() {
    printf "\n"
    box_start "$DIM$BLUE"
    box_empty
    box_line "This will reset and reinitialize the web interface." "center"
    box_empty
    box_line "Options:"
    box_line "  [i] Display current web information"
    box_line "  [r] Reset and reconfigure web UI"
    box_line "  [n] Cancel"
    box_empty
    box_end
    printf "  %s>%s " "$BOLD" "$RESET"
    
    read -r WEB_CHOICE
    
    case "$WEB_CHOICE" in
        [iI])
            display_web_info
            ;;
        [rR])
            printf "\nResetting web interface...\n"
            if command -v start-tunnel >/dev/null 2>&1; then
                start-tunnel web reset 2>/dev/null || true
                printf "Initializing web interface...\n"
                start-tunnel web init
            else
                printf "%sWarning:%s start-tunnel command not found\n" "$YELLOW$BOLD" "$RESET"
            fi
            ;;
        *)
            printf "\n%sCancelled%s\n" "$DIM" "$RESET"
            ;;
    esac
}

check_existing_installation() {
    if command -v dpkg >/dev/null 2>&1 && dpkg -l 2>/dev/null | grep -q "^ii.*$PACKAGE_NAME_BASE" 2>/dev/null; then
        FRESH_INSTALL=false
        INSTALLED_VERSION=$(dpkg -s "$PACKAGE_NAME_BASE" 2>/dev/null | grep '^Version:' | awk '{print $2}')
        
        check_service_status
        
        printf "\n"
        box_start "$DIM$BLUE"
        box_empty
        box_line "StartTunnel $INSTALLED_VERSION is already installed." "center"
        if [ "$SERVICE_WAS_RUNNING" = true ]; then
            box_line "Service is currently running." "center"
        else
            box_line "Service is not running." "center"
        fi
        
        box_empty
        box_line "Options:"
        box_line "  [r] Reinstall package"
        box_line "  [c] Configure web UI"
        box_line "  [n] Cancel"
        box_empty
        box_end
        printf "  %s>%s " "$BOLD" "$RESET"
        
        read -r CHOICE
        
        case "$CHOICE" in
            [rR])
                REINSTALL_MODE=true
                stop_service
                ;;
            [cC])
                reconfigure_web_ui
                printf "\n"
                exit 0
                ;;
            *)
                printf "\n%sInstallation cancelled.%s\n\n" "$DIM" "$RESET"
                exit 0
                ;;
        esac
    fi
}

detect_architecture() {
    MACHINE_ARCH=$(uname -m)
    case "$MACHINE_ARCH" in
        x86_64) ARCH="x86_64"; DISPLAY_ARCH="Intel/AMD64";;
        aarch64) ARCH="aarch64"; DISPLAY_ARCH="ARM64";;
        riscv64) ARCH="riscv64"; DISPLAY_ARCH="RISC-V 64";;
        *) err "Unsupported architecture: $MACHINE_ARCH";;
    esac
}

download_package() {
    PACKAGE_NAME="${PACKAGE_PREFIX}_${ARCH}.deb"
    DOWNLOAD_URL="${BASE_URL}/${PACKAGE_NAME}"
    TEMP_DIR=$(mktemp -d)
    PACKAGE_PATH="${TEMP_DIR}/${PACKAGE_NAME}"

    printf "Downloading StartTunnel...\n"
    
    if command -v curl >/dev/null 2>&1; then
        printf "%s" "$DIM"
        if ! COLUMNS=65 curl --progress-bar -fL "$DOWNLOAD_URL" -o "$PACKAGE_PATH" 2>&1; then
            printf "%s" "$RESET"
            rm -rf "$TEMP_DIR"
            err "Failed to download package"
        fi
        printf "%s" "$RESET"
    elif command -v wget >/dev/null 2>&1; then
        if ! wget -q --show-progress --progress=bar:force "$DOWNLOAD_URL" -O "$PACKAGE_PATH" 2>&1 | grep -v "^$"; then
            rm -rf "$TEMP_DIR"
            err "Failed to download package"
        fi
    else
        rm -rf "$TEMP_DIR"
        err "Neither wget nor curl is available"
    fi
    printf "\n"
}

install_package() {
    if [ "$REINSTALL_MODE" = true ]; then
        printf "Reinstalling...\n"
    else
        printf "Installing...\n"
    fi
    
    apt-get update -qq 2>/dev/null || true
    
    if [ "$REINSTALL_MODE" = true ]; then
        if ! apt-get --reinstall install -y "$PACKAGE_PATH" >/dev/null 2>&1; then
            if ! dpkg -i "$PACKAGE_PATH" >/dev/null 2>&1; then
                apt-get install -f -y >/dev/null 2>&1
            fi
        fi
    else
        if ! apt install -y "$PACKAGE_PATH" >/dev/null 2>&1; then
            if ! dpkg -i "$PACKAGE_PATH" >/dev/null 2>&1; then
                apt-get install -f -y >/dev/null 2>&1
            fi
        fi
    fi
    
    rm -rf "$TEMP_DIR"
}

verify_installation() {
    if command -v start-tunnel >/dev/null 2>&1; then
        INSTALLED_VERSION=$(start-tunnel --version 2>/dev/null || echo "$VERSION")
    elif command -v dpkg >/dev/null 2>&1 && dpkg -l 2>/dev/null | grep -q start-tunnel; then
        INSTALLED_VERSION=$(dpkg -s "$PACKAGE_NAME_BASE" 2>/dev/null | grep '^Version:' | awk '{print $2}')
    else
        err "Installation verification failed"
    fi
}

configure_web_ui() {
    # Reload systemd daemon and check if service is running before attempting web UI configuration
    systemctl daemon-reload 2>/dev/null || true
    if ! systemctl is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
        printf "\n"
        box_start "$DIM$YELLOW"
        box_empty
        box_line "Service is not running. Web interface cannot be configured." "center" "$BOLD"
        box_empty
        box_line "Please start the service first:" "center"
        box_line "  systemctl start $SERVICE_NAME" "center" "$DIM"
        box_line "  systemctl status $SERVICE_NAME" "center" "$DIM"
        box_empty
        box_line "Then run: start-tunnel web init" "center"
        box_empty
        box_end
        printf "\n"
        return
    fi
    
    printf "\n"
    box_start "$DIM$BLUE"
    box_empty
    box_line "StartTunnel includes a web interface for easy management." "center"
    box_line "Would you like to initialize it now? (Recommended)" "center"
    box_empty
    box_line "[y] Yes, initialize web UI"
    box_line "[n] No, configure later"
    box_empty
    box_end
    printf "  %s>%s " "$BOLD" "$RESET"
    
    read -r WEB_RESPONSE
    
    case "$WEB_RESPONSE" in
        [yY]|[yY][eE][sS])
            printf "\n"
            
            # Reload systemd and verify service is still running before configuring
            systemctl daemon-reload 2>/dev/null || true
            if ! systemctl is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
                printf "%sError:%s Service is not running. Cannot configure web interface.\n" "$RED$BOLD" "$RESET"
                printf "         Please start the service: %ssystemctl start %s%s\n" "$DIM" "$SERVICE_NAME" "$RESET"
                printf "         Then run: %sstart-tunnel web init%s\n" "$DIM" "$RESET"
                return
            fi
            
            if [ "$REINSTALL_MODE" = true ]; then
                printf "Resetting web interface...\n"
                if command -v start-tunnel >/dev/null 2>&1; then
                    start-tunnel web reset 2>/dev/null || true
                fi
            fi
            
            printf "Initializing web interface...\n"
            
            if command -v start-tunnel >/dev/null 2>&1; then
                if start-tunnel web init; then
                    CONFIGURE_WEB_UI=true
                else
                    printf "%sWarning:%s Web interface initialization had issues\n" "$YELLOW$BOLD" "$RESET"
                    printf "         You can run: %sstart-tunnel web init%s\n" "$DIM" "$RESET"
                fi
            else
                printf "%sWarning:%s start-tunnel command not found\n" "$YELLOW$BOLD" "$RESET"
            fi
            ;;
        *)
            printf "\n%sSkipping web interface setup%s\n" "$DIM" "$RESET"
            printf "You can initialize it later with: %sstart-tunnel web init%s\n" "$DIM" "$RESET"
            ;;
    esac
}

main() {
    fix_stdin
    check_debian
    ascii_banner
    ensure_root
    check_existing_installation
    
    if [ "$FRESH_INSTALL" = true ]; then
        printf "Preparing system...\n"
    fi
    
    check_install_packages
    check_dns
    check_disable_firewall
    detect_architecture
    download_package
    install_package
    verify_installation

    if [ "$REINSTALL_MODE" = true ]; then
        restart_service
    else
        enable_and_start_service
    fi

    if [ "$FRESH_INSTALL" = true ] || [ "$REINSTALL_MODE" = true ]; then
        configure_web_ui
    fi

    printf "\n"
    box_start "$DIM$GREEN"
    box_empty
    box_line "Installation Complete" "center" "$GREEN$BOLD"
    if [ "$SERVICE_IS_RUNNING" = false ]; then
        box_empty
        box_line "Note: Service is not running. Please check:" "center" "$YELLOW"
        box_line "  systemctl status $SERVICE_NAME" "center" "$DIM"
    fi
    box_empty
    box_end
    printf "\n"
    # Close TTY redirection if it was opened
    exec 0<&- 2>/dev/null || true
}

main "$@"