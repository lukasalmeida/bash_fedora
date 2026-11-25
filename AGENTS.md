# AGENTS.md

Fedora workstation provisioning (Portuguese-language repo). No build, test, lint, CI, or codegen tooling exists.

## Communication

- Always respond to the user in Brazilian Portuguese (`pt-BR`).

## Architecture

- `setup_fedora.sh` is an orchestrator: it `source`s every `scripts/*.sh` in glob (numeric) order and calls a `run_stage` function from each module. It does **not** execute modules as separate processes.
- Modules are sourced, so they inherit orchestrator-provided helpers: `section`, `ok`, `info`, `warn`, `err`, `run_root`, `install_pkg`, `install_flatpak`. Running a module standalone fails — verify syntax instead: `bash -n scripts/*.sh setup_fedora.sh` (no shellcheck config; use it only if installed).
- `scripts/00-validar-prerequisitos.sh` sets shared state used by later modules: `REAL_USER`, `HOME_DIR`, `APPS_DIR`. Keep it as `00-`; modules `02`–`09` depend on those variables.

## Module contract

- Every `scripts/NN-*.sh` must define `run_stage`. A bad `source` or missing function only logs a warning and is counted in the final summary — the run continues either way.
- Error handling is intentionally `set +e` + `set -o pipefail` + an ERR trap: failing commands warn and continue; `run_stage` returning non-zero marks the stage failed without stopping the run. (README's claim of `set -eo pipefail` aborting on first error is stale — trust the code.)
- Naming: zero-padded `NN-verbo-substantivo.sh` (Portuguese verb-noun, e.g. `13-instalar-ferramenta.sh`); the numeric prefix is the execution order.
- Must run as a normal user, never root/sudo (stage `00` rejects root and validates sudo).
- All user-facing output is in Portuguese; match it when adding or editing stages.
- Stage headers like `section "3/12 — Git e SSH"` are manually numbered and stale (13 modules now). Ignore the counters; don't treat them as truth.

## Conventions & gotchas

- Keep stages idempotent: guard with `[[ ! -f ... ]]`, `command -v`, or `rpm -q` checks so re-runs skip completed work (see `09-instalar-ides.sh`, `01-atualizar-sistema.sh`).
- Stage `02` **overwrites** `~/.zshrc` each run; stages `04`/`05` re-append their env blocks afterward with `grep` guards. Any new stage that edits rc files must be numbered after `02` and use guarded appends.
- nvm/node state is not in the current shell: stages must spawn `bash -c 'source "$NVM_DIR/nvm.sh" && ...'` (see `04-instalar-node.sh`).
- Global helper commands (`adddominio`, `atualizar`, `temp`) are installed by writing files to `/usr/local/bin` from `12-instalar-utilitarios.sh`.
- `exports/` and `icones/` are backup assets (Konsole profiles, icon); no script references them.

## README caveats (verified against code)

- There is no `SSH_EMAIL` variable; the SSH comment is hardcoded as `seuemail@gmail.com` in `scripts/03-configurar-git-ssh.sh`.
- README's structure section omits `scripts/` entirely.

## Git

- Base development branch is `dev` (tracks `origin/dev`).
- All modifications originate from an issue. Create a dedicated branch from `dev` using `<type>/<issue-number>-<description-up-to-5-words>` in kebab-case (e.g., `feat/14-adicionar-instalacao-docker`, `fix/22-corrigir-permissao-zshrc`).
- Format commit messages as `<type>/<change-description>` (e.g., `feat/adicionar modulo de instalacao docker`, `fix/proteger append no zshrc`).
- Split commits by necessity and single responsibility — never bundle unrelated changes into a single commit when they can be isolated cleanly.