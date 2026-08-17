#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

section() { echo -e "\n${PURPLE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; echo -e "${PURPLE}${BOLD}  $1${NC}"; echo -e "${PURPLE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; }
ok()      { echo -e "  ${GREEN}✔  $1${NC}"; }
info()    { echo -e "  ${CYAN}→  $1${NC}"; }
warn()    { echo -e "  ${YELLOW}⚠  $1${NC}"; }
err()     { echo -e "  ${RED}✘  $1${NC}"; }

if [[ $EUID -eq 0 ]]; then
    err "Não execute este script como root ou com sudo."
    exit 1
fi

if ! sudo -v; then
    err "Seu usuário precisa ter permissão sudo."
    exit 1
fi

run_root() {
    sudo "$@"
}

install_pkg() {
    if sudo dnf install -y --quiet "$@"; then
        return 0
    else
        warn "Falha ao instalar pacote(s): $*. Continuando..."
        return 1
    fi
}

install_flatpak() {
    if flatpak install -y flathub "$1"; then
        return 0
    else
        warn "Falha ao instalar via Flatpak: $1. Continuando..."
        return 1
    fi
}

REAL_USER="$(whoami)"
HOME_DIR="$HOME"
APPS_DIR="$HOME/Applications"

mkdir -p "$APPS_DIR"

echo -e "\n${BOLD}${CYAN}  Usuário: $REAL_USER${NC}"
echo -e "${BOLD}${CYAN}  Home:    $HOME_DIR${NC}"
echo -e "${BOLD}${CYAN}  Apps:    $APPS_DIR${NC}\n"

section "1/16 — Sistema + Repositórios"

run_root dnf update -y --quiet || warn "Aviso na atualização do sistema."
install_pkg dnf-plugins-core curl wget unzip zip tar make gcc gcc-c++ openssl openssl-devel fuse fuse-libs

info "Brave Browser Nightly..."
if [ ! -f /etc/yum.repos.d/brave-browser-nightly.repo ]; then
    run_root dnf config-manager addrepo --from-repofile=https://brave-browser-rpm-nightly.s3.brave.com/brave-browser-nightly.repo || true
fi
run_root rpm --import https://brave-browser-rpm-nightly.s3.brave.com/brave-core-nightly.asc || true

info "VS Code..."
run_root rpm --import https://packages.microsoft.com/keys/microsoft.asc || true
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

info "Docker..."
if [ ! -f /etc/yum.repos.d/docker-ce.repo ]; then
    run_root dnf config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo || true
fi

info "Flathub..."
install_pkg flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true

ok "Repositórios processados!"

section "2/16 — Ferramentas de terminal"

run_root dnf copr enable -y atim/starship || true
PACKAGES="zsh htop tree fzf bat ripgrep jq starship"

if dnf info fastfetch >/dev/null 2>&1; then
    PACKAGES="$PACKAGES fastfetch"
else
    PACKAGES="$PACKAGES neofetch"
fi

install_pkg $PACKAGES

info "Configurando ZSH, Zinit e Starship..."
cat << 'EOF' > "$HOME_DIR/.zshrc"
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33}%F{220}Instalando Zinit...%f"
    mkdir -p "$HOME/.local/share/zinit"
    git clone https://github.com/zdharma-continuum/zinit.git "$HOME/.local/share/zinit/zinit.git"
fi
source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#d65d0e'
setopt AUTO_CD
autoload -U compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' menu select
bindkey '^[[A' history-beginning-search-backward
bindkey '^[[B' history-beginning-search-forward
alias ls='ls --color=auto'
alias ll='ls -lh --color=auto'
alias la='ls -la --color=auto'
alias c='clear'
alias a='atualizar'
eval "$(starship init zsh)"
EOF

mkdir -p "$HOME_DIR/.config"
cat << 'EOF' > "$HOME_DIR/.config/starship.toml"
format = """
[░▒▓](#ff8c00)\
$os\
$username\
[](bg:#fe8019 fg:#ff8c00)\
$directory\
[](fg:#fe8019 bg:#fabd2f)\
$git_branch\
$git_status\
[](fg:#fabd2f bg:#3c3836)\
$c\
$rust\
$golang\
$nodejs\
$php\
$java\
$python\
[](fg:#3c3836) $character"""

[os]
disabled = false
style = "bg:#ff8c00 fg:#1d2021"

[os.symbols]
Fedora = "🎧 "

[username]
show_always = true
style_user = "bg:#ff8c00 fg:#1d2021"
style_root = "bg:#ff8c00 fg:#1d2021"
format = '[$user]($style)'

[directory]
style = "bg:#fe8019 fg:#1d2021"
format = "[ $path ]($style)"
truncation_length = 3
truncation_symbol = "…/"

[git_branch]
symbol = ""
style = "bg:#fabd2f fg:#1d2021"
format = '[ $symbol $branch ]($style)'

[git_status]
style = "bg:#fabd2f fg:#1d2021"
format = '[$all_status$ahead_behind ]($style)'

[character]
success_symbol = '[❯](bold #ff8c00)'
error_symbol = '[❯](bold red)'
EOF

run_root chsh -s "$(which zsh)" "$REAL_USER" || warn "Falha ao definir ZSH como padrão."
ok "Shell ZSH configurado"

section "3/16 — Git + SSH"

if command -v git >/dev/null 2>&1; then
    warn "Git já instalado."
else
    install_pkg git
fi

git config --global init.defaultBranch main
git config --global core.editor "code --wait"
git config --global pull.rebase false
git config --global core.autocrlf input

SSH_KEY="$HOME_DIR/.ssh/id_ed25519"
mkdir -p ~/.ssh
chmod 700 ~/.ssh

if [ ! -f "$SSH_KEY" ]; then
    SSH_EMAIL="seuemail@gmail.com"
    ssh-keygen -t ed25519 -C "$SSH_EMAIL" -f "$SSH_KEY" -N "" || warn "Falha ao gerar chave SSH."
    if [ -f "$SSH_KEY.pub" ]; then
        echo ""
        warn "Adicione esta chave no GitHub:"
        echo -e "${CYAN}"
        cat "$SSH_KEY.pub"
        echo -e "${NC}"
    fi
else
    warn "Chave SSH já existe, pulando..."
fi

section "4/16 — Node.js via NVM"

NVM_VERSION="v0.40.1"
NVM_DIR="$HOME_DIR/.nvm"

if [ ! -d "$NVM_DIR" ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh | bash || warn "Falha ao instalar NVM."
else
    warn "NVM já existe, pulando..."
fi

NVM_BLOCK='
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"'

for RC in "$HOME_DIR/.zshrc" "$HOME_DIR/.bashrc"; do
    touch "$RC"
    if ! grep -q "NVM_DIR" "$RC" 2>/dev/null; then
        echo "$NVM_BLOCK" >> "$RC"
    fi
done

if [ -f "$NVM_DIR/nvm.sh" ]; then
    bash -c "source $NVM_DIR/nvm.sh && nvm install --lts && nvm use --lts && nvm alias default node" || warn "Falha ao instalar Node LTS."
    bash -c "source $NVM_DIR/nvm.sh && npm install -g pnpm yarn typescript ts-node" || warn "Falha ao instalar pacotes globais npm."
fi

section "5/16 — Java Latest OpenJDK + Maven"

install_pkg java-latest-openjdk java-latest-openjdk-devel maven

JAVA_BLOCK='
export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which javac))))
export PATH="$JAVA_HOME/bin:$PATH"'

for RC in "$HOME_DIR/.zshrc" "$HOME_DIR/.bashrc"; do
    touch "$RC"
    if ! grep -q "JAVA_HOME" "$RC" 2>/dev/null; then
        echo "$JAVA_BLOCK" >> "$RC"
    fi
done

section "6/16 — Python 3"

install_pkg python3 python3-pip python3-devel

PYTHON_BLOCK='
alias python=python3
alias pip=pip3'

for RC in "$HOME_DIR/.zshrc" "$HOME_DIR/.bashrc"; do
    touch "$RC"
    if ! grep -q "alias python=python3" "$RC" 2>/dev/null; then
        echo "$PYTHON_BLOCK" >> "$RC"
    fi
done

section "7/16 — PHP + Composer"

install_pkg php php-cli php-fpm php-mbstring php-xml php-curl php-zip php-pdo php-pgsql

if command -v composer >/dev/null 2>&1; then
    warn "Composer já instalado, pulando..."
else
    info "Instalando Composer..."
    EXPECTED_CS="$(php -r 'copy("https://composer.github.io/installer.sig", "php://stdout");' 2>/dev/null)" || true
    if php -r "copy('https://getcomposer.org/installer', '/tmp/composer-setup.php');" 2>/dev/null; then
        ACTUAL_CS="$(php -r "echo hash_file('sha384', '/tmp/composer-setup.php');")"
        if [ "$EXPECTED_CS" = "$ACTUAL_CS" ]; then
            run_root php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer --quiet || warn "Falha ao mover composer."
            ok "Composer instalado!"
        else
            warn "Falha no checksum do Composer."
        fi
        rm -f /tmp/composer-setup.php
    else
        warn "Falha ao baixar instalador do Composer."
    fi
fi

section "8/16 — Docker Desktop"

install_pkg pass gnome-terminal

if rpm -q docker-desktop >/dev/null 2>&1; then
    warn "Docker Desktop já instalado, pulando..."
else
    info "Baixando Docker Desktop (RPM)..."
    if curl -Lo /tmp/docker-desktop.rpm "https://desktop.docker.com/linux/main/amd64/docker-desktop-x86_64.rpm"; then
        install_pkg /tmp/docker-desktop.rpm
        rm -f /tmp/docker-desktop.rpm
    else
        warn "Falha ao baixar RPM do Docker Desktop."
    fi
fi

run_root groupadd -f docker
run_root usermod -aG docker "$USER" || true

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

install_pkg kubectl

section "10/16 — PostgreSQL"

install_pkg postgresql postgresql-server postgresql-contrib

if sudo -u postgres psql -c '\l' >/dev/null 2>&1; then
    warn "PostgreSQL já configurado."
else
    info "Configurando PostgreSQL..."
    if [ ! -f "/var/lib/pgsql/data/PG_VERSION" ]; then
        run_root rm -rf /var/lib/pgsql/data/*
        run_root postgresql-setup --initdb --unit postgresql || warn "Falha ao inicializar banco PostgreSQL."
    fi
    run_root systemctl enable --now postgresql || warn "Falha ao iniciar serviço PostgreSQL."
fi

section "10.1 — PGAdmin 4"

install_flatpak org.pgadmin.pgadmin4

section "11/16 — IDEs"

info "Instalando VS Code..."
install_pkg code

info "Instalando Cursor..."
if curl -Lo /tmp/cursor.rpm "https://download.todesktop.com/230313mzl4w4u92/linux/rpm/x64"; then
    if ! install_pkg /tmp/cursor.rpm; then
        warn "Falha via RPM — tentando via AppImage..."
        if curl -Lo "$APPS_DIR/Cursor.AppImage" "https://download.todesktop.com/230313mzl4w4u92/linux/appimage/x64"; then
            chmod +x "$APPS_DIR/Cursor.AppImage"
            ok "Cursor instalado como AppImage em ~/Applications/"
        else
            warn "Falha ao baixar AppImage do Cursor."
        fi
    fi
    rm -f /tmp/cursor.rpm
else
    warn "Falha no download do Cursor."
fi

info "Instalando JetBrains Toolbox..."
if [ -f /usr/local/bin/jetbrains-toolbox ]; then
    warn "JetBrains Toolbox já instalado, pulando..."
else
    TOOLBOX_URL=$(curl -s "https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release" | python3 -c "import sys, json; data = json.load(sys.stdin); print(data['TBA'][0]['downloads']['linux']['link'])" 2>/dev/null) || true
    if [ -n "$TOOLBOX_URL" ]; then
        if curl -Lo /tmp/toolbox.tar.gz "$TOOLBOX_URL"; then
            mkdir -p /tmp/toolbox_extracted
            if tar -xzf /tmp/toolbox.tar.gz -C /tmp/toolbox_extracted --strip-components=1 2>/dev/null; then
                if [ -f "/tmp/toolbox_extracted/jetbrains-toolbox" ]; then
                    run_root install -m 755 /tmp/toolbox_extracted/jetbrains-toolbox /usr/local/bin/jetbrains-toolbox || warn "Falha ao mover binário do JetBrains Toolbox."
                    ok "JetBrains Toolbox instalado!"
                else
                    warn "Binário não encontrado após extração."
                fi
            else
                warn "Falha ao extrair pacote do JetBrains Toolbox."
            fi
            rm -rf /tmp/toolbox* || true
        else
            warn "Falha no download do JetBrains Toolbox."
        fi
    else
        warn "Não foi possível obter a URL do JetBrains Toolbox."
    fi
fi

section "12/16 — Ferramentas de Desenvolvimento"

install_flatpak com.getpostman.Postman

run_root tee "/usr/share/applications/freedownloadmanager.desktop" > /dev/null << EOF
[Desktop Entry]
Name=Free Download Manager
Exec=$APPS_DIR/FreeDownloadManager.AppImage
Icon=browser-download
Type=Application
Categories=Network;FileTransfer;
EOF

install_pkg qbittorrent
install_flatpak com.jgraph.drawio.desktop
install_flatpak com.valvesoftware.Steam

section "13/16 — Comunicação"

install_flatpak com.discordapp.Discord

section "14/16 — Navegadores"

install_pkg brave-browser-nightly

section "15/16 — Multimídia"

install_pkg openh264 gstreamer1-plugin-openh264 mozilla-openh264
install_pkg vlc || install_flatpak org.videolan.VLC
install_flatpak com.spotify.Client
install_flatpak com.obsproject.Studio

section "16/16 — Nginx + Scripts Personalizados"

if install_pkg nginx; then
    run_root systemctl enable --now nginx || warn "Falha ao iniciar Nginx."
fi

BIN_DIR="/usr/local/bin"

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

run_root tee "$BIN_DIR/atualizar" > /dev/null << 'EOF'
#!/bin/bash
sudo dnf update --refresh -y
EOF

run_root chmod +x "$BIN_DIR/atualizar"

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

echo ""
echo -e "${BOLD}${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${GREEN}║            SETUP CONCLUÍDO COM SUCESSO! 🚀            ║${NC}"
echo -e "${BOLD}${GREEN}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BOLD}  IDEs${NC}"
echo -e "${GREEN}  ✔  VS Code"
echo -e "  ✔  Cursor"
echo -e "  ✔  JetBrains Toolbox  ${YELLOW}(Abra e instale IntelliJ, PyCharm, DataGrip)${GREEN}"
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
echo -e "${GREEN}  ✔  ZSH + Zinit + Starship (Tema Laranja 🎧)"
echo -e "  ✔  Git + Chave SSH"
echo -e "  ✔  Brave Browser Nightly"
echo -e "  ✔  Discord"
echo -e "  ✔  VLC + Spotify + OBS + openh264"
echo -e "  ✔  Nginx"
echo -e "  ✔  adddominio"
echo -e "  ✔  atualizar"
echo -e "  ✔  temp${NC}"
echo ""
echo -e "${YELLOW}${BOLD}  PENDÊNCIAS MANUAIS PÓS-INSTALAÇÃO:${NC}"
echo -e "${YELLOW}  1. [Git/SSH]    Edite a variável SSH_EMAIL no script antes de rodar (ou gere uma nova manualmente)."
echo -e "  2. [Git]        Configure seu nome no Git: ${NC}git config --global user.name \"Seu Nome\""
echo -e "${YELLOW}  3. [Git]        Configure seu email no Git: ${NC}git config --global user.email \"seuemail@exemplo.com\""
echo -e "${YELLOW}  4. [Git/SSH]    Copie e adicione sua chave SSH pública no GitHub/GitLab: ${NC}cat ~/.ssh/id_ed25519.pub"
echo -e "${YELLOW}  5. [IDEs]       Abra o JetBrains Toolbox no menu de aplicativos e instale o IntelliJ IDEA, PyCharm e DataGrip."
echo -e "  6. [Docker]     Abra o Docker Desktop uma vez para aceitar os termos de serviço e completar a configuração."
echo -e "  7. [Banco]      Acesse o PostgreSQL para definir uma senha: ${NC}sudo -u postgres psql ${YELLOW}(depois digite \\password e saia com \\q)"
echo -e "${YELLOW}  8. [Banco]      Abra o PGAdmin 4 e configure a conexão inicial com o servidor PostgreSQL local."
echo -e "  9. [Contas]     Faça login em suas ferramentas (VS Code, Cursor, Discord, Spotify, Steam, Navegadores)."
echo -e " 10. [Sistema]    ${BOLD}REINICIE O SISTEMA${YELLOW} para que as fontes, ZSH, NVM e as permissões de grupo (Docker) entrem em vigor por completo!${NC}"
echo ""