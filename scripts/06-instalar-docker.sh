#!/bin/bash

run_stage() {
    section "6/12 — Docker Desktop"
    install_pkg pass gnome-terminal
    if rpm -q docker-desktop >/dev/null 2>&1; then
        warn "Docker Desktop já instalado, pulando"
    else
        curl -Lo /tmp/docker-desktop.rpm https://desktop.docker.com/linux/main/amd64/docker-desktop-x86_64.rpm
        install_pkg /tmp/docker-desktop.rpm
        rm -f /tmp/docker-desktop.rpm
    fi
    run_root groupadd -f docker
    run_root usermod -aG docker "$REAL_USER"
    warn "Faça logout/login para aplicar o grupo docker"
}
