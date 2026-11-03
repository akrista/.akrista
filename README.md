# 🛠️ .akrista: Cross-Platform Developer Environment & AI Toolbelt

Unified, cross-platform configuration hub and AI agent environment powering developer workflows across **Debian/Ubuntu Linux**, **Android (Termux)**, and **Windows**.

---

## ⚡ Quick Installation

A single polyglot installer (`install.ps1`) automatically bootstraps runtimes, packages, fonts, symlinks, and AI agent skills across operating systems:

### Linux / Termux (Bash)
```bash
curl -fsSL https://raw.githubusercontent.com/akrista/.akrista/master/install.ps1 | bash
```

### Windows (PowerShell)
```powershell
irm https://raw.githubusercontent.com/akrista/.akrista/master/install.ps1 | iex
```

---

## 🏛️ Repository Architecture

```
~/.akrista/
├── config/                      # Traditional tools & shell configurations
│   ├── alacritty/               # Terminal emulator (MesloLGS NF, Monokai Pro / Gruvbox)
│   ├── bash/                    # 1:1 synchronized .bashrc with Zsh
│   ├── docker/                  # daemon.json log-rotation and live-restore
│   ├── enhancer-for-youtube/    # Custom browser player settings & theme
│   ├── env/                     # .env.local machine-specific environment overrides
│   ├── ghostty/                 # Ghostty terminal configuration
│   ├── git/                     # Base .gitconfig + .gitconfig.local
│   ├── mise/                    # Mise polyglot tool version manager config.toml
│   ├── omp/                     # Oh My Posh lambdageneration theme
│   ├── oxker/                   # Docker/Podman TUI container manager
│   ├── sqlite/                  # .sqliterc prompt & column formatting
│   ├── ssh/                     # Modular OpenSSH Include configuration + config.local
│   ├── sshd/                    # 99-hardening.conf server daemon security
│   ├── termux/                  # Android Termux customizations
│   ├── tmux/                    # .tmux.conf + TPM plugins
│   ├── zed/                     # Zed Editor settings.json template & MCP servers
│   ├── zellij/                  # Zellij terminal workspace multiplexer
│   └── zsh/                     # .zshrc, .zshenv, aliases, prompt, functions (uak)
│
├── slop/                        # Dedicated AI Agent Toolbelt & Skills Hub
│   ├── claude/                  # Claude Code settings (settings.json)
│   ├── opencode/                # OpenCode configuration (opencode.json, opencode.global.dat, tui.json, themes/)
│   ├── maga/                    # Multi-agent harness MCP & plugin manager (config.toml)
│   ├── skills/                  # 🛠️ Handmade custom skills, one flat folder per skill (Tracked in Git)
│   ├── guidelines/
│   │   └── AGENTS.md            # 🧭 Single global guideline file, symlinked into every tool
│   ├── agy/                     # Antigravity CLI configuration (config.json, hooks.json)
│   ├── pi/                      # Pi Coding Agent configurations
│   └── skills-lock.json         # 🔒 Skills lockfile for custom and community skills
│
└── install.ps1                  # Polyglot Bash/PowerShell cross-platform automated installer
```

---

## 🔒 The Centralized Symlink Template Pattern

To prevent private credentials (API keys, SSH hosts, proxy URLs, database connection strings) from being tracked by Git while keeping everything organized in a single repository:

1. **Templates in Git**: Clean `.example` files (`settings.json.example`, `.env.local.example`, `config.local.example`, `opencode.json.example`, `config.json.example`, `hooks.json.example`) are tracked in Git.
2. **Local Active Files**: Real working files (`settings.json`, `.env.local`, `config.local`, `opencode.json`, `opencode.global.dat`, `config.json`, `hooks.json`) live directly inside `.akrista/config/` and `.akrista/slop/` but are **ignored by `.gitignore`**.
3. **OS Symlinks**: System target paths (`~/.config/zed/settings.json`, `~/.config/maga/config.toml`, `~/.config/opencode/opencode.json`, `~/.config/opencode/tui.json`, `~/.config/opencode/themes`, `~/.claude/settings.json`, `~/.gemini/config/config.json`, `~/.gemini/config/hooks.json`, `~/.env.local`, `~/.ssh/config.local`) are symlinked directly to their centralized `.akrista` paths.

---

## 🤖 AI Agent Toolbelt (`slop/`)

The `slop/` module centralizes configurations for terminal-native and autonomous AI coding agents:

* **Claude Code (`slop/claude/`)**: Configured with custom marketplaces (`wakatime`, `ponytail`, `last30days-skill`), an optional custom `ANTHROPIC_BASE_URL` proxy, and dark fullscreen TUI.
* **OpenCode (`slop/opencode/`)**: Configured with the gruvbox-transparent theme (`themes/`, selected in `tui.json`) and custom provider options.
* **Maga (`slop/maga/`)**: General TUI and harness sync configuration (`config.toml`) for `maga`, which centrally manages MCP servers (`mcp.toml`) and plugins (`plugins.toml`) across Antigravity, Claude Code, Copilot, Grok, and OpenCode.
* **Pi Coding Agent (`slop/pi/`)**: Terminal-native coding agent configurations.
* **Antigravity CLI (`slop/agy/`)**: Configured with user settings (`config.json`) and safe lifecycle hooks (`hooks.json`).

---

## 🧠 Agent Skills Architecture

There is a single mechanism for every skill, custom or community: the [`skills`](https://skills.sh) CLI and `slop/skills-lock.json`. There is no separate hand-symlinked path for skills you wrote yourself.

1. **Custom Skills (`slop/skills/<skill-name>/`)**:
   Your own hand-authored skills, tracked directly in Git as a flat `SKILL.md` folder per skill (e.g. `slop/skills/tsql-development/`). They're registered in `slop/skills-lock.json` exactly like a community skill, just sourced from this repo itself (`source: "Akrista/.akrista"`) instead of someone else's.
2. **Community Skills**:
   `~/skills-lock.json` is symlinked to `~/.akrista/slop/skills-lock.json`. To add a new skill globally across all agents:
   ```bash
   cd ~ && bunx skills add <author/repo>
   ```
   To add one of this repo's own custom skills into an unrelated project:
   ```bash
   bunx skills add Akrista/.akrista -s <skill-name> -a <agent>
   ```
   Installed skills are locked in `slop/skills-lock.json`.
3. **Universal Deployment**:
   `install.ps1` runs `bunx skills experimental_install`, which restores every locked skill (custom and community alike) to:
   * **Universal Agent Skills**: `~/.agents/skills/` (read by Antigravity, OpenCode, Codex, Cursor)
   * **Claude Code Skills**: `~/.claude/skills/`

The canonical `slop/guidelines/AGENTS.md` is linked into each agent's documented global
instruction location. For GitHub Copilot CLI, that location is
`~/.copilot/copilot-instructions.md`; the legacy `~/.copilot/AGENTS.md` link is retained
for compatibility.
