#!/bin/bash

run_stage() {
    section "10/12 — Aplicativos"
    install_flatpak com.getpostman.Postman
    install_pkg qbittorrent
    install_flatpak com.jgraph.drawio.desktop
    install_flatpak com.valvesoftware.Steam
    install_flatpak com.discordapp.Discord
    install_pkg brave-browser-nightly
    install_pkg openh264 gstreamer1-plugin-openh264 mozilla-openh264
    install_pkg vlc || install_flatpak org.videolan.VLC
    install_flatpak com.spotify.Client
    install_flatpak com.obsproject.Studio
}
