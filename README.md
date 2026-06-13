# 🐧 Fedora Setup — Lucas (LZL)

Script de configuração automática para reinstalação do Fedora Linux.
Executa uma vez e instala tudo que preciso para trabalhar.

---

## ⚡ Como usar

```bash
# 1. Clone o repositório
git clone git@github.com:seu-usuario/fedora-setup.git
cd fedora-setup

# 2. Edite seu email de SSH antes de rodar (linha SSH_EMAIL no script)
nano setup-fedora.sh

# 3. Execute como root
sudo bash setup-fedora.sh
```

> Tempo estimado: **20–40 minutos** dependendo da sua internet.

---

## 📦 O que é instalado

### 🖥️ IDEs & Editores
| App | Como |
|-----|------|
| VS Code | dnf (repo oficial) |
| Cursor | dnf (repo oficial) |
| IntelliJ IDEA | JetBrains Toolbox |
| PyCharm | JetBrains Toolbox |
| DataGrip | Flatpak |
| JetBrains Toolbox | tarball oficial |

### 🛠️ Ferramentas de Desenvolvimento
| App | Como |
|-----|------|
| Docker Desktop | RPM oficial |
| kubectl | dnf (repo k8s) |
| Postman | Flatpak |
| Draw\.io | Flatpak |
| FreeDownloadManager | AppImage (`~/Applications/`) |
| qBittorrent | dnf |
| Steam | Flatpak |

### 🔤 Linguagens & Runtime
| Linguagem | Versão | Extra |
|-----------|--------|-------|
| Node.js | LTS via NVM | pnpm, yarn, typescript, ts-node |
| Java | 21 (OpenJDK) | Maven |
| Python | 3 | pip, venv |
| PHP | última estável | Composer |

### 🗄️ Banco de Dados
| App | Como |
|-----|------|
| PostgreSQL | dnf + iniciado como serviço |

### 🌐 Navegadores
| App | Como |
|-----|------|
| Brave Browser Nightly | dnf (repo oficial) |
| Firefox | pré-instalado no Fedora |

### 💬 Comunicação
| App | Como |
|-----|------|
| Discord | Flatpak |

### 🎵 Multimídia
| App | Como |
|-----|------|
| Spotify | Flatpak |
| OBS Studio | Flatpak |
| VLC | dnf / Flatpak (fallback) |
| openh264 | dnf (repo Cisco) |

### 🖥️ Terminal
| App | Descrição |
|-----|-----------|
| ZSH + Oh My Zsh | Shell padrão |
| htop | Monitor de processos |
| neofetch | Info do sistema |
| bat | `cat` com syntax highlight |
| fzf | Busca fuzzy |
| ripgrep | Busca em arquivos |
| jq | Manipulação de JSON |
| tree | Visualização de diretórios |

---

## 🔧 Repositórios configurados

```
brave-browser-nightly   → Brave Browser Nightly
code                    → Visual Studio Code
cursor                  → Cursor
docker-ce-stable        → Docker CE / Docker Desktop
kubernetes              → kubectl
flathub                 → Apps Flatpak
```

---

## ✅ Pós-instalação (manual)

Algumas coisas precisam de interação após o script terminar:

- [ ] Adicionar `~/.ssh/id_ed25519.pub` no GitHub → Settings → SSH Keys
- [ ] Configurar nome e email no Git:
  ```bash
  git config --global user.name "Lucas"
  git config --global user.email "seuemail@gmail.com"
  ```
- [ ] Abrir o **JetBrains Toolbox** e instalar IntelliJ IDEA + PyCharm
- [ ] Abrir o **Docker Desktop** uma vez para completar a configuração
- [ ] **Reiniciar o sistema**

---

## 🗂️ Estrutura

```
fedora-setup/
└── setup-fedora.sh   # Script principal
└── README.md         # Este arquivo
```

---

## 📝 Observações

- **FreeDownloadManager** é instalado como AppImage em `~/Applications/`
- **VLC** tenta instalar via `dnf`; se falhar, usa Flatpak automaticamente
- **Docker Desktop** substitui o Docker CE — não instale os dois
- O script para imediatamente (`set -e`) se qualquer comando falhar

---

## ⚙️ Testado em

![Fedora](https://img.shields.io/badge/Fedora-44-blue?logo=fedora)
![Arch](https://img.shields.io/badge/arch-x86__64-lightgrey)