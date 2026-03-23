#!/bin/bash
# Odoo Installer
# Supports: Docker (default) or native deb/rpm package install

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ODOO_VERSION="${ODOO_VERSION:-17}"
ODOO_PORT="${ODOO_PORT:-8069}"
DB_PASSWORD="${ODOO_DB_PASSWORD:-$(tr -dc A-Za-z0-9 </dev/urandom | head -c 16)}"
INSTALL_DIR="${ODOO_INSTALL_DIR:-/opt/odoo}"

log_info()  { echo -e "${BLUE}[Odoo] $1${NC}"; }
log_ok()    { echo -e "${GREEN}[Odoo] $1${NC}"; }
log_warn()  { echo -e "${YELLOW}[Odoo] $1${NC}"; }
log_err()   { echo -e "${RED}[Odoo] $1${NC}"; }

check_docker() {
    if ! command -v docker >/dev/null 2>&1; then
        log_err "Docker is not installed. Please install Docker first (the 1Panel installer handles this)."
        return 1
    fi
    log_ok "Docker detected: $(docker --version)"
}

install_odoo_docker() {
    log_info "Installing Odoo ${ODOO_VERSION} via Docker..."

    if docker ps -a --format '{{.Names}}' | grep -q '^odoo$'; then
        log_warn "Odoo container already exists. Skipping."
        return 0
    fi

    # Create data directories
    mkdir -p "${INSTALL_DIR}/data" "${INSTALL_DIR}/config" "${INSTALL_DIR}/addons"

    # Persist credentials to a restricted file
    CREDENTIALS_FILE="${INSTALL_DIR}/credentials.txt"
    if [ ! -f "${CREDENTIALS_FILE}" ]; then
        install -m 600 /dev/null "${CREDENTIALS_FILE}"
        {
            echo "Odoo DB User: odoo"
            echo "Odoo DB Password: ${DB_PASSWORD}"
        } > "${CREDENTIALS_FILE}"
        log_info "  Credentials saved to: ${CREDENTIALS_FILE}"
    fi

    # Create a dedicated Docker network for Odoo
    if ! docker network ls --format '{{.Name}}' | grep -q '^odoo-net$'; then
        log_info "Creating Docker network 'odoo-net'..."
        docker network create odoo-net
    fi

    # Start PostgreSQL container for Odoo
    if ! docker ps -a --format '{{.Names}}' | grep -q '^odoo-db$'; then
        log_info "Starting PostgreSQL container for Odoo..."
        docker run -d \
            --name odoo-db \
            --restart unless-stopped \
            --network odoo-net \
            -e POSTGRES_DB=postgres \
            -e POSTGRES_PASSWORD="${DB_PASSWORD}" \
            -e POSTGRES_USER=odoo \
            -v "${INSTALL_DIR}/db:/var/lib/postgresql/data" \
            postgres:15
        sleep 5
    else
        log_warn "odoo-db container already exists, reusing."
        # Ensure it is on the odoo-net network
        docker network connect odoo-net odoo-db 2>/dev/null || true
    fi

    # Start Odoo container
    log_info "Starting Odoo ${ODOO_VERSION} container on port ${ODOO_PORT}..."
    docker run -d \
        --name odoo \
        --restart unless-stopped \
        --network odoo-net \
        -p "${ODOO_PORT}:8069" \
        -e HOST=odoo-db \
        -e USER=odoo \
        -e PASSWORD="${DB_PASSWORD}" \
        -v "${INSTALL_DIR}/data:/var/lib/odoo" \
        -v "${INSTALL_DIR}/config:/etc/odoo" \
        -v "${INSTALL_DIR}/addons:/mnt/extra-addons" \
        "odoo:${ODOO_VERSION}"

    log_ok "Odoo ${ODOO_VERSION} installed and running."
    log_info "  Access Odoo at: http://localhost:${ODOO_PORT}"
    log_info "  DB User: odoo | DB Password: ${DB_PASSWORD}"
    log_info "  Data directory: ${INSTALL_DIR}"
    log_info "  Docs: https://hub.docker.com/_/odoo"
}

install_odoo_package() {
    log_info "Installing Odoo ${ODOO_VERSION} via system package..."

    if command -v odoo >/dev/null 2>&1; then
        log_warn "Odoo is already installed. Skipping."
        return 0
    fi

    if command -v apt-get >/dev/null 2>&1; then
        # Debian/Ubuntu
        apt-get install -y wget gnupg
        wget -q -O - https://nightly.odoo.com/odoo.key | gpg --dearmor -o /usr/share/keyrings/odoo-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/odoo-archive-keyring.gpg] https://nightly.odoo.com/${ODOO_VERSION}.0/nightly/deb/ ./" \
            > /etc/apt/sources.list.d/odoo.list
        apt-get update && apt-get install -y odoo
        systemctl enable odoo
        systemctl start odoo
    elif command -v dnf >/dev/null 2>&1; then
        # Fedora/RHEL/CentOS
        dnf config-manager --add-repo="https://nightly.odoo.com/${ODOO_VERSION}.0/nightly/rpm/odoo.repo"
        dnf install -y odoo
        systemctl enable odoo
        systemctl start odoo
    elif command -v yum >/dev/null 2>&1; then
        yum-config-manager --add-repo="https://nightly.odoo.com/${ODOO_VERSION}.0/nightly/rpm/odoo.repo"
        yum install -y odoo
        systemctl enable odoo
        systemctl start odoo
    else
        log_err "Unsupported package manager. Use INSTALL_MODE=docker."
        return 1
    fi

    log_ok "Odoo ${ODOO_VERSION} installed via system package."
    log_info "  Access Odoo at: http://localhost:8069"
}

main() {
    log_info "Starting Odoo installation (version ${ODOO_VERSION})..."
    INSTALL_MODE="${INSTALL_MODE:-docker}"

    if [ "$INSTALL_MODE" = "docker" ]; then
        check_docker && install_odoo_docker
    else
        install_odoo_package
    fi
}

main
