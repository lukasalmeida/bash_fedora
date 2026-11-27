#!/bin/bash

renovar_credencial_sudo() {
    while kill -0 "$$" 2>/dev/null; do
        sleep 60
        sudo -n true >/dev/null 2>&1 || exit 0
    done
}

run_stage() {
    if [[ $EUID -eq 0 ]]; then
        err "Não execute este script como root ou com sudo."
        err "Use: ./setup_fedora.sh ou bash setup_fedora.sh"
        return 1
    fi

    section "Preflight — validação e coleta de entradas"

    REAL_USER="$(whoami)"
    HOME_DIR="$HOME"
    APPS_DIR="$HOME/Applications"
    mkdir -p "$APPS_DIR"

    if ! sudo -v; then
        err "Seu usuário precisa ter permissão sudo."
        return 1
    fi
    ok "Credencial sudo validada para $REAL_USER e renovada automaticamente até o fim da execução"

    renovar_credencial_sudo &

    SSH_KEY_PATH="$HOME_DIR/.ssh/id_ed25519"
    SSH_EMAIL=""

    if [[ -f "$SSH_KEY_PATH" ]]; then
        info "Chave SSH existente detectada em $SSH_KEY_PATH. O e-mail não será solicitado e a chave atual será mantida."
    else
        while [[ -z "$SSH_EMAIL" ]]; do
            if ! read -r -p "E-mail para a chave SSH: " SSH_EMAIL; then
                break
            fi
            if [[ -z "$SSH_EMAIL" ]]; then
                warn "Informe um e-mail para continuar."
            fi
        done

        if [[ -z "$SSH_EMAIL" ]]; then
            err "E-mail da chave SSH não pôde ser coletado no preflight."
            err "A etapa de Git/SSH não vai gerar a chave; depois você pode rodar: ssh-keygen -t ed25519 -C \"seuemail@exemplo.com\" -f ~/.ssh/id_ed25519"
            return 1
        fi

        ok "E-mail coletado para a chave SSH: $SSH_EMAIL"
    fi

    ok "Pré-requisitos validados para $REAL_USER"
}
