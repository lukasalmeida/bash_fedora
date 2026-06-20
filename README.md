# 🐧 Fedora Setup — Lucas

Script de configuração automática para reinstalação do Fedora Linux.

Executa uma única vez e instala todo o ambiente de desenvolvimento, banco de dados, ferramentas, multimídia e utilitários necessários para o dia a dia.

---

## ⚡ Como usar

```bash
# Clone o repositório
git clone https://github.com/lukasalmeida/bash_fedora.git

cd bash_fedora

# Edite seu email SSH no script
nano setup-fedora.sh

# Execute como root
sudo bash setup-fedora.sh
```

> Tempo estimado: **20–40 minutos**, dependendo da velocidade da internet.

---

# 📦 O que é instalado

## 🖥️ IDEs & Editores

| Aplicação         | Método                        |
| ----------------- | ----------------------------- |
| VS Code           | Repositório oficial Microsoft |
| Cursor            | Repositório oficial           |
| JetBrains Toolbox | Download oficial              |
| IntelliJ IDEA     | Via Toolbox                   |
| PyCharm           | Via Toolbox                   |
| DataGrip          | Flatpak                       |

---

## 🛠️ Ferramentas de Desenvolvimento

| Aplicação             | Método                 |
| --------------------- | ---------------------- |
| Docker Desktop        | RPM oficial            |
| kubectl               | Repositório Kubernetes |
| Postman               | Flatpak                |
| Draw.io               | Flatpak                |
| Free Download Manager | AppImage               |
| qBittorrent           | DNF                    |
| Steam                 | Flatpak                |

---

## 🔤 Linguagens & Runtime

| Tecnologia | Versão                   |
| ---------- | ------------------------ |
| Node.js    | LTS via NVM              |
| pnpm       | Global                   |
| yarn       | Global                   |
| TypeScript | Global                   |
| ts-node    | Global                   |
| Java       | OpenJDK 21               |
| Maven      | Última versão            |
| Python     | Python 3                 |
| pip        | Incluído                 |
| venv       | Incluído                 |
| PHP        | Última versão disponível |
| Composer   | Última versão            |

---

## 🗄️ Banco de Dados

| Aplicação  | Método  |
| ---------- | ------- |
| PostgreSQL | DNF     |
| PGAdmin 4  | Flatpak |

### PostgreSQL

O serviço é configurado automaticamente:

```bash
sudo -u postgres psql
```

---

## 🌐 Servidor Web

| Aplicação | Método |
| --------- | ------ |
| Nginx     | DNF    |

O Nginx é iniciado automaticamente:

```bash
sudo systemctl status nginx
```

---

## 🌍 Navegadores

| Aplicação             | Método               |
| --------------------- | -------------------- |
| Brave Browser Nightly | Repositório oficial  |
| Firefox               | Já incluso no Fedora |

---

## 💬 Comunicação

| Aplicação | Método  |
| --------- | ------- |
| Discord   | Flatpak |

---

## 🎵 Multimídia

| Aplicação  | Método         |
| ---------- | -------------- |
| Spotify    | Flatpak        |
| OBS Studio | Flatpak        |
| VLC        | DNF ou Flatpak |
| openh264   | DNF            |

---

## 💻 Terminal

| Ferramenta | Função                   |
| ---------- | ------------------------ |
| ZSH        | Shell padrão             |
| Oh My Zsh  | Framework ZSH            |
| htop       | Monitor de processos     |
| neofetch   | Informações do sistema   |
| bat        | Cat com syntax highlight |
| tree       | Estrutura de diretórios  |
| fzf        | Busca fuzzy              |
| ripgrep    | Busca rápida             |
| jq         | Manipulação JSON         |

---

# 🔧 Repositórios Configurados

* Brave Browser Nightly
* Visual Studio Code
* Cursor
* Docker
* Kubernetes
* Flathub

---

# ⚙️ Scripts Personalizados

Após a instalação ficam disponíveis globalmente:

## adddominio

Cria domínios locais automaticamente no Nginx.

```bash
adddominio
```

Exemplo:

```text
olezele.local
↓
http://127.0.0.1:3000
```

O script:

* Cria configuração Nginx
* Atualiza `/etc/hosts`
* Recarrega o Nginx automaticamente

---

## atualizar

Atualiza todo o sistema Fedora.

```bash
atualizar
```

---

## temp

Limpa a pasta:

```bash
~/Temp
```

Executando:

```bash
temp
```

---

# 📂 Estrutura

```text
bash_fedora/
├── setup-fedora.sh
└── README.md
```

---

# ✅ Pós-instalação

Após a execução do script:

* [ ] Adicionar a chave SSH no GitHub
* [ ] Configurar nome do Git

```bash
git config --global user.name "Lucas"
git config --global user.email "seuemail@gmail.com"
```

* [ ] Abrir o JetBrains Toolbox
* [ ] Instalar IntelliJ IDEA
* [ ] Instalar PyCharm
* [ ] Abrir o Docker Desktop pela primeira vez
* [ ] Reiniciar o sistema

---

# 📝 Observações

* O script utiliza `set -e`, interrompendo a execução ao primeiro erro.
* Free Download Manager é instalado em:

```bash
~/Applications
```

* Cursor possui fallback automático para AppImage caso o repositório falhe.
* VLC tenta instalação via DNF e utiliza Flatpak como alternativa.
* PostgreSQL é iniciado automaticamente após a instalação.
* Nginx é iniciado automaticamente após a instalação.
* PGAdmin 4 é instalado via Flatpak.

---

# 🧪 Testado em

![Fedora](https://img.shields.io/badge/Fedora-44-blue?logo=fedora)
![Linux](https://img.shields.io/badge/Linux-x86__64-lightgrey)
