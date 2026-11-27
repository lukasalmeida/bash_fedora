#!/bin/bash

# O orquestrador continua mesmo quando uma etapa retorna erro.
set +e
set -o pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

VERSION='1.1.0'

echo -e "${BOLD}Fedora Setup v${VERSION}${NC}"

section() { echo -e "\n${PURPLE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; echo -e "${PURPLE}${BOLD}  $1${NC}"; echo -e "${PURPLE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; }
ok() { echo -e "  ${GREEN}✔  $1${NC}"; }
info() { echo -e "  ${CYAN}→  $1${NC}"; }
warn() { echo -e "  ${YELLOW}⚠  $1${NC}"; }
err() { echo -e "  ${RED}✘  $1${NC}"; }

run_root() { sudo "$@"; }
install_pkg() { sudo dnf install -y --quiet "$@"; }
install_flatpak() { flatpak install -y flathub "$1"; }

FAILED_STAGES=0
FAILED_COMMANDS=0
MANUAL_DNF_COMMAND=""

trap 'FAILED_COMMANDS=$((FAILED_COMMANDS + 1)); warn "Falha na linha $LINENO. Continuando."' ERR

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
MODULE_DIR="$SCRIPT_DIR/scripts"

if [[ ! -d "$MODULE_DIR" ]]; then
    err "Diretório de etapas não encontrado: $MODULE_DIR"
    exit 1
fi

for module in "$MODULE_DIR"/*.sh; do
    [[ -f "$module" ]] || continue
    unset -f run_stage 2>/dev/null
    if ! source "$module"; then
        FAILED_STAGES=$((FAILED_STAGES + 1))
        warn "Não foi possível carregar $(basename "$module"). Continuando."
        continue
    fi
    if ! declare -F run_stage >/dev/null; then
        FAILED_STAGES=$((FAILED_STAGES + 1))
        warn "$(basename "$module") não define run_stage. Continuando."
        continue
    fi
    info "Executando $(basename "$module")"
    if ! run_stage; then
        FAILED_STAGES=$((FAILED_STAGES + 1))
        warn "Etapa $(basename "$module") falhou. Continuando para a próxima."
    fi
done

section "Resumo"
if [[ -n "$MANUAL_DNF_COMMAND" ]]; then
    warn "Ação manual necessária:"
    info "Execute o seguinte comando para concluir a transação offline do DNF:"
    echo -e "  ${BOLD}$MANUAL_DNF_COMMAND${NC}"
    echo
fi
if (( FAILED_STAGES == 0 && FAILED_COMMANDS == 0 )); then
    ok "Todas as etapas foram executadas sem falhas detectadas."
else
    warn "$FAILED_STAGES etapa(s) falharam e $FAILED_COMMANDS comando(s) falharam."
    warn "As etapas seguintes foram executadas; revise as mensagens acima."
fi
ok "Configuração finalizada"
