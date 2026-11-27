#!/bin/bash

run_stage() {
    section "9/12 — IDEs"
    install_pkg code
    install_flatpak com.jetbrains.IntelliJ-IDEA-Community
    install_flatpak com.jetbrains.PyCharm-Community
}
