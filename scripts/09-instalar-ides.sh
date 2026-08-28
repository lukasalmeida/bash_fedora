#!/bin/bash

run_stage() {
    section "9/12 — IDEs"
    install_pkg code
    if ! install_pkg cursor; then
        warn "Cursor via repositório falhou; tentando AppImage"
        curl -Lo "$APPS_DIR/Cursor.AppImage" https://download.todesktop.com/230313mzl4w4u92/linux/appimage/x64
        chmod +x "$APPS_DIR/Cursor.AppImage"
    fi
    if [[ ! -f /usr/local/bin/jetbrains-toolbox ]]; then
        local toolbox_url toolbox_bin
        toolbox_url="$(curl -s 'https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release' | python3 -c 'import sys,json; print(json.load(sys.stdin)["TBA"][0]["downloads"]["linux"]["link"])')"
        curl -Lo /tmp/jetbrains-toolbox.tar.gz "$toolbox_url"
        tar -xzf /tmp/jetbrains-toolbox.tar.gz -C /tmp/
        toolbox_bin="$(find /tmp -name jetbrains-toolbox -type f 2>/dev/null | head -1)"
        run_root install -m 755 "$toolbox_bin" /usr/local/bin/jetbrains-toolbox
        rm -rf /tmp/jetbrains-toolbox*
    fi
    warn "Abra o Toolbox para instalar IntelliJ IDEA, PyCharm e DataGrip"
}
