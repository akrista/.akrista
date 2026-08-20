# .akrista — Project Conventions

This repo is **public** on GitHub (`akrista/.akrista`). Every commit is a public disclosure — check before staging.

## Secrets & templates

- `.example` files are tracked; the real files they template (`settings.json`, `.claude.json`, `opencode.json`, `config.json`, `mcp_config.json`, `.env.local`, `*.local`) are gitignored. Never copy real values into an `.example` file — use `<PLACEHOLDER>` or `${ENV_VAR}`, matching the surrounding file's existing style.
- Before committing anything under `slop/` or `config/`, grep the diff for API key formats, `user:pass@host` connection strings, real IPs, and personal domains. This repo has already had real credentials (a SQL Server `sa` password, live API keys) mistakenly pasted into tracked templates — it happens easily, check every time.

## Skills

- Custom skills live flat at `slop/skills/<name>/SKILL.md` — no nesting, no separate "custom" folder.
- All skills (custom and community) are tracked in `slop/skills-lock.json` and restored via `bunx skills experimental_install`. There is no direct-symlink install step for custom skills — if you're tempted to add one to `install.ps1`, register the skill in the lock file instead (`source: "Akrista/.akrista"` for this repo's own skills).

## Guidelines

- `slop/guidelines/AGENTS.md` is the single global instructions file, symlinked into Claude Code (`~/.claude/CLAUDE.md`), OpenCode, Antigravity, and Pi. Edit it there, not per-tool — the symlinks propagate automatically.

## Committing

- This repo often has several unrelated pending changes at once (config edits, in-progress rewrites). Stage precisely (`git add <specific paths>`), never `git add -A`/`git commit -a` unless you've checked `git status` first and mean to include everything.
