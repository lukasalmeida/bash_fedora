#!/bin/bash

run_stage() {
    section "14/15 — OpenCode, Kilo e GitHub Copilot CLI"
    NVM_DIR="$HOME_DIR/.nvm"
    export NVM_DIR
    if ! bash -c 'source "$NVM_DIR/nvm.sh" && command -v npm' >/dev/null 2>&1; then
        warn "npm não disponível, pulando OpenCode, Kilo e GitHub Copilot CLI"
        return 0
    fi
    if bash -c 'source "$NVM_DIR/nvm.sh" && command -v opencode' >/dev/null 2>&1; then
        warn "OpenCode já instalado, pulando"
    else
        bash -c 'source "$NVM_DIR/nvm.sh" && npm_config_ignore_scripts=false npm install -g @opencode/cli'
        ok "OpenCode instalado"
    fi
    if bash -c 'source "$NVM_DIR/nvm.sh" && command -v kilo' >/dev/null 2>&1; then
        warn "Kilo já instalado, pulando"
    else
        bash -c 'source "$NVM_DIR/nvm.sh" && npm install -g @kilocode/cli'
        ok "Kilo instalado"
    fi
    if bash -c 'source "$NVM_DIR/nvm.sh" && command -v copilot' >/dev/null 2>&1; then
        warn "GitHub Copilot CLI já instalado, pulando"
    else
        bash -c 'source "$NVM_DIR/nvm.sh" && npm_config_ignore_scripts=false npm install -g @github/copilot'
        ok "GitHub Copilot CLI instalado"
    fi
}