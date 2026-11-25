# 🐧 Fedora Setup — Lucas

Script de configuração automática para reinstalação do Fedora Linux.

Executa uma única vez e instala todo o ambiente de desenvolvimento, banco de dados, ferramentas, multimídia e utilitários necessários para o dia a dia.

---

## ⚡ Como usar

```bash
# Clone o repositório
git clone https://github.com/lukasalmeida/bash_fedora.git

cd bash_fedora

# Execute como usuário normal (o script solicitará sudo quando necessário)
# Na etapa de Git/SSH, informe o e-mail que será usado como comentário da chave
bash setup_fedora.sh
```

> Tempo estimado: **20–40 minutos**, dependendo da velocidade da internet.

## Arquitetura das etapas

`setup_fedora.sh` funciona como orquestrador e executa, em ordem alfabética, todos os módulos `.sh` do diretório `scripts/`. Cada módulo deve declarar uma função `run_stage`.

Para adicionar ou remover funcionalidades, crie ou remova um módulo seguindo o padrão `NN-verbo-substantivo.sh`, por exemplo `13-instalar-ferramenta.sh`. Se uma etapa falhar, o erro é registrado e o orquestrador continua para o próximo módulo.

---

# 📦 O que é instalado

## 🖥️ IDEs & Editores

| Aplicação               | Método                        |
| ----------------------- | ----------------------------- |
| VS Code                 | Repositório oficial Microsoft |
| IntelliJ IDEA Community | Flatpak (Flathub)             |
| PyCharm Community       | Flatpak (Flathub)             |

---

## 🛠️ Ferramentas de Desenvolvimento

| Aplicação             | Método                 |
| --------------------- | ---------------------- |
| Docker Desktop        | RPM oficial            |
| kubectl               | Repositório Kubernetes |
| OpenCode              | npm global             |
| GitHub Copilot CLI    | npm global             |
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
| btop       | Monitor de processos     |
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
├── setup_fedora.sh
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

* [ ] Abrir o Docker Desktop pela primeira vez
* [ ] Reiniciar o sistema

---

# 📝 Observações

* O script utiliza `set -eo pipefail`, interrompendo a execução ao primeiro erro e propagando falhas em pipelines.
* Free Download Manager é instalado em:

```bash
~/Applications
```

* VLC tenta instalação via DNF e utiliza Flatpak como alternativa.
* PostgreSQL é iniciado automaticamente após a instalação.
* Nginx é iniciado automaticamente após a instalação.
* PGAdmin 4 é instalado via Flatpak.

---

# 🧪 Testado em

![Fedora](https://img.shields.io/badge/Fedora-44-blue?logo=fedora)
![Linux](https://img.shields.io/badge/Linux-x86__64-lightgrey)
