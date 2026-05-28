if [ -d "/home/linuxbrew/.linuxbrew" ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

export PATH="$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/.opencode/bin:$PATH"
export NVM_DIR="$HOME/.nvm"

HISTFILE=~/.zsh_history
HISTDUP=erase
HISTSIZE=5000
SAVEHIST=10000

export VISUAL=nvim
export EDITOR="$VISUAL"
export COMPOSE_BAKE=true

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
# zstyle ':omz:update' mode disabled  # disable automatic updates
zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time
# Uncomment the following line to change how often to auto-update (in days).
zstyle ':omz:update' frequency 30

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

source $ZSH/oh-my-zsh.sh

# User configuration


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
alias cat='bat'
alias ls='eza'

# autoload -Uz compinit && compinit
# zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
# zstyle :compinstall filename '/home/akrista/.zshrc'
# zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
# zstyle ':completion:*' menu no
# End of lines added by compinstall

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
  eval "$(zoxide init zsh --cmd cd)"
fi

if [ -s "$NVM_DIR/nvm.sh" ]; then
  source "$NVM_DIR/nvm.sh"
fi
if [ -s "$NVM_DIR/bash_completion" ]; then
  source "$NVM_DIR/bash_completion"
fi

if [ -s "$HOME/.bun/_bun" ]; then
  source "$HOME/.bun/_bun"
fi

if [ "$TERM_PROGRAM" != "Apple_Terminal" ] && command -v oh-my-posh >/dev/null 2>&1; then
  eval "$(oh-my-posh init zsh --config $HOME/.akrista/lambdageneration.omp.json)"
fi

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

_check_update() {
  local doc_dir="$HOME/.akrista"
  [[ -d "$doc_dir/.git" ]] || return

  local check_file="$doc_dir/.last_update_check"
  local need_fetch=0
  if [[ ! -f "$check_file" ]]; then
    need_fetch=1
  else
    local old_files=( "$check_file"(mh+24N) )
    if [[ -n "$old_files" ]]; then
      need_fetch=1
    fi
  fi

  if (( need_fetch )); then
    touch "$check_file" 2>/dev/null
    (cd "$doc_dir" && git fetch -q) >/dev/null 2>&1 &!
  fi

  if command -v git >/dev/null 2>&1; then
    local upstream=$(git -C "$doc_dir" rev-parse --abbrev-ref @{u} 2>/dev/null)
    if [[ -n "$upstream" ]]; then
      local local_commit=$(git -C "$doc_dir" rev-parse @ 2>/dev/null)
      local remote_commit=$(git -C "$doc_dir" rev-parse @{u} 2>/dev/null)
      if [[ "$local_commit" != "$remote_commit" ]]; then
        local base_commit=$(git -C "$doc_dir" merge-base @ @{u} 2>/dev/null)
        if [[ "$local_commit" = "$base_commit" ]]; then
          printf "\n\e[1;33m[!] An update is available for the .akrista repository!\e[0m\n"
          printf "    Run \e[1;32mupdate-akrista\e[0m to apply the updates.\n\n"
        fi
      fi
    fi
  fi
}
_check_update

update-akrista() {
  local doc_dir="$HOME/.akrista"
  if [[ -d "$doc_dir" ]]; then
    echo "Updating .akrista repository..."
    git -C "$doc_dir" pull
    
    if [[ -f "$doc_dir/install.ps1" ]]; then
      echo "Running installer..."
      bash "$doc_dir/install.ps1" "$@"
    else
      echo "Error: install.ps1 not found in $doc_dir"
      return 1
    fi
  else
    echo "Error: .akrista directory not found at $doc_dir"
    return 1
  fi
}