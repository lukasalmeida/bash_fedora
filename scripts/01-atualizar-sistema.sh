#!/bin/bash

run_stage() {
    section "1/12 — Sistema e repositórios"
    if compgen -G "/var/lib/dnf/offline/packages/*" >/dev/null; then
        warn "Transação offline do DNF pendente detectada; atualização do sistema ignorada para não invalidá-la."
    else
        run_root dnf update -y --quiet
    fi
    install_pkg dnf-plugins-core curl wget unzip zip tar make gcc gcc-c++ openssl openssl-devel fuse fuse-libs

    if ! rpm -q openssl3-libs >/dev/null 2>&1; then
        install_pkg openssl3-libs
    fi

    if [[ ! -f /etc/yum.repos.d/brave-browser-nightly.repo ]]; then
        run_root dnf config-manager addrepo --from-repofile=https://brave-browser-rpm-nightly.s3.brave.com/brave-browser-nightly.repo
    fi
    run_root rpm --import https://brave-browser-rpm-nightly.s3.brave.com/brave-core-nightly.asc
    run_root rpm --import https://packages.microsoft.com/keys/microsoft.asc

    if [[ ! -f /etc/yum.repos.d/vscode.repo ]]; then
        run_root tee /etc/yum.repos.d/vscode.repo >/dev/null <<'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
    fi

    if [[ ! -f /etc/yum.repos.d/docker-ce.repo ]]; then
        run_root dnf config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo
    fi

    install_pkg flatpak
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    ok "Sistema e repositórios processados"
}
