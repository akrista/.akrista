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
    termux-change-repo
    echo "Updating package lists..."
    pkg upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
    echo "Installing required utilities..."
    pkg install -y proot-distro git curl wget neovim termux-api termux-services openssh zsh tree-sitter libllvm make ripgrep fd unzip gitui eza bat oh-my-posh tmux zig clang nnn fzf zoxide rust
    echo "Setting up SSH..."
    bash -c "sv-enable sshd"
    bash -c "sv-enable ssh-agent"
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
fi
[ -d "$HOME/.oh-my-zsh" ] && echo "Oh My Zsh is already installed." || { echo "Installing Oh My Zsh..."; sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended < /dev/null; } #

command -v oh-my-posh &> /dev/null && echo "Oh My Posh is already installed." || { echo "Installing Oh My Posh..."; curl -s https://ohmyposh.dev/install.sh | bash -s; } #

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
            exec zsh -l;
        } || echo "zsh is not installed. Cannot change default shell." ;;
esac #
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
    Write-Host ".akrista repository already exists. Updating..."
    git -C $dotfilesPath pull
}
if (Test-Path $dotfilesPath) {
    $checkFile = Join-Path $dotfilesPath ".last_update_check"
    New-Item -ItemType File -Path $checkFile -Force | Out-Null
}