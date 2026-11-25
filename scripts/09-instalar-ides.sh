#!/bin/bash

run_stage() {
    section "9/12 — IDEs"
    install_pkg code
    if ! install_pkg cursor; then
        warn "Cursor via repositório falhou; tentando AppImage"
        curl -Lo "$APPS_DIR/Cursor.AppImage" https://download.todesktop.com/230313mzl4w4u92/linux/appimage/x64
        chmod +x "$APPS_DIR/Cursor.AppImage"
    fi
    install_flatpak com.jetbrains.IntelliJ-IDEA-Community
    install_flatpak com.jetbrains.PyCharm-Community
}
