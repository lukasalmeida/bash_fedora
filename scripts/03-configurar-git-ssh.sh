#!/bin/bash

run_stage() {
    section "3/12 — Git e SSH"
    install_pkg git
    git config --global init.defaultBranch main
    git config --global core.editor "code --wait"
    git config --global pull.rebase false
    git config --global core.autocrlf input

    local ssh_key="${SSH_KEY_PATH:-$HOME_DIR/.ssh/id_ed25519}"
    mkdir -p "$HOME_DIR/.ssh"
    chmod 700 "$HOME_DIR/.ssh"

    if [[ -f "$ssh_key" ]]; then
        info "Chave SSH já existente em $ssh_key. Geração pulada e chave atual mantida."
        return 0
    fi

    if [[ -z "${SSH_EMAIL:-}" ]]; then
        err "E-mail da chave SSH indisponível no preflight; geração da chave pulada."
        err "Gere a chave manualmente com: ssh-keygen -t ed25519 -C \"seuemail@exemplo.com\" -f $ssh_key"
        return 1
    fi

    ssh-keygen -t ed25519 -C "$SSH_EMAIL" -f "$ssh_key" -N ""
    ok "Chave SSH gerada com o e-mail coletado no preflight"
    cat "$ssh_key.pub"
}
