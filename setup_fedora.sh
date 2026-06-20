#!/bin/bash

# ╔══════════════════════════════════════════════════╗
# ║         SETUP FEDORA LINUX - Lucas               ║
# ║  Execute: sudo bash setup-fedora.sh              ║
# ╚══════════════════════════════════════════════════╝

set -e

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

# ─── Verificação de root ──────────────────────────
if [[ $EUID -ne 0 ]]; then
    err "Execute como root: sudo bash setup-fedora.sh"
    exit 1
fi

REAL_USER="${SUDO_USER:-$(logname 2>/dev/null)}"
HOME_DIR="/home/$REAL_USER"

if [[ -z "$REAL_USER" || "$REAL_USER" == "root" ]]; then
    err "Não foi possível identificar o usuário. Use: sudo bash setup-fedora.sh"
    exit 1
fi

# Pasta para AppImages
APPS_DIR="$HOME_DIR/Applications"
mkdir -p "$APPS_DIR"
chown "$REAL_USER":"$REAL_USER" "$APPS_DIR"

echo -e "\n${BOLD}${CYAN}  Usuário: $REAL_USER${NC}"
echo -e "${BOLD}${CYAN}  Home:    $HOME_DIR${NC}"
echo -e "${BOLD}${CYAN}  Apps:    $APPS_DIR${NC}\n"


# ════════════════════════════════════════════════════
# 1. SISTEMA + REPOSITÓRIOS
# ════════════════════════════════════════════════════
section "1/15 — Sistema + Repositórios"

dnf update -y --quiet
dnf install -y --quiet \
dnf-plugins-core curl wget unzip zip tar \
make gcc gcc-c++ openssl openssl-devel \
fuse fuse-libs                           # necessário para AppImages
ok "Sistema atualizado!"

# ── Brave Browser Nightly ──────────────────────────
info "Brave Browser Nightly..."
if [ ! -f /etc/yum.repos.d/brave-browser-nightly.repo ]; then
    dnf config-manager addrepo \
    --from-repofile=https://brave-browser-rpm-nightly.s3.brave.com/brave-browser-nightly.repo
fi
rpm --import https://brave-browser-rpm-nightly.s3.brave.com/brave-core-nightly.asc

# ── VS Code ───────────────────────────────────────
info "VS Code..."
rpm --import https://packages.microsoft.com/keys/microsoft.asc
cat > /etc/yum.repos.d/vscode.repo << 'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF

# ── Cursor ────────────────────────────────────────
info "Cursor..."
cat > /etc/yum.repos.d/cursor.repo << 'EOF'
[cursor]
name=Cursor
baseurl=https://download.todesktop.com/230313mzl4w4u92/rpm
enabled=1
gpgcheck=0
EOF

# ── Docker ────────────────────────────────────────
info "Docker..."
if [ ! -f /etc/yum.repos.d/docker-ce.repo ]; then
    dnf config-manager addrepo \
    --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo
fi

# ── Flathub ───────────────────────────────────────
info "Flathub..."
dnf install -y --quiet flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

ok "Todos os repositórios configurados!"


# ════════════════════════════════════════════════════
# 2. FERRAMENTAS DE TERMINAL
# ════════════════════════════════════════════════════
section "2/15 — Ferramentas de terminal"

PACKAGES="zsh htop tree fzf bat ripgrep jq"

if dnf info fastfetch >/dev/null 2>&1; then
    PACKAGES="$PACKAGES fastfetch"
else
    PACKAGES="$PACKAGES neofetch"
fi

dnf install -y --quiet $PACKAGES

ok "Ferramentas de terminal instaladas"

# ── Oh My Zsh ─────────────────────────────────────
if [ ! -d "$HOME_DIR/.oh-my-zsh" ]; then
    info "Instalando Oh My Zsh..."
    sudo -u "$REAL_USER" sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    ok "Oh My Zsh instalado!"
else
    warn "Oh My Zsh já existe, pulando..."
fi

chsh -s "$(which zsh)" "$REAL_USER"
ok "Shell padrão → ZSH"


# ════════════════════════════════════════════════════
# 3. GIT + SSH
# ════════════════════════════════════════════════════
section "3/15 — Git + SSH"

dnf install -y --quiet git

sudo -u "$REAL_USER" git config --global init.defaultBranch main
sudo -u "$REAL_USER" git config --global core.editor "code --wait"
sudo -u "$REAL_USER" git config --global pull.rebase false
sudo -u "$REAL_USER" git config --global core.autocrlf input
ok "Git configurado!"

SSH_KEY="$HOME_DIR/.ssh/id_ed25519"
mkdir -p "$HOME_DIR/.ssh"
chmod 700 "$HOME_DIR/.ssh"
chown "$REAL_USER":"$REAL_USER" "$HOME_DIR/.ssh"

if [ ! -f "$SSH_KEY" ]; then
    # ─── EDITE SEU EMAIL AQUI ───────────────────────
    SSH_EMAIL="seuemail@gmail.com"
    # ───────────────────────────────────────────────
    sudo -u "$REAL_USER" ssh-keygen -t ed25519 -C "$SSH_EMAIL" -f "$SSH_KEY" -N ""
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
section "4/15 — Node.js via NVM"

NVM_VERSION="v0.40.1"
NVM_DIR="$HOME_DIR/.nvm"

if [ ! -d "$NVM_DIR" ]; then
    sudo -u "$REAL_USER" bash -c \
    "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh | bash"
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
  if ! grep -q "NVM_DIR" "$RC" 2>/dev/null; then
    echo "$NVM_BLOCK" >> "$RC"
  fi
done

sudo -u "$REAL_USER" bash -c \
  "source $NVM_DIR/nvm.sh && nvm install --lts && nvm use --lts && nvm alias default node"
ok "Node.js LTS instalado!"

sudo -u "$REAL_USER" bash -c \
  "source $NVM_DIR/nvm.sh && npm install -g pnpm yarn typescript ts-node"
ok "Globais: pnpm, yarn, typescript, ts-node"


# ════════════════════════════════════════════════════
# 5. Java Latest OpenJDK + Maven
# ════════════════════════════════════════════════════
section "5/15 — Java Latest OpenJDK + Maven"

dnf install -y --quiet java-latest-openjdk java-latest-openjdk-devel maven
ok "Java 21 (OpenJDK) + Maven instalados!"

JAVA_BLOCK='
# Java
export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which javac))))
export PATH="$JAVA_HOME/bin:$PATH"'

for RC in "$HOME_DIR/.zshrc" "$HOME_DIR/.bashrc"; do
    if ! grep -q "JAVA_HOME" "$RC" 2>/dev/null; then
        echo "$JAVA_BLOCK" >> "$RC"
    fi
done
ok "JAVA_HOME configurado!"


# ════════════════════════════════════════════════════
# 6. PYTHON 3
# ════════════════════════════════════════════════════
section "6/15 — Python 3"

dnf install -y --quiet python3 python3-pip python3-devel
ok "Python 3 instalado!"

PYTHON_BLOCK='
# Python
alias python=python3
alias pip=pip3'

for RC in "$HOME_DIR/.zshrc" "$HOME_DIR/.bashrc"; do
    if ! grep -q "alias python=python3" "$RC" 2>/dev/null; then
        echo "$PYTHON_BLOCK" >> "$RC"
    fi
done


# ════════════════════════════════════════════════════
# 7. PHP + COMPOSER
# ════════════════════════════════════════════════════
section "7/15 — PHP + Composer"

dnf install -y --quiet \
php php-cli php-fpm php-mbstring \
php-xml php-curl php-zip php-pdo php-pgsql
ok "PHP instalado!"

info "Instalando Composer..."
EXPECTED_CS="$(php -r 'copy("https://composer.github.io/installer.sig", "php://stdout");')"
php -r "copy('https://getcomposer.org/installer', '/tmp/composer-setup.php');"
ACTUAL_CS="$(php -r "echo hash_file('sha384', '/tmp/composer-setup.php');")"

if [ "$EXPECTED_CS" = "$ACTUAL_CS" ]; then
    php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer --quiet
    rm /tmp/composer-setup.php
    ok "Composer instalado!"
else
    warn "Falha no checksum — instale o Composer manualmente depois."
    rm -f /tmp/composer-setup.php
fi


# ════════════════════════════════════════════════════
# 8. DOCKER DESKTOP
# ════════════════════════════════════════════════════
section "8/15 — Docker Desktop"

# Dependências do Docker Desktop
dnf install -y --quiet pass gnome-terminal
ok "Dependências instaladas (pass, gnome-terminal)"

info "Baixando Docker Desktop (RPM)..."
curl -Lo /tmp/docker-desktop.rpm \
"https://desktop.docker.com/linux/main/amd64/docker-desktop-x86_64.rpm"
dnf install -y /tmp/docker-desktop.rpm
rm -f /tmp/docker-desktop.rpm

getent group docker >/dev/null || groupadd docker
usermod -aG docker "$REAL_USER"
systemctl --user enable docker-desktop 2>/dev/null || true
ok "Docker Desktop instalado!"
warn "Abra o Docker Desktop uma vez para completar a configuração inicial"


# ════════════════════════════════════════════════════
# 9. KUBECTL
# ════════════════════════════════════════════════════
section "9/15 — kubectl"

cat > /etc/yum.repos.d/kubernetes.repo << 'EOF'
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.30/gpgkey
EOF

if dnf install -y kubectl; then
    ok "kubectl instalado!"
else
    warn "Falha ao instalar kubectl. Continuando..."
fi


# ════════════════════════════════════════════════════
# 10. POSTGRESQL
# ════════════════════════════════════════════════════
section "10/15 — PostgreSQL"

dnf install -y --quiet postgresql postgresql-server postgresql-contrib

if [ ! -f /var/lib/pgsql/data/PG_VERSION ]; then
    postgresql-setup --initdb --unit postgresql
fi

systemctl enable postgresql >/dev/null 2>&1
systemctl start postgresql >/dev/null 2>&1
ok "PostgreSQL instalado e iniciado!"
info "Acesse com: sudo -u postgres psql"


# ════════════════════════════════════════════════════
# 10.1 PGADMIN 4
# ════════════════════════════════════════════════════
section "10.1 — PGAdmin 4"

info "Instalando PGAdmin 4..."
sudo -u "$REAL_USER" flatpak remote-add \
    --if-not-exists \
    flathub \
    https://flathub.org/repo/flathub.flatpakrepo
    
sudo -u "$REAL_USER" flatpak install --user -y flathub org.pgadmin.pgadmin4

ok "PGAdmin 4 instalado!"


# ════════════════════════════════════════════════════
# 11. IDEs
# ════════════════════════════════════════════════════
section "11/15 — IDEs"

# ── VS Code ───────────────────────────────────────
info "Instalando VS Code..."
dnf install -y --quiet code
ok "VS Code instalado!"

# ── Cursor ────────────────────────────────────────
info "Instalando Cursor..."
dnf install -y --quiet cursor || {
    warn "Falha via repo — tentando via AppImage..."
    curl -Lo "$APPS_DIR/Cursor.AppImage" \
    "https://download.todesktop.com/230313mzl4w4u92/linux/appimage/x64"
    chmod +x "$APPS_DIR/Cursor.AppImage"
    chown "$REAL_USER":"$REAL_USER" "$APPS_DIR/Cursor.AppImage"
    ok "Cursor instalado como AppImage em ~/Applications/"
}

# ── JetBrains Toolbox → IntelliJ, PyCharm, DataGrip ──
info "Instalando JetBrains Toolbox..."
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
install -m 755 "$TOOLBOX_BIN" /usr/local/bin/jetbrains-toolboxrm -rf /tmp/jetbrains-toolbox* /tmp/jetbrains-toolbox-*
ok "JetBrains Toolbox instalado em /usr/local/bin/"
warn "Abra o Toolbox e instale manualmente: IntelliJ IDEA, PyCharm e DataGrip"


# ════════════════════════════════════════════════════
# 12. FERRAMENTAS DE DESENVOLVIMENTO
# ════════════════════════════════════════════════════
section "12/15 — Ferramentas de Desenvolvimento"

# ── Postman ───────────────────────────────────────
info "Instalando Postman..."
sudo -u "$REAL_USER" flatpak install -y flathub com.getpostman.Postman
ok "Postman instalado!"

# ── DataGrip ─────────────────────────────────────
info "Instalando DataGrip (Flatpak — alternativa ao Toolbox)..."
sudo -u "$REAL_USER" flatpak install -y flathub com.jetbrains.DataGrip
ok "DataGrip instalado!"

# ── FreeDownloadManager ───────────────────────────
info "Instalando FreeDownloadManager (AppImage)..."
FDM_URL="https://download3.freedownloadmanager.org/latest/freedownloadmanager.x86_64.AppImage"
sudo -u "$REAL_USER" curl -Lo "$APPS_DIR/FreeDownloadManager.AppImage" "$FDM_URL"
chmod +x "$APPS_DIR/FreeDownloadManager.AppImage"
chown "$REAL_USER":"$REAL_USER" "$APPS_DIR/FreeDownloadManager.AppImage"
ok "FreeDownloadManager instalado em ~/Applications/"

# Criar .desktop para integração com o menu do sistema
cat > "/usr/share/applications/freedownloadmanager.desktop" << EOF
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
dnf install -y --quiet qbittorrent
ok "qBittorrent instalado!"

# ── Draw.io ───────────────────────────────────────
info "Instalando Draw.io..."
sudo -u "$REAL_USER" flatpak install -y flathub com.jgraph.drawio.desktop
ok "Draw.io instalado!"

# ── Steam ─────────────────────────────────────────
info "Instalando Steam..."
sudo -u "$REAL_USER" flatpak install -y flathub com.valvesoftware.Steam
ok "Steam instalado!"


# ════════════════════════════════════════════════════
# 13. COMUNICAÇÃO
# ════════════════════════════════════════════════════
section "13/15 — Comunicação"

info "Instalando Discord..."
sudo -u "$REAL_USER" flatpak install -y --noninteractive flathub com.discordapp.Discord || true
ok "Discord instalado!"


# ════════════════════════════════════════════════════
# 14. NAVEGADORES
# ════════════════════════════════════════════════════
section "14/15 — Navegadores"

info "Instalando Brave Browser Nightly..."
dnf install -y --quiet brave-browser-nightly
ok "Brave Browser Nightly instalado!"
ok "Firefox já vem pré-instalado no Fedora"


# ════════════════════════════════════════════════════
# 15. MULTIMÍDIA
# ════════════════════════════════════════════════════
section "15/15 — Multimídia"

# openh264 via Cisco (repo fedora-cisco-openh264 já vem habilitado)
info "Instalando openh264..."
dnf install -y --quiet openh264 gstreamer1-plugin-openh264 mozilla-openh264
ok "openh264 instalado!"

info "Instalando VLC..."
dnf install -y --quiet vlc 2>/dev/null || {
    warn "VLC não disponível no dnf — instalando via Flatpak..."
    sudo -u "$REAL_USER" flatpak install -y flathub org.videolan.VLC
}
ok "VLC instalado!"

info "Instalando Spotify..."
sudo -u "$REAL_USER" flatpak install -y flathub com.spotify.Client
ok "Spotify instalado!"

info "Instalando OBS Studio..."
sudo -u "$REAL_USER" flatpak install -y flathub com.obsproject.Studio
ok "OBS Studio instalado!"

# ════════════════════════════════════════════════════
# 16. NGINX + SCRIPTS PERSONALIZADOS
# ════════════════════════════════════════════════════
section "16/16 — Nginx + Scripts Personalizados"

info "Instalando Nginx..."

dnf install -y --quiet nginx

systemctl enable nginx
systemctl start nginx

ok "Nginx instalado e iniciado!"

BIN_DIR="/bin"

# ─────────────────────────────────────────────
# adddominio
# ─────────────────────────────────────────────
cat > "$BIN_DIR/adddominio" << 'EOF'
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

chmod +x "$BIN_DIR/adddominio"

# ─────────────────────────────────────────────
# atualizar
# ─────────────────────────────────────────────
cat > "$BIN_DIR/atualizar" << 'EOF'
#!/bin/bash
sudo dnf update --refresh -y
EOF

chmod +x "$BIN_DIR/atualizar"

# ─────────────────────────────────────────────
# temp
# ─────────────────────────────────────────────
cat > "$BIN_DIR/temp" << 'EOF'
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

chmod +x "$BIN_DIR/temp"

ok "Scripts personalizados instalados!"


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
echo -e "  ✔  Java 21 (OpenJDK) + Maven"
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
echo -e "${YELLOW}  1. Edite SSH_EMAIL no script antes de rodar"
echo -e "  2. git config --global user.name \"Lucas\""
echo -e "  3. git config --global user.email \"seuemail@gmail.com\""
echo -e "  4. Adicione ~/.ssh/id_ed25519.pub no GitHub"
echo -e "  5. Abra o JetBrains Toolbox e instale IntelliJ + PyCharm"
echo -e "  6. Abra o Docker Desktop para completar a configuração"
echo -e "  7. ${BOLD}REINICIE O SISTEMA!${NC}"
echo ""