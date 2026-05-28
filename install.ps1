#!/usr/bin/env bash

function REM() { return; }
REM @'
REM '; : << "BASH"
BASH

echo "Unix: Bourne-Shell"
unset ZSH

if [ -n "$TERMUX_VERSION" ] || command -v pkg &> /dev/null; then
    PACKAGER="pkg"
    OS="Termux"
elif command -v apt &> /dev/null || command -v apt-get &> /dev/null; then
    PACKAGER="apt"
    OS="Debian/Ubuntu"
elif command -v dnf &> /dev/null; then
    PACKAGER="dnf"
    OS="Fedora"
elif command -v pacman &> /dev/null; then
    PACKAGER="pacman"
    OS="Arch Linux"
elif command -v apk &> /dev/null; then
    PACKAGER="apk"
    OS="Alpine"
else
    PACKAGER="unknown"
    OS="unknown"
fi

echo "Detected OS/Environment: $OS"
echo "Detected Package Manager: $PACKAGER"

if [ "$OS" = "Termux" ]; then
    echo "Setting up Termux User Repository (tur-repo)..."
    pkg install -y tur-repo root-repo
    echo "Changing Termux repository..."
    [ -t 0 ] && termux-change-repo || echo "Non-interactive shell detected, skipping mirror configuration."
    echo "Updating package lists..."
    pkg upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
    echo "Installing required utilities..."
    pkg install -y proot-distro git curl wget neovim termux-api termux-services openssh zsh tree-sitter libllvm make ripgrep fd unzip gitui eza bat oh-my-posh tmux zig clang nnn fzf zoxide rust nodejs sqlite php composer gh lua-language-server stylua

    echo "Setting up SSH..."
    bash -l -c "sv-enable sshd"
    bash -l -c "sv-enable ssh-agent"
    echo "Ensuring Termux boot directory exists (~/.termux/boot)..."
    mkdir -p ~/.termux/boot
    echo "Setting up Termux storage access..."
    termux-setup-storage
    if [ ! -f ~/.termux/font.ttf ]; then
        echo "Downloading and installing MesloLGS NF Regular font..."
        mkdir -p ~/.termux
        curl -fsSL -o ~/.termux/font.ttf "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf"
        termux-reload-settings
    else
        echo "MesloLGS NF Regular font is already installed."
    fi

    if ! command -v gemini &> /dev/null; then
        echo "Installing @google/gemini-cli..."
        npm i -g @google/gemini-cli
    else
        echo "gemini-cli is already installed."
    fi
fi
[ -d "$HOME/.oh-my-zsh" ] && echo "Oh My Zsh is already installed." || { echo "Installing Oh My Zsh..."; sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended < /dev/null; } #

mkdir -p "$HOME/.zsh"
[ -d "$HOME/.zsh/zsh-autosuggestions" ] && echo "zsh-autosuggestions is already installed." || { echo "Installing zsh-autosuggestions..."; git clone https://github.com/zsh-users/zsh-autosuggestions "$HOME/.zsh/zsh-autosuggestions"; } #
[ -d "$HOME/.zsh/zsh-syntax-highlighting" ] && echo "zsh-syntax-highlighting is already installed." || { echo "Installing zsh-syntax-highlighting..."; git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$HOME/.zsh/zsh-syntax-highlighting"; } #
[ -d "$HOME/.zsh/zsh-completions" ] && echo "zsh-completions is already installed." || { echo "Installing zsh-completions..."; git clone https://github.com/zsh-users/zsh-completions.git "$HOME/.zsh/zsh-completions"; rm -f "$HOME/.zcompdump"*; } #

command -v oh-my-posh &> /dev/null && echo "Oh My Posh is already installed." || { echo "Installing Oh My Posh..."; curl -s https://ohmyposh.dev/install.sh | bash -s; } #

if [ "$OS" = "Termux" ]; then
    echo "Skipping NVM installation on Termux."
else
    [ -d "$HOME/.nvm" ] && echo "NVM is already installed." || { echo "Installing NVM..."; curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash; } #
fi

if [ "$OS" = "Termux" ]; then
    echo "Skipping Bun installation on Termux."
else
    [ -d "$HOME/.bun" ] && echo "Bun is already installed." || { echo "Installing Bun..."; curl -fsSL https://bun.sh/install | bash; } #
fi

if [ "$OS" = "Termux" ]; then
    echo "Skipping Opencode installation on Termux."
else
    command -v opencode &> /dev/null && echo "OpenCode is already installed." || { echo "Installing OpenCode..."; curl -fsSL https://opencode.ai/install | bash; } #
fi

if [ "$OS" = "Termux" ]; then
    echo "Skipping Copilot installation on Termux."
else
    command -v copilot &> /dev/null && echo "GitHub Copilot CLI is already installed." || { echo "Installing GitHub Copilot CLI..."; curl -fsSL https://gh.io/copilot-install | bash; } #
fi

command -v pi &> /dev/null && echo "Pi coding agent is already installed." || { echo "Installing Pi coding agent..."; npm i -g --ignore-scripts @earendil-works/pi-coding-agent; } #

NVIM_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
[ -d "$NVIM_CONFIG_DIR" ] && echo "Neovim configuration already exists." || { echo "Cloning Neovim configuration..."; git clone -b akrista https://github.com/akrista/nvim "$NVIM_CONFIG_DIR"; } #

DOTFILES_DIR="$HOME/.akrista"
[ -d "$DOTFILES_DIR" ] && { echo ".akrista repository already exists. Updating..."; git -C "$DOTFILES_DIR" pull; } || { echo "Cloning .akrista repository..."; git clone https://github.com/akrista/.akrista "$DOTFILES_DIR"; } #

[ -d "$DOTFILES_DIR" ] && touch "$DOTFILES_DIR/.last_update_check" 2>/dev/null

ZSHRC_TARGET="$HOME/.zshrc"
ZSHRC_SOURCE="$DOTFILES_DIR/.zshrc"
[ ! -f "$ZSHRC_SOURCE" ] && echo "Warning: Repository's .zshrc not found at $ZSHRC_SOURCE" || {
    [ -L "$ZSHRC_TARGET" ] && [ "$(readlink "$ZSHRC_TARGET")" = "$ZSHRC_SOURCE" ] && echo ".zshrc is already linked to the repository's version." || {
        echo "Creating symlink for .zshrc..."
        { [ -e "$ZSHRC_TARGET" ] || [ -L "$ZSHRC_TARGET" ]; } && { echo "Backing up existing $ZSHRC_TARGET to $ZSHRC_TARGET.bak..."; mv "$ZSHRC_TARGET" "$ZSHRC_TARGET.bak"; }
        ln -s "$ZSHRC_SOURCE" "$ZSHRC_TARGET"
    }
} #

GITCONFIG_TARGET="$HOME/.gitconfig"
GITCONFIG_SOURCE="$DOTFILES_DIR/.gitconfig"
[ ! -f "$GITCONFIG_SOURCE" ] && echo "Warning: Repository's .gitconfig not found at $GITCONFIG_SOURCE" || {
    [ -L "$GITCONFIG_TARGET" ] && [ "$(readlink "$GITCONFIG_TARGET")" = "$GITCONFIG_SOURCE" ] && echo ".gitconfig is already linked to the repository's version." || {
        echo "Creating symlink for .gitconfig..."
        { [ -e "$GITCONFIG_TARGET" ] || [ -L "$GITCONFIG_TARGET" ]; } && { echo "Backing up existing $GITCONFIG_TARGET to $GITCONFIG_TARGET.bak..."; mv "$GITCONFIG_TARGET" "$GITCONFIG_TARGET.bak"; }
        ln -s "$GITCONFIG_SOURCE" "$GITCONFIG_TARGET"
    }
} #

TERMUX_PROPERTIES_TARGET="$HOME/.termux/termux.properties"
TERMUX_PROPERTIES_SOURCE="$DOTFILES_DIR/.termux.properties"
if [ "$OS" = "Termux" ]; then
    [ ! -f "$TERMUX_PROPERTIES_SOURCE" ] && echo "Warning: Repository's .termux.properties not found at $TERMUX_PROPERTIES_SOURCE" || {
        [ -L "$TERMUX_PROPERTIES_TARGET" ] && [ "$(readlink "$TERMUX_PROPERTIES_TARGET")" = "$TERMUX_PROPERTIES_SOURCE" ] && echo "termux.properties is already linked to the repository's version." || {
            echo "Creating symlink for termux.properties..."
            mkdir -p "$HOME/.termux"
            { [ -e "$TERMUX_PROPERTIES_TARGET" ] || [ -L "$TERMUX_PROPERTIES_TARGET" ]; } && { echo "Backing up existing $TERMUX_PROPERTIES_TARGET to $TERMUX_PROPERTIES_TARGET.bak..."; mv "$TERMUX_PROPERTIES_TARGET" "$TERMUX_PROPERTIES_TARGET.bak"; }
            ln -s "$TERMUX_PROPERTIES_SOURCE" "$TERMUX_PROPERTIES_TARGET"
            termux-reload-settings
        }
    }
fi #

GITCONFIG_LOCAL="$HOME/.gitconfig.local"
[ -f "$GITCONFIG_LOCAL" ] && echo ".gitconfig.local already exists." || {
    echo "Creating empty .gitconfig.local..."
    touch "$GITCONFIG_LOCAL"
} #

case "$SHELL" in #
    *zsh) #
        echo "Default shell is already zsh." ;;
    *) #
        command -v zsh &> /dev/null && {
            echo "Changing default shell to zsh..."
            [ "$OS" = "Termux" ] && chsh -s zsh || {
                command -v chsh &> /dev/null && chsh -s "$(command -v zsh)" || echo "chsh command not found. Please change your default shell to zsh manually.";
            }
            echo "Switching current session to zsh..."
            exec zsh -l </dev/tty;
        } || echo "zsh is not installed. Cannot change default shell." ;;
esac #
exit
'@
# '

Write-Host "Windows: Powershell"
Write-Host "Installing Oh My Posh..."
winget install -e --accept-source-agreements --accept-package-agreements JanDeDobbeleer.OhMyPosh --source winget

$nvimConfigPath = Join-Path $env:LOCALAPPDATA "nvim"
if (-not (Test-Path $nvimConfigPath)) {
    Write-Host "Cloning Neovim configuration..."
    git clone -b akrista https://github.com/akrista/nvim $nvimConfigPath
} else {
    Write-Host "Neovim configuration already exists."
}

$dotfilesPath = Join-Path $HOME ".akrista"
if (-not (Test-Path $dotfilesPath)) {
    Write-Host "Cloning .akrista repository..."
    git clone https://github.com/akrista/.akrista $dotfilesPath
} else {
    Write-Host ".akrista repository already exists. Updating..."
    git -C $dotfilesPath pull
}
if (Test-Path $dotfilesPath) {
    $checkFile = Join-Path $dotfilesPath ".last_update_check"
    New-Item -ItemType File -Path $checkFile -Force | Out-Null
}

$gitConfigTarget = Join-Path $HOME ".gitconfig"
$gitConfigSource = Join-Path $dotfilesPath ".gitconfig"

if (Test-Path $gitConfigSource) {
    $alreadyLinked = $false
    if (Test-Path $gitConfigTarget) {
        $item = Get-Item $gitConfigTarget
        if ($item.Attributes -match "ReparsePoint") {
            $target = $item.Target
            if ($target -eq $gitConfigSource -or $target -eq (Get-Item $gitConfigSource).FullName) {
                Write-Host ".gitconfig is already linked to the repository's version."
                $alreadyLinked = $true
            }
        }
        
        if (-not $alreadyLinked) {
            Write-Host "Backing up existing $gitConfigTarget to $gitConfigTarget.bak..."
            if (Test-Path "$gitConfigTarget.bak") {
                Remove-Item "$gitConfigTarget.bak" -Force
            }
            Move-Item $gitConfigTarget "$gitConfigTarget.bak" -Force
            Write-Host "Creating symlink for .gitconfig..."
            try {
                New-Item -ItemType SymbolicLink -Path $gitConfigTarget -Value $gitConfigSource -ErrorAction Stop | Out-Null
            } catch {
                Write-Host "Failed to create symlink (requires Admin or Developer Mode). Copying file instead..."
                Copy-Item $gitConfigSource $gitConfigTarget -Force
            }
        }
    } else {
        Write-Host "Creating symlink for .gitconfig..."
        try {
            New-Item -ItemType SymbolicLink -Path $gitConfigTarget -Value $gitConfigSource -ErrorAction Stop | Out-Null
        } catch {
            Write-Host "Failed to create symlink. Copying file instead..."
            Copy-Item $gitConfigSource $gitConfigTarget -Force
        }
    }
}

$gitConfigLocal = Join-Path $HOME ".gitconfig.local"
if (-not (Test-Path $gitConfigLocal)) {
    Write-Host "Creating empty $gitConfigLocal..."
    New-Item -ItemType File -Path $gitConfigLocal -Force | Out-Null
}
