#!/bin/bash

# AI Coding Tools Installer
# Installs claude-code (Anthropic) and codex-cli (OpenAI)

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()  { echo -e "${BLUE}[AI Tools] $1${NC}"; }
log_ok()    { echo -e "${GREEN}[AI Tools] $1${NC}"; }
log_warn()  { echo -e "${YELLOW}[AI Tools] $1${NC}"; }
log_err()   { echo -e "${RED}[AI Tools] $1${NC}"; }

# ── Node.js prerequisite check ──────────────────────────────────────────────
check_node() {
    if ! command -v node >/dev/null 2>&1; then
        log_warn "Node.js not found. Attempting to install via NodeSource (LTS)..."
        if command -v apt-get >/dev/null 2>&1; then
            curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
            apt-get install -y nodejs
        elif command -v yum >/dev/null 2>&1; then
            curl -fsSL https://rpm.nodesource.com/setup_lts.x | bash -
            yum install -y nodejs
        elif command -v dnf >/dev/null 2>&1; then
            curl -fsSL https://rpm.nodesource.com/setup_lts.x | bash -
            dnf install -y nodejs
        else
            log_err "Unsupported package manager. Please install Node.js 18+ manually and re-run."
            return 1
        fi
    fi

    node_major=$(node --version | sed 's/v//' | cut -d. -f1)
    if [ "$node_major" -lt 18 ]; then
        log_err "Node.js 18+ is required (found $(node --version)). Please upgrade Node.js."
        return 1
    fi
    log_ok "Node.js $(node --version) detected."
}

# ── Install claude-code ──────────────────────────────────────────────────────
install_claude_code() {
    log_info "Installing claude-code (Anthropic Claude Code CLI)..."
    if command -v claude >/dev/null 2>&1; then
        log_warn "claude-code is already installed ($(claude --version 2>/dev/null || echo 'unknown version')). Skipping."
        return 0
    fi

    if npm install -g @anthropic-ai/claude-code 2>&1; then
        log_ok "claude-code installed successfully."
        log_info "Run 'claude' to get started. Authenticate with: claude config"
    else
        log_err "Failed to install claude-code via npm."
        return 1
    fi
}

# ── Install codex-cli ────────────────────────────────────────────────────────
install_codex_cli() {
    log_info "Installing codex-cli (OpenAI Codex CLI)..."
    if command -v codex >/dev/null 2>&1; then
        log_warn "codex-cli is already installed ($(codex --version 2>/dev/null || echo 'unknown version')). Skipping."
        return 0
    fi

    if npm install -g @openai/codex 2>&1; then
        log_ok "codex-cli installed successfully."
        log_info "Run 'codex' to get started. Set your API key: export OPENAI_API_KEY=<your-key>"
    else
        log_err "Failed to install codex-cli via npm."
        return 1
    fi
}

# ── Main ─────────────────────────────────────────────────────────────────────
install_ai_tools() {
    log_info "Starting AI coding tools installation..."
    check_node || { log_err "Node.js prerequisite check failed. Aborting AI tools installation."; return 1; }
    install_claude_code
    install_codex_cli
    log_ok "AI coding tools installation complete."
    log_info "  • claude-code: run 'claude' — docs: https://github.com/anthropics/claude-code"
    log_info "  • codex-cli:   run 'codex'  — docs: https://github.com/openai/codex"
}

install_ai_tools
