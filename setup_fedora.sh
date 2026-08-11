#!/bin/bash

set -eo pipefail

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

trap 'err "Erro na linha $LINENO. Abortando."; exit 1' ERR

if [[ $EUID -eq 0 ]]; then
    err "Não execute este script como root ou com sudo."
    err "Use: ./setup-fedora.sh  ou  bash setup-fedora.sh"
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
    sudo dnf install -y --quiet "$@"
}

install_flatpak() {
    flatpak install -y flathub "$1"
}

REAL_USER="$(whoami)"
HOME_DIR="$HOME"

APPS_DIR="$HOME/Applications"
mkdir -p "$APPS_DIR"

echo -e "\n${BOLD}${CYAN}  Usuário: $REAL_USER${NC}"
echo -e "${BOLD}${CYAN}  Home:    $HOME_DIR${NC}"
echo -e "${BOLD}${CYAN}  Apps:    $APPS_DIR${NC}\n"

section "1/16 — Sistema + Repositórios"

run_root dnf update -y --quiet
install_pkg dnf-plugins-core curl wget unzip zip tar make gcc gcc-c++ openssl openssl-devel fuse fuse-libs
ok "Sistema atualizado!"

info "Brave Browser Nightly..."
if [ ! -f /etc/yum.repos.d/brave-browser-nightly.repo ]; then
    run_root dnf config-manager addrepo --from-repofile=https://brave-browser-rpm-nightly.s3.brave.com/brave-browser-nightly.repo
fi
run_root rpm --import https://brave-browser-rpm-nightly.s3.brave.com/brave-core-nightly.asc

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

info "Docker..."
if [ ! -f /etc/yum.repos.d/docker-ce.repo ]; then
    run_root dnf config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo
fi

info "Flathub..."
install_pkg flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

ok "Todos os repositórios configurados!"

section "2/16 — Ferramentas de terminal"

run_root dnf copr enable -y atim/starship
PACKAGES="zsh htop tree fzf bat ripgrep jq starship"

if dnf info fastfetch >/dev/null 2>&1; then
    PACKAGES="$PACKAGES fastfetch"
else
    PACKAGES="$PACKAGES neofetch"
fi

install_pkg $PACKAGES
ok "Ferramentas de terminal instaladas"

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

run_root chsh -s "$(which zsh)" "$REAL_USER"
ok "Shell padrão → ZSH"

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
    SSH_EMAIL="seuemail@gmail.com"
    ssh-keygen -t ed25519 -C "$SSH_EMAIL" -f "$SSH_KEY" -N ""
    ok "Chave SSH gerada!"
    echo ""
    warn "Adicione esta chave no GitHub:"
    echo -e "${CYAN}"
    cat "$SSH_KEY.pub"
    echo -e "${NC}"
else
    warn "Chave SSH já existe, pulando..."
fi

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
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"'

for RC in "$HOME_DIR/.zshrc" "$HOME_DIR/.bashrc"; do
  touch "$RC"
  if ! grep -q "NVM_DIR" "$RC" 2>/dev/null; then
    echo "$NVM_BLOCK" >> "$RC"
  fi
done

bash -c "source $NVM_DIR/nvm.sh && nvm install --lts && nvm use --lts && nvm alias default node"
ok "Node.js LTS instalado!"

bash -c "source $NVM_DIR/nvm.sh && npm install -g pnpm yarn typescript ts-node"
ok "Globais: pnpm, yarn, typescript, ts-node"

section "5/16 — Java Latest OpenJDK + Maven"

install_pkg java-latest-openjdk java-latest-openjdk-devel maven
ok "Java (OpenJDK) + Maven instalados!"

JAVA_BLOCK='
export JAVA_HOME=$(dirname$(dirname $(readlink -f$(which javac))))
export PATH="$JAVA_HOME/bin:$PATH"'

for RC in "$HOME_DIR/.zshrc" "$HOME_DIR/.bashrc"; do
    touch "$RC"
    if ! grep -q "JAVA_HOME" "$RC" 2>/dev/null; then
        echo "$JAVA_BLOCK" >> "$RC"
    fi
done
ok "JAVA_HOME configurado!"

section "6/16 — Python 3"

install_pkg python3 python3-pip python3-devel
ok "Python 3 instalado!"

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

section "8/16 — Docker Desktop"

install_pkg pass gnome-terminal
ok "Dependências instaladas (pass, gnome-terminal)"

if rpm -q docker-desktop >/dev/null 2>&1; then
    warn "Docker Desktop já instalado, pulando..."
else
    info "Baixando Docker Desktop (RPM)..."
    curl -Lo /tmp/docker-desktop.rpm "https://desktop.docker.com/linux/main/amd64/docker-desktop-x86_64.rpm"
    install_pkg /tmp/docker-desktop.rpm
    rm -f /tmp/docker-desktop.rpm
    ok "Docker Desktop instalado!"
fi

run_root groupadd -f docker
run_root usermod -aG docker "$USER"
ok "Usuário adicionado ao grupo docker!"
warn "Abra o Docker Desktop uma vez para completar a configuração inicial"
warn "Faça logout/login para que a associação ao grupo docker tenha efeito"

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

section "10/16 — PostgreSQL"

install_pkg postgresql postgresql-server postgresql-contrib

if sudo -u postgres psql -c '\l' >/dev/null 2>&1; then
    ok "PostgreSQL já configurado."
else
    info "Configurando PostgreSQL..."
    if [ ! -f "/var/lib/pgsql/data/PG_VERSION" ]; then
        run_root rm -rf /var/lib/pgsql/data/*
        run_root postgresql-setup --initdb --unit postgresql
    fi
    run_root systemctl enable --now postgresql
fi

run_root systemctl enable --now postgresql >/dev/null 2>&1

ok "PostgreSQL instalado e iniciado!"
info "Acesse com: sudo -u postgres psql"

section "10.1 — PGAdmin 4"

info "Instalando PGAdmin 4..."
install_flatpak org.pgadmin.pgadmin4
ok "PGAdmin 4 instalado!"

section "11/16 — IDEs"

info "Instalando VS Code..."
install_pkg code
ok "VS Code instalado!"

info "Instalando Cursor..."
install_pkg cursor || {
    warn "Falha via repo — tentando via AppImage..."
    curl -Lo "$APPS_DIR/Cursor.AppImage" "https://download.todesktop.com/230313mzl4w4u92/linux/appimage/x64"
    chmod +x "$APPS_DIR/Cursor.AppImage"
    ok "Cursor instalado como AppImage em ~/Applications/"
}

info "Instalando JetBrains Toolbox..."
if [ -f /usr/local/bin/jetbrains-toolbox ]; then
    warn "JetBrains Toolbox já instalado, pulando..."
else
    TOOLBOX_URL=$(curl -s "https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release" | python3 -c "import sys, json; data = json.load(sys.stdin); print(data['TBA'][0]['downloads']['linux']['link'])")
    curl -Lo /tmp/jetbrains-toolbox.tar.gz "$TOOLBOX_URL"
    tar -xzf /tmp/jetbrains-toolbox.tar.gz -C /tmp/
    TOOLBOX_BIN=$(find /tmp -name "jetbrains-toolbox" -type f 2>/dev/null | head -1)
    run_root install -m 755 "$TOOLBOX_BIN" /usr/local/bin/jetbrains-toolbox
    rm -rf /tmp/jetbrains-toolbox*
    ok "JetBrains Toolbox instalado em /usr/local/bin/"
fi
warn "Abra o Toolbox e instale manualmente: IntelliJ IDEA, PyCharm e DataGrip"

section "12/16 — Ferramentas de Desenvolvimento"

info "Instalando Postman..."
install_flatpak com.getpostman.Postman
ok "Postman instalado!"

run_root tee "/usr/share/applications/freedownloadmanager.desktop" > /dev/null << EOF
[Desktop Entry]
Name=Free Download Manager
Exec=$APPS_DIR/FreeDownloadManager.AppImage
Icon=browser-download
Type=Application
Categories=Network;FileTransfer;
EOF
ok "Ícone do FDM adicionado ao menu!"

info "Instalando qBittorrent..."
install_pkg qbittorrent
ok "qBittorrent instalado!"

info "Instalando Draw.io..."
install_flatpak com.jgraph.drawio.desktop
ok "Draw.io instalado!"

info "Instalando Steam..."
install_flatpak com.valvesoftware.Steam
ok "Steam instalado!"

section "13/16 — Comunicação"

info "Instalando Discord..."
install_flatpak com.discordapp.Discord || true
ok "Discord instalado!"

section "14/16 — Navegadores"

info "Instalando Brave Browser Nightly..."
install_pkg brave-browser-nightly
ok "Brave Browser Nightly instalado!"
ok "Firefox já vem pré-instalado no Fedora"

section "15/16 — Multimídia"

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

section "16/16 — Nginx + Scripts Personalizados"

info "Instalando Nginx..."

install_pkg nginx

run_root systemctl enable --now nginx

ok "Nginx instalado e iniciado!"

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
echo "Destino: