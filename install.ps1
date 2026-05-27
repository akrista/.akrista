#!/usr/bin/env bash

function REM() { return; }
REM @'
REM '; : << "BASH"
BASH

echo "Unix: Bourne-Shell"

# Identify package manager and OS
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
    termux-change-repo

    echo "Updating package lists..."
    pkg upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"

    echo "Installing required utilities..."
    pkg install -y proot-distro git curl wget neovim termux-api termux-services openssh zsh tree-sitter libllvm make ripgrep fd unzip gitui eza bat oh-my-posh tmux zig clang nnn fzf zoxide rust

    echo "Setting up SSH..."
    sv-enable sshd
    sv-enable ssh-agent

    echo "Ensuring Termux boot directory exists (~/.termux/boot)..."
    mkdir -p ~/.termux/boot

    echo "Setting up Termux storage access..."
    termux-setup-storage
fi

if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    echo "Oh My Zsh is already installed."
fi

if ! command -v oh-my-posh &> /dev/null; then
    echo "Installing Oh My Posh..."
    curl -s https://ohmyposh.dev/install.sh | bash -s
else
    echo "Oh My Posh is already installed."
fi

NVIM_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
if [ ! -d "$NVIM_CONFIG_DIR" ]; then
    echo "Cloning Neovim configuration..."
    git clone -b akrista https://github.com/akrista/nvim "$NVIM_CONFIG_DIR"
else
    echo "Neovim configuration already exists."
fi

DOTFILES_DIR="$HOME/.akrista"
if [ ! -d "$DOTFILES_DIR" ]; then
    echo "Cloning .akrista repository..."
    git clone https://github.com/akrista/.akrista "$DOTFILES_DIR"
else
    echo ".akrista repository already exists."
fi

ZSHRC_TARGET="$HOME/.zshrc"
ZSHRC_SOURCE="$DOTFILES_DIR/.zshrc"

if [ -f "$ZSHRC_SOURCE" ]; then
    # Check if .zshrc at home is already a symlink to our repo's .zshrc
    if [ -L "$ZSHRC_TARGET" ] && [ "$(readlink "$ZSHRC_TARGET")" = "$ZSHRC_SOURCE" ]; then
        echo ".zshrc is already linked to the repository's version."
    else
        echo "Creating symlink for .zshrc..."
        if [ -e "$ZSHRC_TARGET" ] || [ -L "$ZSHRC_TARGET" ]; then
            echo "Backing up existing $ZSHRC_TARGET to $ZSHRC_TARGET.bak..."
            mv "$ZSHRC_TARGET" "$ZSHRC_TARGET.bak"
        fi
        ln -s "$ZSHRC_SOURCE" "$ZSHRC_TARGET"
    fi
else
    echo "Warning: Repository's .zshrc not found at $ZSHRC_SOURCE"
fi

case "$SHELL" in
    *zsh)
        echo "Default shell is already zsh."
        ;;
    *)
        if command -v zsh &> /dev/null; then
            echo "Changing default shell to zsh..."
            if [ "$OS" = "Termux" ]; then
                chsh -s zsh
            else
                if command -v chsh &> /dev/null; then
                    chsh -s "$(command -v zsh)"
                else
                    echo "chsh command not found. Please change your default shell to zsh manually."
                fi
            fi
            
            echo "Switching current session to zsh..."
            exec zsh -l
        else
            echo "zsh is not installed. Cannot change default shell."
        fi
        ;;
esac

exit
'@

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
    Write-Host ".akrista repository already exists."
}