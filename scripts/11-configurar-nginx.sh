#!/bin/bash

run_stage() {
    section "11/12 — Nginx"
    install_pkg nginx
    run_root systemctl enable --now nginx
    run_root setsebool -P httpd_can_network_connect 1
}
