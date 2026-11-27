#!/bin/bash

run_stage() {
    section "15/15 — Configurar Kilo e OpenCode (prune)"
    NVM_DIR="$HOME_DIR/.nvm"
    export NVM_DIR

    # Configurar Kilo - desabilitar prune
    local kilo_config_dir="$HOME_DIR/.config/kilo"
    local kilo_config_file="$kilo_config_dir/kilo.jsonc"
    mkdir -p "$kilo_config_dir"

    if [[ ! -f "$kilo_config_file" ]]; then
        cat > "$kilo_config_file" <<'EOF'
{
  "$schema": "app.kilo.ai/config.json",
  "compaction": {
    "prune": false
  }
}
EOF
        ok "Configuração do Kilo criada com prune desabilitado"
    else
        if command -v jq >/dev/null 2>&1; then
            jq '.compaction.prune = false' "$kilo_config_file" > "$kilo_config_file.tmp" && mv "$kilo_config_file.tmp" "$kilo_config_file"
            ok "Configuração do Kilo 'compaction.prune: false' aplicada"
        else
            if ! grep -q '"prune"' "$kilo_config_file"; then
                warn "Configuração do Kilo existente detectada. Adicione manualmente em $kilo_config_file:"
                warn '  "compaction": { "prune": false }'
            fi
        fi
    fi

    # Configurar OpenCode - desabilitar prune
    local opencode_config_dir="$HOME_DIR/.config/opencode"
    local opencode_config_file="$opencode_config_dir/opencode.jsonc"
    mkdir -p "$opencode_config_dir"

    if [[ ! -f "$opencode_config_file" ]]; then
        cat > "$opencode_config_file" <<'EOF'
{
  "$schema": "opencode.ai/config.json",
  "compaction": {
    "prune": false
  }
}
EOF
        ok "Configuração do OpenCode criada com prune desabilitado"
    else
        if command -v jq >/dev/null 2>&1; then
            jq '.compaction.prune = false' "$opencode_config_file" > "$opencode_config_file.tmp" && mv "$opencode_config_file.tmp" "$opencode_config_file"
            ok "Configuração do OpenCode 'compaction.prune: false' aplicada"
        else
            if ! grep -q '"prune"' "$opencode_config_file"; then
                warn "Configuração do OpenCode existente detectada. Adicione manualmente em $opencode_config_file:"
                warn '  "compaction": { "prune": false }'
            fi
        fi
    fi
}