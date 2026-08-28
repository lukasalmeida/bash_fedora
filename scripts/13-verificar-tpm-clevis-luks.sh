#!/bin/bash

run_stage() {
    section "13/13 — Verificação de criptografia LUKS"

    local luks_devices=()
    local mapped_devices=()
    local device
    local mapping
    local clevis_bindings
    local has_tpm_binding=0

    while IFS= read -r device; do
        [[ -n "$device" ]] && luks_devices+=("$device")
    done < <(lsblk -pnro NAME,FSTYPE 2>/dev/null | awk '$2 == "crypto_LUKS" {print $1}')

    while IFS= read -r device; do
        [[ -n "$device" ]] && mapped_devices+=("$device")
    done < <(lsblk -pnro NAME,TYPE 2>/dev/null | awk '$2 == "crypt" {print $1}')

    if (( ${#luks_devices[@]} == 0 && ${#mapped_devices[@]} == 0 )); then
        info "Nenhuma partição LUKS ou unidade dm-crypt ativa detectada. Fluxo normal mantido."
        return 0
    fi

    ok "Criptografia LUKS detectada."
    for device in "${luks_devices[@]}"; do
        info "Partição criptografada: $device"
    done
    for mapping in "${mapped_devices[@]}"; do
        info "Mapeamento LUKS ativo: $mapping"
    done

    if ! command -v clevis >/dev/null 2>&1; then
        warn "Clevis não está instalado; não foi possível verificar o desbloqueio via TPM."
        info "Nenhuma configuração foi alterada."
        return 0
    fi

    for device in "${luks_devices[@]}"; do
        clevis_bindings="$(clevis luks list -d "$device" 2>/dev/null || true)"
        if [[ -n "${clevis_bindings//[[:space:]]/}" ]]; then
            ok "Binding Clevis encontrado em $device."
            if grep -Eiq '(^|[^[:alnum:]_])tpm2([^[:alnum:]_]|$)' <<< "$clevis_bindings"; then
                has_tpm_binding=1
            fi
        else
            info "Nenhum binding Clevis encontrado em $device."
        fi
    done

    if (( has_tpm_binding == 1 )); then
        ok "TPM2/Clevis configurado para desbloqueio automático."
    else
        warn "Não foi identificado binding TPM2/Clevis. Nenhuma configuração foi alterada."
    fi
}