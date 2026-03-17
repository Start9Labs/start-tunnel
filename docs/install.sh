#!/usr/bin/env sh
# start-tunnel installer for Debian 13 VPS systems
# Installs start-tunnel from the official Start9 Debian repository

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
        # Save original stdin to FD 3 before redirecting to /dev/tty
        # This allows ensure_root() to still read the script from the pipe
        exec 3<&0
        exec < /dev/tty
    fi
}

# Support only Debian 13, inform early if not and exit
check_debian() {
    if [ ! -f /etc/os-release ]; then
        printf "\n"
        box_start "$DIM$RED"
        box_empty
        box_line "StartTunnel requires Debian 13." center "$BOLD"
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
        box_line "StartTunnel installer supports ONLY Debian 13." center "$BOLD"
        box_empty
        box_line "Detected: $NAME" center
        box_line "Please run this script on Debian 13 VPS." center
        box_empty
        box_end
        printf "\n"
        exit 1
    fi
    if [ -n "${VERSION_ID:-}" ]; then
        DEBIAN_MAJOR=$(echo "$VERSION_ID" | cut -d. -f1)
    elif [ -f /etc/debian_version ]; then
        DEBIAN_MAJOR=$(cut -d. -f1 /etc/debian_version)
    else
        DEBIAN_MAJOR="unknown"
    fi
    if ! echo "$DEBIAN_MAJOR" | grep -qE '^[0-9]+$'; then
        printf "\n"
        box_start "$DIM$RED"
        box_empty
        box_line "Unable to detect Debian major version." center
        box_line "Please run this script on Debian 13 VPS." center
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
        box_line "Required: Debian 13" center
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
    box_line "optimized for reverse tunneling" "center" "$DIM"
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
        # Check if FD 3 exists (saved original stdin from fix_stdin)
        # or if we need to read from stdin (script was piped)
        if ( : <&3 ) 2>/dev/null; then
            # FD 3 exists: read from original pipe (saved before fix_stdin redirect)
            cat <&3 > "$TEMP_SCRIPT"
        elif [ ! -t 0 ] || [ "$0" = "sh" ] || [ "$0" = "bash" ]; then
            # No FD 3: read from current stdin (script was piped but fix_stdin wasn't called yet)
            cat - > "$TEMP_SCRIPT"
        else
            # Script is a file: copy it
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
PACKAGE_NAME="start-tunnel"
SERVICE_NAME="start-tunneld.service"

# Start9 apt repository
REPO_URL="https://start9-debs.nyc3.cdn.digitaloceanspaces.com"
KEYRING_PATH="/usr/share/keyrings/start9.gpg"
SOURCES_PATH="/etc/apt/sources.list.d/start9.list"

# GPG public key URL for the Start9 apt repository
START9_GPG_KEY_URL="https://raw.githubusercontent.com/Start9Labs/start-os/next/major/apt/start9.gpg"

REINSTALL_MODE=false
FRESH_INSTALL=true
INSTALLED_VERSION=""
SERVICE_WAS_RUNNING=false
SERVICE_WAS_ENABLED=false
SERVICE_IS_RUNNING=false

check_dependencies() {
    if ! command -v curl >/dev/null 2>&1; then
        printf "Installing curl...\n"
        apt-get update -qq 2>/dev/null || true
        if ! apt-get install -y curl >/dev/null 2>&1; then
            err "Failed to install curl"
        fi
    fi
}

check_dns() {
    if ! ping -c 1 -W 2 deb.debian.org >/dev/null 2>&1; then
        printf "\n"
        box_start "$DIM$YELLOW"
        box_empty
        box_line "Cannot resolve deb.debian.org. Checking connectivity..."
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
            if ! ping -c 1 -W 2 deb.debian.org >/dev/null 2>&1; then
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

setup_repository() {
    printf "%s•%s Configuring Start9 apt repository..." "$YELLOW" "$RESET"

    # Download and install GPG keyring
    if ! curl -fsSL "$START9_GPG_KEY_URL" -o "$KEYRING_PATH"; then
        printf "\n"
        err "Failed to download GPG key from $START9_GPG_KEY_URL"
    fi

    # Install sources list
    printf 'deb [arch=amd64,arm64,riscv64 signed-by=%s] %s stable main\n' \
        "$KEYRING_PATH" "$REPO_URL" > "$SOURCES_PATH"

    printf "\r%s✓%s Configuring Start9 apt repository...\n" "$GREEN" "$RESET"

    printf "%s•%s Updating package lists..." "$YELLOW" "$RESET"
    if ! apt-get update -qq >/dev/null 2>&1; then
        printf "\n"
        err "Failed to update package lists. Check network connectivity."
    fi
    printf "\r%s✓%s Updating package lists...\n" "$GREEN" "$RESET"
}

check_existing_installation() {
    # Get version info from apt
    POLICY=$(apt-cache policy "$PACKAGE_NAME" 2>/dev/null || true)
    VERSION=$(printf '%s' "$POLICY" | grep 'Candidate:' | awk '{print $2}')
    INSTALLED_VERSION=$(printf '%s' "$POLICY" | grep 'Installed:' | awk '{print $2}')

    if [ -z "$VERSION" ] || [ "$VERSION" = "(none)" ]; then
        err "Package $PACKAGE_NAME not found in repository."
    fi

    printf "%s✓%s Found version: %s%s%s\n" "$GREEN" "$RESET" "$BOLD" "$VERSION" "$RESET"

    if [ "$INSTALLED_VERSION" != "(none)" ] && [ -n "$INSTALLED_VERSION" ]; then
        FRESH_INSTALL=false

        check_service_status

        printf "\n"
        box_start "$DIM$BLUE"
        box_empty
        box_line "StartTunnel installed: $INSTALLED_VERSION" "center"
        if [ "$SERVICE_WAS_RUNNING" = true ]; then
            box_line "Service is currently running." "center"
        else
            box_line "Service is not running." "center"
        fi

        box_empty
        box_line "Install version $VERSION?"
        box_line "  [y] Yes"
        box_line "  [n] No"
        box_empty
        box_end

        while true; do
            printf "  %s>%s " "$BOLD" "$RESET"
            read -r CHOICE

            case "$CHOICE" in
                [yY])
                    REINSTALL_MODE=true
                    stop_service
                    break
                    ;;
                [nN])
                    printf "\n%sInstallation cancelled.%s\n\n" "$DIM" "$RESET"
                    exit 0
                    ;;
                *)
                    printf "  %sPlease enter 'y' or 'n'%s\n" "$DIM" "$RESET"
                    ;;
            esac
        done
    fi
}

install_package() {
    if [ "$REINSTALL_MODE" = true ]; then
        printf "Installing...\n"
        if ! DEBIAN_FRONTEND=noninteractive apt-get install -y --reinstall "$PACKAGE_NAME" >/dev/null 2>&1; then
            err "Failed to install $PACKAGE_NAME"
        fi
    else
        printf "Installing...\n"
        if ! DEBIAN_FRONTEND=noninteractive apt-get install -y "$PACKAGE_NAME" >/dev/null 2>&1; then
            err "Failed to install $PACKAGE_NAME"
        fi
    fi
}

verify_installation() {
    if ! dpkg -l "$PACKAGE_NAME" 2>/dev/null | grep -q "^ii"; then
        err "Installation verification failed"
    fi
    INSTALLED_VERSION=$(dpkg -s "$PACKAGE_NAME" 2>/dev/null | grep '^Version:' | awk '{print $2}')
}

main() {
    fix_stdin
    check_debian
    ascii_banner
    ensure_root

    check_dependencies
    check_dns
    setup_repository
    check_existing_installation

    if [ "$FRESH_INSTALL" = true ]; then
        printf "Preparing system...\n"
    fi
    check_disable_firewall
    install_package
    verify_installation

    if [ "$REINSTALL_MODE" = true ]; then
        restart_service

        # For reinstalls, automatically run web init if service is running
        if [ "$SERVICE_IS_RUNNING" = true ] && command -v start-tunnel >/dev/null 2>&1; then
            printf "\n"
            start-tunnel web init
            printf "\n"
        fi
    else
        enable_and_start_service

        # For fresh installs, show success message with instructions
        printf "\n"
        box_start "$DIM$GREEN"
        box_empty
        box_line "Installation Complete" "center" "$GREEN$BOLD"
        box_empty
        if [ "$SERVICE_IS_RUNNING" = false ]; then
            box_line "Note: Service is not running. Please check:" "center" "$YELLOW"
            box_line "  systemctl status $SERVICE_NAME" "center" "$DIM"
            box_empty
        fi
        box_line "To initialize the web interface, run:" "center"
        box_line "  start-tunnel web init" "center" "$BOLD"
        box_empty
        box_end
        printf "\n"
    fi

    # Close TTY redirection if it was opened
    exec 0<&- 2>/dev/null || true
}

main "$@"
