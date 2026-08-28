#!/bin/bash

run_stage() {
    if [[ $EUID -eq 0 ]]; then
        err "Não execute este script como root ou com sudo."
        err "Use: ./setup_fedora.sh ou bash setup_fedora.sh"
        return 1
    fi

    if ! sudo -v; then
        err "Seu usuário precisa ter permissão sudo."
        return 1
    fi

    REAL_USER="$(whoami)"
    HOME_DIR="$HOME"
    APPS_DIR="$HOME/Applications"
    mkdir -p "$APPS_DIR"
    ok "Pré-requisitos validados para $REAL_USER"
}
