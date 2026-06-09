export ZSH_DISABLE_COMPFIX="true"

# Ensure UTF-8 locale if available
if locale -a 2>/dev/null | grep -qi "en_US.utf8"; then
  export LANG=en_US.UTF-8
  export LC_ALL=en_US.UTF-8
elif locale -a 2>/dev/null | grep -qi "C.utf8"; then
  export LANG=C.UTF-8
  export LC_ALL=C.UTF-8
fi

typeset -U path PATH

# Linuxbrew integration
if [ -d "/home/linuxbrew/.linuxbrew" ]; then
  [[ -n "$ZSH_STARTUP_DEBUG" ]] && declare -f _log_time >/dev/null && _log_time "Before Brew"
  if [ -z "$HOMEBREW_PREFIX" ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  fi
  [[ -n "$ZSH_STARTUP_DEBUG" ]] && declare -f _log_time >/dev/null && _log_time "After Brew"
fi

# Set up default paths
path=(
  $HOME/bin
  $HOME/.local/bin
  /usr/local/bin
  $path
)

# Bun Runtime paths
export BUN_INSTALL="$HOME/.bun"
path=($BUN_INSTALL/bin $path)

# Cargo, OpenCode, and Composer paths
path=($HOME/.cargo/bin $path)
path=($HOME/.opencode/bin $path)
path=($HOME/.composer/vendor/bin $path)

# Node Version Manager path
export NVM_DIR="$HOME/.nvm"
