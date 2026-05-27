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

# Environment-specific package installations
if [ "$OS" = "Termux" ]; then

    echo "Changing Termux repository..."
    termux-change-repo

    echo "Setting up Termux User Repository (tur-repo)..."
    pkg install -y tur-repo

    echo "Installing required utilities..."
    pkg install -y proot-distro git curl wget neovim termux-api termux-services openssh zsh tree-sitter libllvm make ripgrep fd unzip gitui eza bat oh-my-posh tmux zig clang nnn

    echo "Setting up SSH..."
    sv-enable sshd
    sv-enable ssh-agent

    echo "Ensuring Termux boot directory exists (~/.termux/boot)..."
    mkdir -p ~/.termux/boot

    echo "Setting up Termux storage access..."
    termux-setup-storage
fi

# Install Oh My Zsh if not already present
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    echo "Oh My Zsh is already installed."
fi

# Install Oh My Posh if not already present
if ! command -v oh-my-posh &> /dev/null; then
    echo "Installing Oh My Posh..."
    curl -s https://ohmyposh.dev/install.sh | bash -s
else
    echo "Oh My Posh is already installed."
fi

# Clone Neovim config if not already present
NVIM_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
if [ ! -d "$NVIM_CONFIG_DIR" ]; then
    echo "Cloning Neovim configuration..."
    git clone -b akrista https://github.com/akrista/nvim "$NVIM_CONFIG_DIR"
else
    echo "Neovim configuration already exists."
fi

exit
'@

Write-Host "Windows: Powershell"

Write-Host "Installing Oh My Posh..."
winget install -e --accept-source-agreements --accept-package-agreements JanDeDobbeleer.OhMyPosh --source winget

# Clone Neovim config if not already present in Windows
$nvimConfigPath = Join-Path $env:LOCALAPPDATA "nvim"
if (-not (Test-Path $nvimConfigPath)) {
    Write-Host "Cloning Neovim configuration..."
    git clone -b akrista https://github.com/akrista/nvim $nvimConfigPath
} else {
    Write-Host "Neovim configuration already exists."
}