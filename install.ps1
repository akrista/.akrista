#!/usr/bin/env bash

function REM() { return; }
REM @'
REM '; : << "BASH"
BASH

echo "Unix: Bourne-Shell"
unset ZSH

# 1. OS & Package Manager Detection
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

# 2. Symlink Helper Function
link_file() {
    local source_file="$1"
    local target_file="$2"
    local name="$3"
    
    [ ! -f "$source_file" ] && echo "Warning: Repository's $name not found at $source_file" && return
    
    if [ -L "$target_file" ] && [ "$(readlink "$target_file")" = "$source_file" ]; then
        echo "$name is already linked to the repository's version."
    else
        echo "Creating symlink for $name..."
        if [ -e "$target_file" ] || [ -L "$target_file" ]; then
            echo "Backing up existing $target_file to $target_file.bak..."
            mv "$target_file" "$target_file.bak"
        fi
        ln -s "$source_file" "$target_file"
    fi
}

# 3. Termux Specific Setup
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

# 4. Shell & Plugin Installs
[ -d "$HOME/.oh-my-zsh" ] && echo "Oh My Zsh is already installed." || { echo "Installing Oh My Zsh..."; sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended < /dev/null; }

mkdir -p "$HOME/.zsh"
[ -d "$HOME/.zsh/zsh-autosuggestions" ] && echo "zsh-autosuggestions is already installed." || { echo "Installing zsh-autosuggestions..."; git clone https://github.com/zsh-users/zsh-autosuggestions "$HOME/.zsh/zsh-autosuggestions"; }
[ -d "$HOME/.zsh/zsh-syntax-highlighting" ] && echo "zsh-syntax-highlighting is already installed." || { echo "Installing zsh-syntax-highlighting..."; git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$HOME/.zsh/zsh-syntax-highlighting"; }
[ -d "$HOME/.zsh/zsh-completions" ] && echo "zsh-completions is already installed." || { echo "Installing zsh-completions..."; git clone https://github.com/zsh-users/zsh-completions.git "$HOME/.zsh/zsh-completions"; rm -f "$HOME/.zcompdump"*; }

command -v oh-my-posh &> /dev/null && echo "Oh My Posh is already installed." || { echo "Installing Oh My Posh..."; curl -s https://ohmyposh.dev/install.sh | bash -s; }

# 5. Non-Termux Installs
if [ "$OS" != "Termux" ]; then
    [ -d "$HOME/.nvm" ] && echo "NVM is already installed." || { echo "Installing NVM..."; curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash; }
    [ -d "$HOME/.bun" ] && echo "Bun is already installed." || { echo "Installing Bun..."; curl -fsSL https://bun.sh/install | bash; }
    command -v opencode &> /dev/null && echo "OpenCode is already installed." || { echo "Installing OpenCode..."; curl -fsSL https://opencode.ai/install | bash; }
    command -v copilot &> /dev/null && echo "GitHub Copilot CLI is already installed." || { echo "Installing GitHub Copilot CLI..."; curl -fsSL https://gh.io/copilot-install | bash; }
fi

command -v pi &> /dev/null && echo "Pi coding agent is already installed." || { echo "Installing Pi coding agent..."; npm i -g --ignore-scripts @earendil-works/pi-coding-agent; }

# 6. Configurations & Symlinks
NVIM_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
[ -d "$NVIM_CONFIG_DIR" ] && echo "Neovim configuration already exists." || { echo "Cloning Neovim configuration..."; git clone -b akrista https://github.com/akrista/nvim "$NVIM_CONFIG_DIR"; }

DOTFILES_DIR="$HOME/.akrista"
[ -d "$DOTFILES_DIR" ] && { echo ".akrista repository already exists. Updating..."; git -C "$DOTFILES_DIR" pull; } || { echo "Cloning .akrista repository..."; git clone https://github.com/akrista/.akrista "$DOTFILES_DIR"; }

[ -d "$DOTFILES_DIR" ] && touch "$DOTFILES_DIR/.last_update_check" 2>/dev/null

[ -d "$HOME/.tmux/plugins/tpm" ] && echo "TPM (Tmux Plugin Manager) is already installed." || {
    echo "Installing TPM (Tmux Plugin Manager)..."
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
}

# Link dotfiles
link_file "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc" ".zshrc"
link_file "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig" ".gitconfig"
link_file "$DOTFILES_DIR/.sqliterc" "$HOME/.sqliterc" ".sqliterc"

if [ "$OS" = "Termux" ]; then
    mkdir -p "$HOME/.termux"
    link_file "$DOTFILES_DIR/termux.properties" "$HOME/.termux/termux.properties" "termux.properties"
    termux-reload-settings
fi

GITCONFIG_LOCAL="$HOME/.gitconfig.local"
[ -f "$GITCONFIG_LOCAL" ] && echo ".gitconfig.local already exists." || {
    echo "Creating empty .gitconfig.local..."
    touch "$GITCONFIG_LOCAL"
}

# 7. Shell Switch
case "$SHELL" in
    *zsh)
        echo "Default shell is already zsh." ;;
    *)
        command -v zsh &> /dev/null && {
            echo "Changing default shell to zsh..."
            [ "$OS" = "Termux" ] && chsh -s zsh || {
                command -v chsh &> /dev/null && chsh -s "$(command -v zsh)" || echo "chsh command not found. Please change your default shell to zsh manually.";
            }
            echo "Switching current session to zsh..."
            exec zsh -l </dev/tty;
        } || echo "zsh is not installed. Cannot change default shell." ;;
esac
exit
'@
# '

# =====================================================================
# Windows PowerShell Execution Block
# =====================================================================
Write-Host "Windows: Powershell"
Write-Host "Installing Oh My Posh..."
winget install -e --accept-source-agreements --accept-package-agreements JanDeDobbeleer.OhMyPosh --source winget

# PowerShell Symlink Helper
function Link-File {
    param (
        [string]$SourcePath,
        [string]$TargetPath,
        [string]$Name
    )
    if (Test-Path $SourcePath) {
        $alreadyLinked = $false
        if (Test-Path $TargetPath) {
            $item = Get-Item $TargetPath
            if ($item.Attributes -match "ReparsePoint") {
                $target = $item.Target
                if ($target -eq $SourcePath -or $target -eq (Get-Item $SourcePath).FullName) {
                    Write-Host "$Name is already linked to the repository's version."
                    $alreadyLinked = $true
                }
            }
            
            if (-not $alreadyLinked) {
                Write-Host "Backing up existing $TargetPath to $TargetPath.bak..."
                if (Test-Path "$TargetPath.bak") {
                    Remove-Item "$TargetPath.bak" -Force
                }
                Move-Item $TargetPath "$TargetPath.bak" -Force
                Write-Host "Creating symlink for $Name..."
                try {
                    New-Item -ItemType SymbolicLink -Path $TargetPath -Value $SourcePath -ErrorAction Stop | Out-Null
                } catch {
                    Write-Host "Failed to create symlink (requires Admin or Developer Mode). Copying file instead..."
                    Copy-Item $SourcePath $TargetPath -Force
                }
            }
        } else {
            Write-Host "Creating symlink for $Name..."
            try {
                New-Item -ItemType SymbolicLink -Path $TargetPath -Value $SourcePath -ErrorAction Stop | Out-Null
            } catch {
                Write-Host "Failed to create symlink. Copying file instead..."
                Copy-Item $SourcePath $TargetPath -Force
            }
        }
    }
}

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

# Link Windows dotfiles
Link-File -SourcePath (Join-Path $dotfilesPath ".gitconfig") -TargetPath (Join-Path $HOME ".gitconfig") -Name ".gitconfig"
Link-File -SourcePath (Join-Path $dotfilesPath ".sqliterc") -TargetPath (Join-Path $HOME ".sqliterc") -Name ".sqliterc"

$gitConfigLocal = Join-Path $HOME ".gitconfig.local"
if (-not (Test-Path $gitConfigLocal)) {
    Write-Host "Creating empty $gitConfigLocal..."
    New-Item -ItemType File -Path $gitConfigLocal -Force | Out-Null
}
