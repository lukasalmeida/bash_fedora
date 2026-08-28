#!/bin/bash

run_stage() {
    section "1/12 — Sistema e repositórios"
    run_root dnf update -y --quiet
    install_pkg dnf-plugins-core curl wget unzip zip tar make gcc gcc-c++ openssl openssl-devel fuse fuse-libs

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

    if [[ ! -f /etc/yum.repos.d/cursor.repo ]]; then
        run_root tee /etc/yum.repos.d/cursor.repo >/dev/null <<'EOF'
[cursor]
name=Cursor
baseurl=https://download.todesktop.com/230313mzl4w4u92/rpm
enabled=1
gpgcheck=0
EOF
    fi

    if [[ ! -f /etc/yum.repos.d/docker-ce.repo ]]; then
        run_root dnf config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo
    fi

    install_pkg flatpak
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    ok "Sistema e repositórios processados"
}
