# 🛠️ .akrista — Cross-Platform Developer Environment & AI Toolbelt

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
│   ├── workmux/                 # Workmux git worktree + tmux orchestrator config
│   ├── zed/                     # Zed Editor settings.json template & MCP servers
│   ├── zellij/                  # Zellij terminal workspace multiplexer
│   └── zsh/                     # .zshrc, .zshenv, aliases, prompt, functions (uak)
│
├── slop/                        # Dedicated AI Agent Toolbelt & Skills Hub
│   ├── claude/                  # Claude Code settings & profile (settings.json, .claude.json)
│   ├── opencode/                # OpenCode configuration (opencode.json, opencode.global.dat)
│   ├── mcp/                     # Shared MCP catalog & server definitions (servers.json.example)
│   ├── skills/                  # 🛠️ Handmade custom skills, one flat folder per skill (Tracked in Git)
│   ├── guidelines/
│   │   └── AGENTS.md            # 🧭 Single global guideline file, symlinked into every tool
│   ├── agy/                     # Antigravity CLI configuration (config.json, mcp_config.json)
│   ├── pi/                      # Pi Coding Agent configurations
│   └── skills-lock.json         # 🔒 Skills lockfile — custom AND community skills alike
│
└── install.ps1                  # Polyglot Bash/PowerShell cross-platform automated installer
```

---

## 🔒 The Centralized Symlink Template Pattern

To prevent private credentials (API keys, SSH hosts, proxy URLs, database connection strings) from being tracked by Git while keeping everything organized in a single repository:

1. **Templates in Git**: Clean `.example` files (`settings.json.example`, `.claude.json.example`, `.env.local.example`, `config.local.example`, `opencode.json.example`, `servers.json.example`, `config.json.example`, `mcp_config.json.example`, `hooks.json.example`) are tracked in Git.
2. **Local Active Files**: Real working files (`settings.json`, `.claude.json`, `.env.local`, `config.local`, `opencode.json`, `opencode.global.dat`, `config.json`, `mcp_config.json`, `hooks.json`) live directly inside `.akrista/config/` and `.akrista/slop/` but are **ignored by `.gitignore`**.
3. **OS Symlinks**: System target paths (`~/.config/zed/settings.json`, `~/.config/opencode/opencode.json`, `~/.claude/settings.json`, `~/.claude.json`, `~/.gemini/config/config.json`, `~/.gemini/config/mcp_config.json`, `~/.gemini/config/hooks.json`, `~/.env.local`, `~/.ssh/config.local`) are symlinked directly to their centralized `.akrista` paths.

---

## 🤖 AI Agent Toolbelt (`slop/`)

The `slop/` module centralizes configurations for terminal-native and autonomous AI coding agents:

* **Claude Code (`slop/claude/`)**: Configured with custom marketplaces (`wakatime`, `ponytail`, `last30days-skill`), enabled plugins, an optional custom `ANTHROPIC_BASE_URL` proxy, and dark fullscreen TUI.
* **OpenCode (`slop/opencode/`)**: Configured with active plugins (`opencode-wakatime`, `@tarquinen/opencode-dcp`, `@dietrichgebert/ponytail`) and local/remote MCP definitions.
* **Shared MCP Catalog (`slop/mcp/`)**: Reference catalog for stdio/SSE servers (Context7, DBHub, Astro, Svelte, Shadcn, NextJs, Metabase, Stitch).
* **Pi Coding Agent (`slop/pi/`)**: Terminal-native coding agent configurations.
* **Antigravity CLI (`slop/agy/`)**: Configured with user settings (`config.json`), global MCP definitions (`mcp_config.json`), and safe lifecycle hooks (`hooks.json`).

---

## 🧠 Agent Skills Architecture

There is a single mechanism for every skill, custom or community — the [`skills`](https://skills.sh) CLI and `slop/skills-lock.json`. There is no separate hand-symlinked path for skills you wrote yourself.

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
   `install.ps1` runs `bunx skills experimental_install`, which restores every locked skill — custom and community alike — to:
   * **Universal Agent Skills**: `~/.agents/skills/` (read by Antigravity, OpenCode, Codex, Cursor)
   * **Claude Code Skills**: `~/.claude/skills/`
