#!/bin/bash

run_stage() {
    section "3/12 — Git e SSH"
    install_pkg git
    git config --global init.defaultBranch main
    git config --global core.editor "code --wait"
    git config --global pull.rebase false
    git config --global core.autocrlf input

    local ssh_key="$HOME_DIR/.ssh/id_ed25519"
    mkdir -p "$HOME_DIR/.ssh"
    chmod 700 "$HOME_DIR/.ssh"
    if [[ ! -f "$ssh_key" ]]; then
        ssh-keygen -t ed25519 -C "seuemail@gmail.com" -f "$ssh_key" -N ""
        ok "Chave SSH gerada"
        cat "$ssh_key.pub"
    else
        warn "Chave SSH já existe, pulando"
    fi
}
