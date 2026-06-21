#!/bin/bash

# ╔══════════════════════════════════════════════════╗
# ║         SETUP FEDORA LINUX - Lucas               ║
# ║  Execute: ./setup-fedora.sh  ou  bash setup-fedora.sh ║
# ╚══════════════════════════════════════════════════╝

set -eo pipefail

# ─── Cores ────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

# ─── Funções de log ───────────────────────────────
section() { echo -e "\n${PURPLE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; echo -e "${PURPLE}${BOLD}  $1${NC}"; echo -e "${PURPLE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; }
ok()      { echo -e "  ${GREEN}✔  $1${NC}"; }
info()    { echo -e "  ${CYAN}→  $1${NC}"; }
warn()    { echo -e "  ${YELLOW}⚠  $1${NC}"; }
err()     { echo -e "  ${RED}✘  $1${NC}"; }

trap 'err "Erro na linha $LINENO. Abortando."; exit 1' ERR

# ─── Verificação: não pode ser root ───────────────
if [[ $EUID -eq 0 ]]; then
    err "Não execute este script como root ou com sudo."
    err "Use: ./setup-fedora.sh  ou  bash setup-fedora.sh"
    exit 1
fi

# ─── Verificação: usuário precisa ter permissão sudo ──
if ! sudo -v; then
    err "Seu usuário precisa ter permissão sudo."
    exit 1
fi

# ─── Funções auxiliares ───────────────────────────
run_root() {
    sudo "$@"
}

install_pkg() {
    sudo dnf install -y --quiet "$@"
}

install_flatpak() {
    flatpak install -y flathub "$1"
}

# ─── Usuário e diretórios ──────────────────────────
REAL_USER="$(whoami)"
HOME_DIR="$HOME"

# Pasta para AppImages
APPS_DIR="$HOME/Applications"
mkdir -p "$APPS_DIR"

echo -e "\n${BOLD}${CYAN}  Usuário: $REAL_USER${NC}"
echo -e "${BOLD}${CYAN}  Home:    $HOME_DIR${NC}"
echo -e "${BOLD}${CYAN}  Apps:    $APPS_DIR${NC}\n"


# ════════════════════════════════════════════════════
# 1. SISTEMA + REPOSITÓRIOS
# ════════════════════════════════════════════════════
section "1/16 — Sistema + Repositórios"

run_root dnf update -y --quiet
install_pkg \
dnf-plugins-core curl wget unzip zip tar \
make gcc gcc-c++ openssl openssl-devel \
fuse fuse-libs                           # necessário para AppImages
ok "Sistema atualizado!"

# ── Brave Browser Nightly ──────────────────────────
info "Brave Browser Nightly..."
if [ ! -f /etc/yum.repos.d/brave-browser-nightly.repo ]; then
    run_root dnf config-manager addrepo \
    --from-repofile=https://brave-browser-rpm-nightly.s3.brave.com/brave-browser-nightly.repo
fi
run_root rpm --import https://brave-browser-rpm-nightly.s3.brave.com/brave-core-nightly.asc

# ── VS Code ───────────────────────────────────────
info "VS Code..."
run_root rpm --import https://packages.microsoft.com/keys/microsoft.asc
if [ ! -f /etc/yum.repos.d/vscode.repo ]; then
    run_root tee /etc/yum.repos.d/vscode.repo > /dev/null << 'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
fi

# ── Cursor ────────────────────────────────────────
info "Cursor..."
if [ ! -f /etc/yum.repos.d/cursor.repo ]; then
    run_root tee /etc/yum.repos.d/cursor.repo > /dev/null << 'EOF'
[cursor]
name=Cursor
baseurl=https://download.todesktop.com/230313mzl4w4u92/rpm
enabled=1
gpgcheck=0
EOF
fi

# ── Docker ────────────────────────────────────────
info "Docker..."
if [ ! -f /etc/yum.repos.d/docker-ce.repo ]; then
    run_root dnf config-manager addrepo \
    --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo
fi

# ── Flathub ───────────────────────────────────────
info "Flathub..."
install_pkg flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

ok "Todos os repositórios configurados!"


# ════════════════════════════════════════════════════
# 2. FERRAMENTAS DE TERMINAL
# ════════════════════════════════════════════════════
section "2/16 — Ferramentas de terminal"

PACKAGES="zsh htop tree fzf bat ripgrep jq"

if dnf info fastfetch >/dev/null 2>&1; then
    PACKAGES="$PACKAGES fastfetch"
else
    PACKAGES="$PACKAGES neofetch"
fi

install_pkg $PACKAGES

ok "Ferramentas de terminal instaladas"

# ── Oh My Zsh ─────────────────────────────────────
if [ ! -d "$HOME_DIR/.oh-my-zsh" ]; then
    info "Instalando Oh My Zsh..."
    sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    ok "Oh My Zsh instalado!"
else
    warn "Oh My Zsh já existe, pulando..."
fi

run_root chsh -s "$(which zsh)" "$REAL_USER"
ok "Shell padrão → ZSH"


# ════════════════════════════════════════════════════
# 3. GIT + SSH
# ════════════════════════════════════════════════════
section "3/16 — Git + SSH"

install_pkg git

git config --global init.defaultBranch main
git config --global core.editor "code --wait"
git config --global pull.rebase false
git config --global core.autocrlf input
ok "Git configurado!"

SSH_KEY="$HOME_DIR/.ssh/id_ed25519"
mkdir -p ~/.ssh
chmod 700 ~/.ssh

if [ ! -f "$SSH_KEY" ]; then
    # ─── EDITE SEU EMAIL AQUI ───────────────────────
    SSH_EMAIL="seuemail@gmail.com"
    # ───────────────────────────────────────────────
    ssh-keygen -t ed25519 -C "$SSH_EMAIL" -f "$SSH_KEY" -N ""
    ok "Chave SSH gerada!"
    echo ""
    warn "Adicione esta chave no GitHub → Settings → SSH Keys:"
    echo -e "${CYAN}"
    cat "$SSH_KEY.pub"
    echo -e "${NC}"
else
    warn "Chave SSH já existe, pulando..."
fi


# ════════════════════════════════════════════════════
# 4. NODE.JS via NVM
# ════════════════════════════════════════════════════
section "4/16 — Node.js via NVM"

NVM_VERSION="v0.40.1"
NVM_DIR="$HOME_DIR/.nvm"

if [ ! -d "$NVM_DIR" ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh | bash
    ok "NVM $NVM_VERSION instalado!"
else
    warn "NVM já existe, pulando..."
fi

NVM_BLOCK='
# NVM - Node Version Manager
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"'

for RC in "$HOME_DIR/.zshrc" "$HOME_DIR/.bashrc"; do
  touch "$RC"
  if ! grep -q "NVM_DIR" "$RC" 2>/dev/null; then
    echo "$NVM_BLOCK" >> "$RC"
  fi
done

bash -c \
  "source $NVM_DIR/nvm.sh && nvm install --lts && nvm use --lts && nvm alias default node"
ok "Node.js LTS instalado!"

bash -c \
  "source $NVM_DIR/nvm.sh && npm install -g pnpm yarn typescript ts-node"
ok "Globais: pnpm, yarn, typescript, ts-node"


# ════════════════════════════════════════════════════
# 5. Java Latest OpenJDK + Maven
# ════════════════════════════════════════════════════
section "5/16 — Java Latest OpenJDK + Maven"

install_pkg java-latest-openjdk java-latest-openjdk-devel maven
ok "Java (OpenJDK) + Maven instalados!"

JAVA_BLOCK='
# Java
export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which javac))))
export PATH="$JAVA_HOME/bin:$PATH"'

for RC in "$HOME_DIR/.zshrc" "$HOME_DIR/.bashrc"; do
    touch "$RC"
    if ! grep -q "JAVA_HOME" "$RC" 2>/dev/null; then
        echo "$JAVA_BLOCK" >> "$RC"
    fi
done
ok "JAVA_HOME configurado!"


# ════════════════════════════════════════════════════
# 6. PYTHON 3
# ════════════════════════════════════════════════════
section "6/16 — Python 3"

install_pkg python3 python3-pip python3-devel
ok "Python 3 instalado!"

PYTHON_BLOCK='
# Python
alias python=python3
alias pip=pip3'

for RC in "$HOME_DIR/.zshrc" "$HOME_DIR/.bashrc"; do
    touch "$RC"
    if ! grep -q "alias python=python3" "$RC" 2>/dev/null; then
        echo "$PYTHON_BLOCK" >> "$RC"
    fi
done


# ════════════════════════════════════════════════════
# 7. PHP + COMPOSER
# ════════════════════════════════════════════════════
section "7/16 — PHP + Composer"

install_pkg \
php php-cli php-fpm php-mbstring \
php-xml php-curl php-zip php-pdo php-pgsql
ok "PHP instalado!"

if command -v composer >/dev/null 2>&1; then
    warn "Composer já instalado, pulando..."
else
    info "Instalando Composer..."
    EXPECTED_CS="$(php -r 'copy("https://composer.github.io/installer.sig", "php://stdout");')"
    php -r "copy('https://getcomposer.org/installer', '/tmp/composer-setup.php');"
    ACTUAL_CS="$(php -r "echo hash_file('sha384', '/tmp/composer-setup.php');")"

    if [ "$EXPECTED_CS" = "$ACTUAL_CS" ]; then
        run_root php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer --quiet
        rm -f /tmp/composer-setup.php
        ok "Composer instalado!"
    else
        warn "Falha no checksum — instale o Composer manualmente depois."
        rm -f /tmp/composer-setup.php
    fi
fi


# ════════════════════════════════════════════════════
# 8. DOCKER DESKTOP
# ════════════════════════════════════════════════════
section "8/16 — Docker Desktop"

# Dependências do Docker Desktop
install_pkg pass gnome-terminal
ok "Dependências instaladas (pass, gnome-terminal)"

if rpm -q docker-desktop >/dev/null 2>&1; then
    warn "Docker Desktop já instalado, pulando..."
else
    info "Baixando Docker Desktop (RPM)..."
    curl -Lo /tmp/docker-desktop.rpm \
    "https://desktop.docker.com/linux/main/amd64/docker-desktop-x86_64.rpm"
    install_pkg /tmp/docker-desktop.rpm
    rm -f /tmp/docker-desktop.rpm
    ok "Docker Desktop instalado!"
fi

run_root groupadd -f docker
run_root usermod -aG docker "$USER"
ok "Usuário adicionado ao grupo docker!"
warn "Abra o Docker Desktop uma vez para completar a configuração inicial"
warn "Faça logout/login para que a associação ao grupo docker tenha efeito"


# ════════════════════════════════════════════════════
# 9. KUBECTL
# ════════════════════════════════════════════════════
section "9/16 — kubectl"

if [ ! -f /etc/yum.repos.d/kubernetes.repo ]; then
    run_root tee /etc/yum.repos.d/kubernetes.repo > /dev/null << 'EOF'
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.30/gpgkey
EOF
fi

if install_pkg kubectl; then
    ok "kubectl instalado!"
else
    warn "Falha ao instalar kubectl. Continuando..."
fi


# ════════════════════════════════════════════════════
# 10. POSTGRESQL
# ════════════════════════════════════════════════════
section "10/16 — PostgreSQL"

install_pkg postgresql postgresql-server postgresql-contrib

if [ ! -f /var/lib/pgsql/data/PG_VERSION ]; then
    run_root postgresql-setup --initdb --unit postgresql
fi

run_root systemctl enable --now postgresql >/dev/null 2>&1
ok "PostgreSQL instalado e iniciado!"
info "Acesse com: sudo -u postgres psql"


# ════════════════════════════════════════════════════
# 10.1 PGADMIN 4
# ════════════════════════════════════════════════════
section "10.1 — PGAdmin 4"

info "Instalando PGAdmin 4..."

install_flatpak org.pgadmin.pgadmin4
ok "PGAdmin 4 instalado!"


# ════════════════════════════════════════════════════
# 11. IDEs
# ════════════════════════════════════════════════════
section "11/16 — IDEs"

# ── VS Code ───────────────────────────────────────
info "Instalando VS Code..."
install_pkg code
ok "VS Code instalado!"

# ── Cursor ────────────────────────────────────────
info "Instalando Cursor..."
install_pkg cursor || {
    warn "Falha via repo — tentando via AppImage..."
    curl -Lo "$APPS_DIR/Cursor.AppImage" \
    "https://download.todesktop.com/230313mzl4w4u92/linux/appimage/x64"
    chmod +x "$APPS_DIR/Cursor.AppImage"
    ok "Cursor instalado como AppImage em ~/Applications/"
}

# ── JetBrains Toolbox → IntelliJ, PyCharm, DataGrip ──
info "Instalando JetBrains Toolbox..."
if [ -f /usr/local/bin/jetbrains-toolbox ]; then
    warn "JetBrains Toolbox já instalado, pulando..."
else
    TOOLBOX_URL=$(curl -s \
        "https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release" \
        | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(data['TBA'][0]['downloads']['linux']['link'])
")

    curl -Lo /tmp/jetbrains-toolbox.tar.gz "$TOOLBOX_URL"
    tar -xzf /tmp/jetbrains-toolbox.tar.gz -C /tmp/
    TOOLBOX_BIN=$(find /tmp -name "jetbrains-toolbox" -type f 2>/dev/null | head -1)
    run_root install -m 755 "$TOOLBOX_BIN" /usr/local/bin/jetbrains-toolbox

    rm -rf /tmp/jetbrains-toolbox*
    ok "JetBrains Toolbox instalado em /usr/local/bin/"
fi
warn "Abra o Toolbox e instale manualmente: IntelliJ IDEA, PyCharm e DataGrip"


# ════════════════════════════════════════════════════
# 12. FERRAMENTAS DE DESENVOLVIMENTO
# ════════════════════════════════════════════════════
section "12/16 — Ferramentas de Desenvolvimento"

# ── Postman ───────────────────────────────────────
info "Instalando Postman..."
install_flatpak com.getpostman.Postman
ok "Postman instalado!"

# ── DataGrip ─────────────────────────────────────
info "Instalando DataGrip (Flatpak — alternativa ao Toolbox)..."
install_flatpak com.jetbrains.DataGrip
ok "DataGrip instalado!"

# ── FreeDownloadManager ───────────────────────────
info "Instalando FreeDownloadManager (AppImage)..."
FDM_URL="https://download3.freedownloadmanager.org/latest/freedownloadmanager.x86_64.AppImage"
curl -Lo "$APPS_DIR/FreeDownloadManager.AppImage" "$FDM_URL"
chmod +x "$APPS_DIR/FreeDownloadManager.AppImage"
ok "FreeDownloadManager instalado em ~/Applications/"

# Criar .desktop para integração com o menu do sistema
run_root tee "/usr/share/applications/freedownloadmanager.desktop" > /dev/null << EOF
[Desktop Entry]
Name=Free Download Manager
Exec=$APPS_DIR/FreeDownloadManager.AppImage
Icon=browser-download
Type=Application
Categories=Network;FileTransfer;
EOF
ok "Ícone do FDM adicionado ao menu!"

# ── qBittorrent ───────────────────────────────────
info "Instalando qBittorrent..."
install_pkg qbittorrent
ok "qBittorrent instalado!"

# ── Draw.io ───────────────────────────────────────
info "Instalando Draw.io..."
install_flatpak com.jgraph.drawio.desktop
ok "Draw.io instalado!"

# ── Steam ─────────────────────────────────────────
info "Instalando Steam..."
install_flatpak com.valvesoftware.Steam
ok "Steam instalado!"


# ════════════════════════════════════════════════════
# 13. COMUNICAÇÃO
# ════════════════════════════════════════════════════
section "13/16 — Comunicação"

info "Instalando Discord..."
install_flatpak com.discordapp.Discord || true
ok "Discord instalado!"


# ════════════════════════════════════════════════════
# 14. NAVEGADORES
# ════════════════════════════════════════════════════
section "14/16 — Navegadores"

info "Instalando Brave Browser Nightly..."
install_pkg brave-browser-nightly
ok "Brave Browser Nightly instalado!"
ok "Firefox já vem pré-instalado no Fedora"


# ════════════════════════════════════════════════════
# 15. MULTIMÍDIA
# ════════════════════════════════════════════════════
section "15/16 — Multimídia"

# openh264 via Cisco (repo fedora-cisco-openh264 já vem habilitado)
info "Instalando openh264..."
install_pkg openh264 gstreamer1-plugin-openh264 mozilla-openh264
ok "openh264 instalado!"

info "Instalando VLC..."
install_pkg vlc 2>/dev/null || {
    warn "VLC não disponível no dnf — instalando via Flatpak..."
    install_flatpak org.videolan.VLC
}
ok "VLC instalado!"

info "Instalando Spotify..."
install_flatpak com.spotify.Client
ok "Spotify instalado!"

info "Instalando OBS Studio..."
install_flatpak com.obsproject.Studio
ok "OBS Studio instalado!"

# ════════════════════════════════════════════════════
# 16. NGINX + SCRIPTS PERSONALIZADOS
# ════════════════════════════════════════════════════
section "16/16 — Nginx + Scripts Personalizados"

info "Instalando Nginx..."

install_pkg nginx

run_root systemctl enable --now nginx

ok "Nginx instalado e iniciado!"

BIN_DIR="/usr/local/bin"

# ─────────────────────────────────────────────
# adddominio
# ─────────────────────────────────────────────
run_root tee "$BIN_DIR/adddominio" > /dev/null << 'EOF'
#!/bin/bash

echo "======================================="
echo " Criador de Domínios Locais para Nginx "
echo "======================================="
echo

read -p "Domínio local (ex: olezele.local): " DOMAIN
read -p "IP do serviço (ex: 127.0.0.1): " IP
read -p "Porta do serviço (ex: 8080): " PORT

CONF_FILE="/etc/nginx/conf.d/${DOMAIN}.conf"

echo
echo "Resumo:"
echo "Domínio: $DOMAIN"
echo "Destino: http://$IP:$PORT"
echo

read -p "Confirmar? (s/N): " CONFIRM

if [[ ! "$CONFIRM" =~ ^[Ss]$ ]]; then
    echo "Operação cancelada."
    exit 0
fi

if ! grep -q "$DOMAIN" /etc/hosts; then
    echo "127.0.0.1 $DOMAIN" | sudo tee -a /etc/hosts >/dev/null
fi

sudo tee "$CONF_FILE" > /dev/null <<EONGINX
server {
    listen 80;
    server_name $DOMAIN;

    location / {
        proxy_pass http://$IP:$PORT;

        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EONGINX

if sudo nginx -t; then
    sudo systemctl reload nginx
    echo
    echo "✓ Domínio criado com sucesso!"
    echo "http://$DOMAIN"
else
    sudo rm -f "$CONF_FILE"
    echo "Erro na configuração."
    exit 1
fi
EOF

run_root chmod +x "$BIN_DIR/adddominio"

# ─────────────────────────────────────────────
# atualizar
# ─────────────────────────────────────────────
run_root tee "$BIN_DIR/atualizar" > /dev/null << 'EOF'
#!/bin/bash
sudo dnf update --refresh -y
EOF

run_root chmod +x "$BIN_DIR/atualizar"

# ─────────────────────────────────────────────
# temp
# ─────────────────────────────────────────────
run_root tee "$BIN_DIR/temp" > /dev/null << 'EOF'
#!/bin/bash

if [ ! -d "$HOME/Temp" ]; then
    echo "Pasta ~/Temp não existe."
    exit 0
fi

read -p "Deseja limpar a pasta ~/Temp? (s/N): " resposta

if [[ "$resposta" =~ ^[Ss]$ ]]; then
    cd "$HOME/Temp" || exit 1
    rm -rf ./*
    echo "Pasta Temp limpa."
else
    echo "Limpeza cancelada."
fi
EOF

run_root chmod +x "$BIN_DIR/temp"

ok "Scripts personalizados instalados em /usr/local/bin/!"


# ════════════════════════════════════════════════════
# RESUMO FINAL
# ════════════════════════════════════════════════════
echo ""
echo -e "${BOLD}${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${GREEN}║            SETUP CONCLUÍDO COM SUCESSO! 🚀            ║${NC}"
echo -e "${BOLD}${GREEN}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BOLD}  IDEs${NC}"
echo -e "${GREEN}  ✔  VS Code"
echo -e "  ✔  Cursor"
echo -e "  ✔  JetBrains Toolbox  ${YELLOW}(abra e instale IntelliJ, PyCharm)${GREEN}"
echo -e "  ✔  DataGrip (Flatpak)"
echo ""
echo -e "${BOLD}  Ferramentas Dev${NC}"
echo -e "${GREEN}  ✔  Postman"
echo -e "  ✔  Docker Desktop"
echo -e "  ✔  kubectl"
echo -e "  ✔  FreeDownloadManager  ${YELLOW}(~/Applications/)${GREEN}"
echo -e "  ✔  qBittorrent"
echo -e "  ✔  Draw.io"
echo -e "  ✔  Steam"
echo ""
echo -e "${BOLD}  Linguagens & Runtime${NC}"
echo -e "${GREEN}  ✔  Node.js LTS via NVM + pnpm, yarn, typescript, ts-node"
echo -e "  ✔  Java latest (OpenJDK) + Maven"
echo -e "  ✔  Python 3"
echo -e "  ✔  PHP + Composer"
echo -e "  ✔  PostgreSQL"
echo -e "  ✔  PGAdmin 4"
echo ""
echo -e "${BOLD}  Outros${NC}"
echo -e "${GREEN}  ✔  ZSH + Oh My Zsh"
echo -e "  ✔  Git + Chave SSH"
echo -e "  ✔  Brave Browser Nightly"
echo -e "  ✔  Discord"
echo -e "  ✔  VLC + Spotify + OBS + openh264"
echo -e "  ✔  Nginx"
echo -e "  ✔  adddominio"
echo -e "  ✔  atualizar"
echo -e "  ✔  temp${NC}"
echo ""
echo -e "${YELLOW}${BOLD}  PENDÊNCIAS MANUAIS:${NC}"
echo -e "${YELLOW}  1. Edite SSH_EMAIL no script antes de rodar (ou rode novamente após editar)"
echo -e "  2. git config --global user.name \"Lucas\""
echo -e "  3. git config --global user.email \"seuemail@gmail.com\""
echo -e "  4. Adicione ~/.ssh/id_ed25519.pub no GitHub"
echo -e "  5. Abra o JetBrains Toolbox e instale IntelliJ + PyCharm"
echo -e "  6. Abra o Docker Desktop para completar a configuração"
echo -e "  7. Faça logout/login (ou reinicie) para o grupo docker ter efeito"
echo -e "  8. ${BOLD}REINICIE O SISTEMA!${NC}"
echo ""