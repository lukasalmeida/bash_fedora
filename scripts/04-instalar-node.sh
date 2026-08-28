#!/bin/bash

run_stage() {
    section "4/12 — Node.js via NVM"
    local nvm_version="v0.40.1"
    NVM_DIR="$HOME_DIR/.nvm"
    export NVM_DIR
    if [[ ! -d "$NVM_DIR" ]]; then
        curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/$nvm_version/install.sh" | bash
    else
        warn "NVM já existe, pulando"
    fi
    for rc_file in "$HOME_DIR/.zshrc" "$HOME_DIR/.bashrc"; do
        touch "$rc_file"
        grep -q NVM_DIR "$rc_file" 2>/dev/null || cat >> "$rc_file" <<'EOF'
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
EOF
    done
    bash -c 'source "$NVM_DIR/nvm.sh" && nvm install --lts && nvm alias default node'
    bash -c 'source "$NVM_DIR/nvm.sh" && npm install -g pnpm yarn typescript ts-node'
    ok "Node.js e ferramentas globais processados"
}
