if [ -d "/home/linuxbrew/.linuxbrew" ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

export PATH="$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export NVM_DIR="$HOME/.nvm"

HISTFILE=~/.zsh_history
HISTDUP=erase
HISTSIZE=5000
SAVEHIST=10000

export VISUAL=nvim
export EDITOR="$VISUAL"
export COMPOSE_BAKE=true

export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

zstyle ':omz:update' mode auto      # update automatically without asking
zstyle ':omz:update' frequency 30

DISABLE_UNTRACKED_FILES_DIRTY="true"

plugins=()

source $ZSH/oh-my-zsh.sh

alias cat='bat'

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

if [ -s "$NVM_DIR/nvm.sh" ]; then
  source "$NVM_DIR/nvm.sh"
fi
if [ -s "$NVM_DIR/bash_completion" ]; then
  source "$NVM_DIR/bash_completion"
fi

if [ -s "/home/akrista/.bun/_bun" ]; then
  source "/home/akrista/.bun/_bun"
fi

if [ "$TERM_PROGRAM" != "Apple_Terminal" ] && command -v oh-my-posh >/dev/null 2>&1; then
  eval "$(oh-my-posh init zsh --config $HOME/.akrista/lambdageneration.omp.json)"
fi

if [ -f "/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
  source "/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

if [ -f "/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
  source "/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi