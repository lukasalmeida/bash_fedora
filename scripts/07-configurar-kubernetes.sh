#!/bin/bash

run_stage() {
    section "7/12 — kubectl"
    if [[ ! -f /etc/yum.repos.d/kubernetes.repo ]]; then
        run_root tee /etc/yum.repos.d/kubernetes.repo >/dev/null <<'EOF'
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.30/gpgkey
EOF
    fi
    install_pkg kubectl
}
