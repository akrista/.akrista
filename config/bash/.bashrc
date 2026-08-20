# ==============================================================================
#  🐚 Interactive Bash Shell Configuration (.bashrc)
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. Non-Interactive Guard & Terminal Options
# ------------------------------------------------------------------------------
case $- in
    *i*) ;;
      *) return;;
esac

# History options
HISTCONTROL=ignoreboth:erasedups
shopt -s histappend
HISTSIZE=5000
HISTFILESIZE=10000

# Window size & navigation
shopt -s checkwinsize
shopt -s autocd 2>/dev/null || true

# ------------------------------------------------------------------------------
# 2. Core Environment Variables & Default Editors
# ------------------------------------------------------------------------------
export DOTFILES="$HOME/.akrista"
export VISUAL=nvim
export EDITOR="$VISUAL"
export COMPOSE_BAKE=true

# Ensure UTF-8 locale if available
if locale -a 2>/dev/null | grep -qi "en_US.utf8"; then
  export LANG=en_US.UTF-8
  export LC_ALL=en_US.UTF-8
elif locale -a 2>/dev/null | grep -qi "C.utf8"; then
  export LANG=C.UTF-8
  export LC_ALL=C.UTF-8
fi

# ------------------------------------------------------------------------------
# 3. Path Configurations & Runtimes
# ------------------------------------------------------------------------------

# Homebrew / Linuxbrew
if [ -d "/home/linuxbrew/.linuxbrew" ]; then
  if [ -z "$HOMEBREW_PREFIX" ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  fi
fi

# Source machine-specific local environment if present
if [ -f "$HOME/.env.local" ]; then
  source "$HOME/.env.local"
fi

# Go binary path
[ -d "/usr/local/go/bin" ] && export PATH="/usr/local/go/bin:$PATH"
if command -v go >/dev/null 2>&1; then
  export PATH="$(go env GOPATH)/bin:$PATH"
fi

# Standard & local paths
export PATH="$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH"

# Bun Runtime
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun" 2>/dev/null || true

# Fast Node Manager (fnm)
export PATH="$HOME/.local/share/fnm:$PATH"
if command -v fnm >/dev/null 2>&1; then
  eval "$(fnm env --use-on-cd)"
fi

# Rust / Cargo
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
export PATH="$HOME/.cargo/bin:$PATH"

# OpenCode & Composer
[ -d "$HOME/.opencode/bin" ] && export PATH="$HOME/.opencode/bin:$PATH"
[ -d "$HOME/.composer/vendor/bin" ] && export PATH="$HOME/.composer/vendor/bin:$PATH"

# Lerd
[ -d "$HOME/.local/share/lerd/bin" ] && export PATH="$HOME/.local/share/lerd/bin:$PATH"

# Deno
[ -s "$HOME/.deno/env" ] && . "$HOME/.deno/env"

# ------------------------------------------------------------------------------
# 4. Programmable Shell Completions
# ------------------------------------------------------------------------------
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

if [ -f "$HOME/.local/share/bash-completion/completions/deno.bash" ]; then
  source "$HOME/.local/share/bash-completion/completions/deno.bash"
fi

# ------------------------------------------------------------------------------
# 5. Integrations (Zoxide)
# ------------------------------------------------------------------------------
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init bash)"
  eval "$(zoxide init bash --cmd cd)"
fi

# ------------------------------------------------------------------------------
# 6. Shared Aliases & Helpers
# ------------------------------------------------------------------------------
if [ -f "$DOTFILES/config/zsh/.zsh_aliases" ]; then
  source "$DOTFILES/config/zsh/.zsh_aliases"
fi

if [ -f "$HOME/.bash_aliases" ]; then
  . "$HOME/.bash_aliases"
fi

alias ubash="source ~/.bashrc"
alias ebash="nvim ~/.bashrc"

# ------------------------------------------------------------------------------
# 7. Updater & Utility Functions
# ------------------------------------------------------------------------------
# Update the .akrista repository and run installer
uak() {
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

# Log in to a proot-distro container in isolated mode
pdl() {
  local user="${1:-akrista}"
  local distro="${2:-debian}"

  if [[ "$user" == "-h" || "$user" == "--help" ]]; then
    echo "Usage: pdl [user] [distro]"
    echo "Log in to a proot-distro container in isolated mode."
    echo "Defaults: user=akrista, distro=debian"
    return 0
  fi

  echo "Logging into '$distro' as user '$user' (isolated)..."
  proot-distro login --isolated --user "$user" "$distro"
}

# Check for repository updates periodically (24h rate limit)
_check_update() {
  local doc_dir="$HOME/.akrista"
  [[ -d "$doc_dir/.git" ]] || return

  local check_file="$doc_dir/.last_update_check"
  local need_fetch=0
  if [[ ! -f "$check_file" ]]; then
    need_fetch=1
  elif [ -n "$(find "$check_file" -mmin +1440 2>/dev/null)" ]; then
    need_fetch=1
  fi

  if [ "$need_fetch" -eq 1 ]; then
    touch "$check_file" 2>/dev/null
    (cd "$doc_dir" && git fetch -q) >/dev/null 2>&1 &
  fi

  if command -v git >/dev/null 2>&1; then
    local upstream
    upstream=$(git -C "$doc_dir" rev-parse --abbrev-ref @{u} 2>/dev/null)
    if [[ -n "$upstream" ]]; then
      local local_commit remote_commit base_commit
      local_commit=$(git -C "$doc_dir" rev-parse @ 2>/dev/null)
      remote_commit=$(git -C "$doc_dir" rev-parse @{u} 2>/dev/null)
      if [[ "$local_commit" != "$remote_commit" ]]; then
        base_commit=$(git -C "$doc_dir" merge-base @ @{u} 2>/dev/null)
        if [[ "$local_commit" = "$base_commit" ]]; then
          printf "\n\033[1;33m[!] An update is available for the .akrista repository!\033[0m\n"
          printf "    Run \033[1;32muak\033[0m to apply the updates.\n\n"
        fi
      fi
    fi
  fi
}

# Run background update check
_check_update

# ------------------------------------------------------------------------------
# 8. Shell Prompt (Oh My Posh with fallback)
# ------------------------------------------------------------------------------
if [ "$TERM_PROGRAM" != "Apple_Terminal" ] && command -v oh-my-posh >/dev/null 2>&1; then
  OMP_CONFIG="$DOTFILES/config/omp/lambdageneration.omp.json"
  if [ -f "$OMP_CONFIG" ]; then
    eval "$(oh-my-posh init bash --config "$OMP_CONFIG")"
  else
    eval "$(oh-my-posh init bash)"
  fi
else
  PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
fi
