# --- Startup Timing ---
if [[ -n "$ZSH_STARTUP_DEBUG" ]]; then
  zmodload zsh/datetime
  _startup_start_time=$EPOCHREALTIME
  _startup_last_time=$_startup_start_time
  _log_time() {
    local current_time=$EPOCHREALTIME
    printf "DEBUG: %-30s | +%.4fs | Total: %.4fs\n" "$1" "$(( current_time - _startup_last_time ))" "$(( current_time - _startup_start_time ))"
    _startup_last_time=$current_time
  }
  _log_time "ZSH Start"
fi

# Define path configurations
export DOTFILES="$HOME/.akrista"
export ZDOTDIR="$DOTFILES/config/zsh"

# Source early environment settings
if [ -f "$ZDOTDIR/.zshenv" ]; then
  source "$ZDOTDIR/.zshenv"
fi

# Options & Variables
HISTFILE=~/.zsh_history
HISTDUP=erase
HISTSIZE=5000
SAVEHIST=10000

setopt SHARE_HISTORY
setopt INC_APPEND_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_SAVE_NO_DUPS
setopt HIST_REDUCE_BLANKS

setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT

export VISUAL=nvim
export EDITOR="$VISUAL"
export COMPOSE_BAKE=true

# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
zstyle ':omz:update' mode disabled
DISABLE_UNTRACKED_FILES_DIRTY="true"
plugins=()

if [ -d "$HOME/.zsh/zsh-completions/src" ]; then
  fpath=("$HOME/.zsh/zsh-completions/src" $fpath)
fi

if [ -d "$HOME/.zsh/completions" ]; then
  fpath=("$HOME/.zsh/completions" $fpath)
fi

[[ -n "$ZSH_STARTUP_DEBUG" ]] && _log_time "Before Oh My Zsh"
source $ZSH/oh-my-zsh.sh
[[ -n "$ZSH_STARTUP_DEBUG" ]] && _log_time "After Oh My Zsh"

if [ -f "$ZDOTDIR/.zsh_functions" ]; then
  source "$ZDOTDIR/.zsh_functions"
fi

if [ -f "$ZDOTDIR/.zsh_aliases" ]; then
  source "$ZDOTDIR/.zsh_aliases"
fi

# --- Integrations & Add-ons ---

# Zoxide
if command -v zoxide >/dev/null 2>&1; then
  [[ -n "$ZSH_STARTUP_DEBUG" ]] && _log_time "Before Zoxide"
  eval "$(zoxide init zsh)"
  eval "$(zoxide init zsh --cmd cd)"
  [[ -n "$ZSH_STARTUP_DEBUG" ]] && _log_time "After Zoxide"
fi

# Bun
if [ -s "$HOME/.bun/_bun" ]; then
  source "$HOME/.bun/_bun"
fi

# Load prompt settings
if [ -f "$ZDOTDIR/.zsh_prompt" ]; then
  source "$ZDOTDIR/.zsh_prompt"
fi


# Autosuggestions & Syntax Highlighting
SYS_PREFIX="${PREFIX:-/usr}"

if [ -f "$SYS_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
  source "$SYS_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
elif [ -f "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
  source "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

if [ -f "$SYS_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
  source "$SYS_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
elif [ -f "$HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
  source "$HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

# Trigger repository update check
if declare -f _check_update >/dev/null; then
  _check_update
fi



# Fast Node Manager (fnm)
if command -v fnm >/dev/null 2>&1; then
  eval "$(fnm env --use-on-cd)"
fi

# Deno
if [ -s "$HOME/.deno/env" ]; then
  . "$HOME/.deno/env"
fi

# Lerd
if [ -d "$HOME/.local/share/lerd/bin" ]; then
  export PATH="$HOME/.local/share/lerd/bin:$PATH"
fi

if [ -d "$HOME/.local/share/zsh/site-functions" ]; then
  fpath=("$HOME/.local/share/zsh/site-functions" $fpath)
fi
autoload -Uz compinit && compinit
