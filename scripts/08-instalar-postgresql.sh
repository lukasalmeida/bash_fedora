#!/bin/bash

run_stage() {
    section "8/12 — PostgreSQL e PGAdmin"
    install_pkg postgresql postgresql-server postgresql-contrib
    if sudo -u postgres psql -c '\l' >/dev/null 2>&1; then
        warn "PostgreSQL já configurado"
    else
        [[ -f /var/lib/pgsql/data/PG_VERSION ]] || {
            run_root mkdir -p /var/lib/pgsql/data
            run_root postgresql-setup --initdb --unit postgresql
        }
        run_root systemctl enable --now postgresql
    fi
    install_flatpak org.pgadmin.pgadmin4
}
