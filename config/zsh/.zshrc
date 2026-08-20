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

# --- Zsh Options & Variables ---
HISTFILE=~/.zsh_history
HISTDUP=erase
HISTSIZE=5000
SAVEHIST=10000

# Modern Zsh history options
setopt SHARE_HISTORY          # Share history between all sessions
setopt INC_APPEND_HISTORY     # Write to history file immediately, not just when logout
setopt HIST_IGNORE_ALL_DUPS   # Erase old duplicate command if new one is typed
setopt HIST_IGNORE_SPACE      # Don't record an entry starting with a space
setopt HIST_SAVE_NO_DUPS      # Don't write duplicate entries to history file
setopt HIST_REDUCE_BLANKS     # Remove superfluous blanks before recording entry

# Native Zsh directory navigation options
setopt AUTO_CD                # Go to directory by just entering its name
setopt AUTO_PUSHD             # Make cd push the old directory onto the directory stack
setopt PUSHD_IGNORE_DUPS      # Don't push duplicate directories onto stack
setopt PUSHD_SILENT           # Do not print the directory stack after pushd or popd

export VISUAL=nvim
export EDITOR="$VISUAL"
export COMPOSE_BAKE=true

# --- Oh My Zsh Setup ---
# If you come from bash you might have to change your $PATH.
# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"
# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time
# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 30

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
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

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# --- Load Custom Modular Settings ---

# Load helper functions
if [ -f "$ZDOTDIR/.zsh_functions" ]; then
  source "$ZDOTDIR/.zsh_functions"
fi

# Load aliases
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
