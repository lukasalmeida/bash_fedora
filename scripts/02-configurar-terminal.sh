#!/bin/bash

run_stage() {
    section "2/12 — Ferramentas de terminal"
    run_root dnf copr enable -y atim/starship
    local packages="zsh htop tree fzf bat ripgrep jq starship"
    if dnf info fastfetch >/dev/null 2>&1; then
        packages="$packages fastfetch"
    else
        packages="$packages neofetch"
    fi
    install_pkg $packages

    cat > "$HOME_DIR/.zshrc" <<'EOF'
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
setopt HIST_EXPIRE_DUPS_FIRST HIST_IGNORE_DUPS HIST_IGNORE_ALL_DUPS HIST_FIND_NO_DUPS HIST_IGNORE_SPACE SHARE_HISTORY
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
    cat > "$HOME_DIR/.config/starship.toml" <<'EOF'
format = "$username$directory$git_branch$git_status$character"
[username]
show_always = true
[directory]
truncation_length = 3
[character]
success_symbol = '[❯](bold #ff8c00)'
error_symbol = '[❯](bold red)'
EOF
    run_root chsh -s "$(command -v zsh)" "$REAL_USER"
    ok "Terminal configurado"
}
