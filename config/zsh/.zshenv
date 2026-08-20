export ZSH_DISABLE_COMPFIX="true"

if locale -a 2>/dev/null | grep -qi "en_US.utf8"; then
  export LANG=en_US.UTF-8
  export LC_ALL=en_US.UTF-8
elif locale -a 2>/dev/null | grep -qi "C.utf8"; then
  export LANG=C.UTF-8
  export LC_ALL=C.UTF-8
fi

typeset -U path PATH

if [ -d "/home/linuxbrew/.linuxbrew" ]; then
  [[ -n "$ZSH_STARTUP_DEBUG" ]] && declare -f _log_time >/dev/null && _log_time "Before Brew"
  if [ -z "$HOMEBREW_PREFIX" ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  fi
  [[ -n "$ZSH_STARTUP_DEBUG" ]] && declare -f _log_time >/dev/null && _log_time "After Brew"
fi

if [ -f "$HOME/.env.local" ]; then
  source "$HOME/.env.local"
fi

path=(/usr/local/go/bin $path)
if command -v go >/dev/null 2>&1; then
  path=($(go env GOPATH)/bin $path)
fi

path=(
  $HOME/bin
  $HOME/.local/bin
  /usr/local/bin
  $path
)

export BUN_INSTALL="$HOME/.bun"
path=($BUN_INSTALL/bin $path)
path=($HOME/.local/share/fnm $path)
path=($HOME/.cargo/bin $path)
path=($HOME/.opencode/bin $path)
path=($HOME/.composer/vendor/bin $path)
