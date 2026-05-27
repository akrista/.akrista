# Akrista's DotFiles

Personal configuration files for terminal emulators and development tools.

## Installation

You can install the tools and configure your environment by running the polyglot installer script with a single command:

### Linux / Termux (Bash)

Run the following command to identify your OS/package manager and install Oh My Zsh & Oh My Posh:

```bash
curl -fsSL https://raw.githubusercontent.com/akrista/.akrista/master/install.ps1 | bash
```

### Windows (PowerShell)

Run the following command in an elevated PowerShell session to install Oh My Posh using `winget`:

```powershell
irm https://raw.githubusercontent.com/akrista/.akrista/master/install.ps1 | iex
```

## Files

### `.sqliterc`
SQLite configuration file with default settings for the SQLite CLI:
- Enables column headers in output
- Shows query execution timing
- Sets table display mode

### `alacritty/alacritty.toml`
Alacritty terminal emulator configuration featuring:
- Custom opacity (0.9) with no window decorations
- MesloLGS NF font family at 16pt
- Monokai Pro Ristretto color scheme
- PowerShell as default shell
- Large scrollback buffer (100,000 lines)
- Custom keybindings (Ctrl+F to toggle fullscreen)

### `wezterm/.wezterm.lua`
WezTerm terminal configuration with:
- Cross-platform shell support (PowerShell on Windows, Zsh on Unix)
- OpenGL rendering at 144 FPS
- Dual-layered background with Psychopomp game assets (random hue variation)
- MonokaiProRistretto color scheme
- MesloLGS NF font at 16pt
- Custom pane splitting and resizing keybindings
- Opacity toggle (Ctrl+Alt+O)

### `zellij/config.kdl`
Zellij terminal multiplexer configuration with:
- Tmux-style keybindings with custom modal navigation
- Gruvbox Dark theme
- PowerShell as default shell
- Custom keybinds for pane/tab management, resizing, and movement
- Plugin configuration (about, compact-bar, session-manager, etc.)
- Vim-style navigation (hjkl)

## Credits

- introPsyWorry.png and introPsyWorry2.png are assets from [Psychopomp](https://store.steampowered.com/app/2771670/Psychopomp/)
- [nvim-lite](https://github.com/radleylewis/nvim-lite)