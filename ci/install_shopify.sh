#!/bin/bash
# Shopify CLI Installer
# npm package: @shopify/cli

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()  { echo -e "${BLUE}[Shopify CLI] $1${NC}"; }
log_ok()    { echo -e "${GREEN}[Shopify CLI] $1${NC}"; }
log_warn()  { echo -e "${YELLOW}[Shopify CLI] $1${NC}"; }
log_err()   { echo -e "${RED}[Shopify CLI] $1${NC}"; }

check_node() {
    if ! command -v node >/dev/null 2>&1; then
        log_err "Node.js is required but not found. Please install Node.js 18+ first."
        return 1
    fi
    node_major=$(node --version | sed 's/v//' | cut -d. -f1)
    if [ "$node_major" -lt 18 ]; then
        log_err "Node.js 18+ required (found $(node --version))."
        return 1
    fi
    log_ok "Node.js $(node --version) detected."
}

install_shopify_cli() {
    log_info "Installing Shopify CLI..."

    if command -v shopify >/dev/null 2>&1; then
        log_warn "Shopify CLI already installed ($(shopify version 2>/dev/null || echo 'unknown')). Skipping."
        return 0
    fi

    if npm install -g @shopify/cli@latest; then
        log_ok "Shopify CLI installed successfully."
        log_info "  Run 'shopify' to get started."
        log_info "  Docs: https://shopify.dev/docs/api/shopify-cli"
        log_info "  GitHub: https://github.com/Shopify/cli"
    else
        log_err "Failed to install Shopify CLI."
        return 1
    fi
}

check_node && install_shopify_cli
