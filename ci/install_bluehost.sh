#!/bin/bash
# 1Panel Installer for Bluehost VMs
# Supports CentOS 7/8/Stream, AlmaLinux, Rocky Linux, Ubuntu 18.04/20.04/22.04/24.04
#
# Usage:
#   sudo bash install_bluehost.sh
#
# Environment variables:
#   PANEL_PORT   - 1Panel web port (default: 4000)

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PANEL_PORT="${PANEL_PORT:-4000}"

log_info()  { echo -e "${BLUE}[1Panel] $1${NC}"; }
log_ok()    { echo -e "${GREEN}[1Panel] $1${NC}"; }
log_warn()  { echo -e "${YELLOW}[1Panel] $1${NC}"; }
log_err()   { echo -e "${RED}[1Panel] $1${NC}"; exit 1; }

# ---------------------------------------------------------------------------
# 1. Root check
# ---------------------------------------------------------------------------
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        log_err "This script must be run as root. Try: sudo bash $0"
    fi
    log_ok "Running as root."
}

# ---------------------------------------------------------------------------
# 2. OS detection
# ---------------------------------------------------------------------------
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_ID="${ID}"
        OS_VERSION_ID="${VERSION_ID}"
    else
        log_err "Cannot detect OS. /etc/os-release not found."
    fi

    case "${OS_ID}" in
        ubuntu|debian)
            PKG_MGR="apt"
            ;;
        centos|rhel|almalinux|rocky|ol)
            PKG_MGR="yum"
            if command -v dnf >/dev/null 2>&1; then
                PKG_MGR="dnf"
            fi
            ;;
        *)
            log_err "Unsupported OS '${OS_ID}'. Bluehost VMs typically run CentOS 7/8, AlmaLinux, Rocky Linux, or Ubuntu."
            ;;
    esac

    log_ok "Detected OS: ${PRETTY_NAME:-${OS_ID} ${OS_VERSION_ID}} (package manager: ${PKG_MGR})"
}

# ---------------------------------------------------------------------------
# 3. System requirements
# ---------------------------------------------------------------------------
check_requirements() {
    # RAM: require at least 512 MB
    TOTAL_RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    TOTAL_RAM_MB=$((TOTAL_RAM_KB / 1024))
    if [ "${TOTAL_RAM_MB}" -lt 512 ]; then
        log_err "Insufficient RAM: ${TOTAL_RAM_MB} MB detected. 1Panel requires at least 512 MB."
    fi
    log_ok "RAM: ${TOTAL_RAM_MB} MB available."

    # Disk: require at least 1 GB free on /
    FREE_DISK_KB=$(df -k / | awk 'NR==2{print $4}')
    FREE_DISK_MB=$((FREE_DISK_KB / 1024))
    if [ "${FREE_DISK_MB}" -lt 1024 ]; then
        log_err "Insufficient disk space: ${FREE_DISK_MB} MB free on /. 1Panel requires at least 1 GB."
    fi
    log_ok "Free disk: ${FREE_DISK_MB} MB on /."
}

# ---------------------------------------------------------------------------
# 4. Prerequisites
# ---------------------------------------------------------------------------
install_prerequisites() {
    log_info "Installing prerequisites (curl, wget)..."
    if [ "${PKG_MGR}" = "apt" ]; then
        apt-get update -qq
        apt-get install -y curl wget
    else
        "${PKG_MGR}" install -y curl wget
    fi
    log_ok "Prerequisites installed."
}

# ---------------------------------------------------------------------------
# 5. Firewall — open the 1Panel port
# ---------------------------------------------------------------------------
_try_iptables() {
    if command -v iptables >/dev/null 2>&1; then
        # Use -L -n to list rules for more reliable port detection across systems
        if ! iptables -L INPUT -n | grep -qw "${PANEL_PORT}"; then
            iptables -I INPUT -p tcp --dport "${PANEL_PORT}" -j ACCEPT
            log_ok "iptables: port ${PANEL_PORT}/tcp opened."
            # Persist the rule if iptables-save is available
            if command -v iptables-save >/dev/null 2>&1; then
                if [ -d /etc/sysconfig ]; then
                    iptables-save > /etc/sysconfig/iptables
                elif [ -d /etc/iptables ]; then
                    iptables-save > /etc/iptables/rules.v4
                fi
            fi
        else
            log_warn "iptables: port ${PANEL_PORT}/tcp already open."
        fi
    else
        log_warn "No supported firewall found (firewalld / ufw / iptables). Ensure port ${PANEL_PORT}/tcp is open in your Bluehost control panel."
    fi
}

open_firewall_port() {
    log_info "Opening port ${PANEL_PORT}/tcp in the firewall..."

    if command -v firewall-cmd >/dev/null 2>&1; then
        if firewall-cmd --state >/dev/null 2>&1; then
            # firewalld active (CentOS 7+, RHEL, AlmaLinux, Rocky)
            if ! firewall-cmd --list-ports | grep -q "${PANEL_PORT}/tcp"; then
                firewall-cmd --permanent --add-port="${PANEL_PORT}/tcp"
                firewall-cmd --reload
                log_ok "firewalld: port ${PANEL_PORT}/tcp opened."
            else
                log_warn "firewalld: port ${PANEL_PORT}/tcp already open."
            fi
        else
            log_warn "firewalld is installed but not running. Skipping firewalld rule; falling back to iptables."
            _try_iptables
        fi
    elif command -v ufw >/dev/null 2>&1 && ufw status | grep -q "Status: active"; then
        # ufw (Ubuntu)
        ufw allow "${PANEL_PORT}/tcp"
        log_ok "ufw: port ${PANEL_PORT}/tcp allowed."
    else
        _try_iptables
    fi
}

# ---------------------------------------------------------------------------
# 6. Run the official 1Panel installer
# ---------------------------------------------------------------------------
run_1panel_installer() {
    log_info "Downloading the official 1Panel installer..."
    local installer_url="https://resource.1panel.pro/v2/quick_start.sh"
    local installer_tmp
    installer_tmp="$(mktemp /tmp/1panel_installer_XXXXXX.sh)"

    # Ensure the temp file is always removed on exit
    trap 'rm -f "${installer_tmp}"' EXIT

    if ! curl -sSL "${installer_url}" -o "${installer_tmp}"; then
        log_err "Failed to download the 1Panel installer from ${installer_url}"
    fi

    log_info "  Installer SHA256: $(sha256sum "${installer_tmp}" | awk '{print $1}')"
    log_info "Running the 1Panel installer (this may take a few minutes)..."

    bash "${installer_tmp}"
    log_ok "1Panel installer completed."
}

# ---------------------------------------------------------------------------
# 7. Post-install summary
# ---------------------------------------------------------------------------
print_summary() {
    echo ""
    log_ok "======================================================"
    log_ok "  1Panel installation on Bluehost VM is complete!"
    log_ok "======================================================"
    log_info "  Web UI:   http://<your-server-ip>:${PANEL_PORT}"
    log_info "  Retrieve your credentials with:"
    log_info "    sudo 1pctl user-info"
    log_info ""
    log_info "  Bluehost reminders:"
    log_info "  - Ensure port ${PANEL_PORT} is allowed in your Bluehost"
    log_info "    firewall / security group settings."
    log_info "  - If cPanel/WHM is installed, avoid port conflicts"
    log_info "    (cPanel uses 2082, 2083, 2086, 2087, 2095, 2096)."
    log_info "  - Manage 1Panel with: sudo 1pctl"
    log_info ""
    log_info "  Docs: https://1panel.pro/docs"
    log_ok "======================================================"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
    log_info "Starting 1Panel installation for Bluehost VM..."
    check_root
    detect_os
    check_requirements
    install_prerequisites
    open_firewall_port
    run_1panel_installer
    print_summary
}

main
