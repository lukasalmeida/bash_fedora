#!/bin/bash

run_stage() {
    section "5/12 — Java, Python, PHP e Composer"
    install_pkg java-latest-openjdk java-latest-openjdk-devel maven
    local java_block='export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which javac))))
export PATH="$JAVA_HOME/bin:$PATH"'
    for rc_file in "$HOME_DIR/.zshrc" "$HOME_DIR/.bashrc"; do
        touch "$rc_file"
        grep -q JAVA_HOME "$rc_file" 2>/dev/null || printf '\n%s\n' "$java_block" >> "$rc_file"
    done

    install_pkg python3 python3-pip python3-devel
    for rc_file in "$HOME_DIR/.zshrc" "$HOME_DIR/.bashrc"; do
        touch "$rc_file"
        grep -q 'alias python=python3' "$rc_file" 2>/dev/null || printf '\nalias python=python3\nalias pip=pip3\n' >> "$rc_file"
    done

    install_pkg php php-cli php-fpm php-mbstring php-xml php-curl php-zip php-pdo php-pgsql
    if ! command -v composer >/dev/null 2>&1; then
        local expected actual
        expected="$(php -r 'copy("https://composer.github.io/installer.sig", "php://stdout");')"
        php -r "copy('https://getcomposer.org/installer', '/tmp/composer-setup.php');"
        actual="$(php -r "echo hash_file('sha384', '/tmp/composer-setup.php');")"
        if [[ "$expected" == "$actual" ]]; then
            run_root php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer --quiet
        else
            warn "Checksum do Composer inválido"
        fi
        rm -f /tmp/composer-setup.php
    else
        warn "Composer já instalado, pulando"
    fi
    ok "Linguagens processadas"
}
