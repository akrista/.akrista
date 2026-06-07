#!/usr/bin/env bash

# ==============================================================================
#  🛠️  Bilingual Environment Bootstrapper & Installer (install.ps1 / Polyglot)
# ==============================================================================
#  This script is a polyglot / bilingual execution script. It is designed to
#  run directly as a Bourne-Shell (Bash) script on Unix/Linux/macOS/Termux systems
#  and as a PowerShell 5.1/7+ script on Windows systems—all within the SAME file.
#
#  💡 HOW THE POLYGLOT TECHNIQUE WORKS:
#  - Linux/Unix shells run this file using 'bash'.
#  - Line 3 declares the REM function. In shell scripts, REM is a standard command.
#  - Line 4 'REM @'' evaluates as a call to REM with the argument "@'".
#  - Line 5 uses Bash's command sequence separator (;) and a here-doc redirect (: << "BASH")
#    to make Bash execute everything inside this block and ignore the rest of the file.
#  - Line 450 ends the Bash script with "exit" and the PowerShell here-string closing tag "'@".
#  - Windows PowerShell reads 'REM @'' as the beginning of a multi-line here-string,
#    meaning PowerShell completely skips the entire Bash block (lines 4 to 450) and
#    runs only the PowerShell block starting on line 453.
# ==============================================================================

function REM() { return; }
REM @'
REM '; : << "BASH"
BASH

# ------------------------------------------------------------------------------
#  1. Logging & Formatting Helpers (Bash)
# ------------------------------------------------------------------------------
# Define standard colors for elegant, premium logging output.
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color / Reset

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

log_info "Initializing Unix setup block..."

# ------------------------------------------------------------------------------
#  2. Argument Parsing (Bash)
# ------------------------------------------------------------------------------
FORCE=false
for arg in "$@"; do
    case $arg in
        --force|-f) 
            FORCE=true 
            log_info "Force installation flag (--force / -f) detected."
            ;;
    esac
done

# ------------------------------------------------------------------------------
#  3. OS & Package Manager Detection (Bash)
# ------------------------------------------------------------------------------
# Dynamically queries package manager tools to figure out the active environment.
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

log_info "Detected OS/Environment: $OS"
log_info "Detected Package Manager: $PACKAGER"

# Checks if we are running in a PRoot/Chroot containment framework under Android
IS_PROOT_DISTRO=false
if uname -a | grep -q "PRoot-Distro"; then
    IS_PROOT_DISTRO=true
    log_info "PRoot-Distro sandbox environment detected."
fi

DOTFILES_DIR="$HOME/.akrista"

# ------------------------------------------------------------------------------
#  4. Sudo & Linking Utilities (Bash)
# ------------------------------------------------------------------------------

# Renders a diagnostic, beautiful instruction panel if the user runs into privilege blockades.
show_sudo_debian_remediation_message() {
    local reason="$1"
    echo ""
    echo -e "${RED}========================================================================"
    echo " 🔴 SYSTEM CONFIGURATION ISSUE DETECTED"
    echo -e "========================================================================${NC}"
    if [ "$reason" = "root" ]; then
        echo " Error: You are currently running this script as root!"
        echo " Running dotfiles setup as root is not supported or recommended."
    elif [ "$reason" = "no_sudo" ]; then
        echo " Error: 'sudo' command not found!"
    else
        echo " Error: Current user '$USER' does not have sudo privileges!"
    fi
    echo ""
    echo " Debian usually doesn't come with sudo installed by default."
    echo " Please follow these steps to configure your environment:"
    echo ""
    echo " 1. Login with root and install sudo:"
    echo "    apt update && apt install -y sudo"
    echo ""
    echo " 2. Create the desired user:"
    echo "    useradd -m username"
    echo "    passwd username"
    echo ""
    echo " 3. Add user to sudo group:"
    echo "    usermod -aG sudo username"
    echo ""
    echo " 4. Ensure that an editor is installed (if not, install neovim):"
    echo "    apt install -y neovim"
    echo ""
    echo " 5. Run visudo (or sudo visudo) to add the username privilege:"
    echo "    visudo"
    echo "    # Add the following line under the user privilege specification:"
    echo "    username ALL=(ALL:ALL) ALL"
    echo ""
    echo " 6. Switch to your user and run the installation script again:"
    echo "    su - username"
    echo "    cd ~/.username"
    echo "    ./install.ps1"
    echo -e "${RED}========================================================================${NC}"
    echo ""
}

# Verifies if the active shell user has sudo permissions without blocking interactive sessions.
has_sudo_privileges() {
    if ! command -v sudo &> /dev/null; then
        return 1
    fi
    if sudo -n true 2>/dev/null; then
        return 0
    fi
    if groups | grep -qE '\b(sudo|admin|wheel)\b'; then
        return 0
    fi
    local sudo_l_output
    sudo_l_output=$(sudo -n -l 2>&1)
    if echo "$sudo_l_output" | grep -qE "not in the sudoers|not allowed to run sudo"; then
        return 1
    fi
    log_info "Checking sudo access (you may be prompted for your password)..."
    if sudo -v &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Creates a symbolic link for config files while backing up any pre-existing custom versions.
link_file() {
    local source_file="$1"
    local target_file="$2"
    local name="$3"
    
    [ ! -f "$source_file" ] && log_warn "Repository's $name not found at $source_file" && return
    
    if [ -L "$target_file" ] && [ "$(readlink "$target_file")" = "$source_file" ]; then
        log_success "$name is already linked to the repository's version."
    else
        log_info "Creating symlink for $name..."
        if [ -e "$target_file" ] || [ -L "$target_file" ]; then
            log_info "Backing up existing $target_file to $target_file.bak..."
            mv "$target_file" "$target_file.bak"
        fi
        ln -s "$source_file" "$target_file"
    fi
}

# Check if a package is installed using dpkg/apt or command check fallback.
pkg_is_installed() {
    if [ "$PACKAGER" = "pkg" ] || [ "$PACKAGER" = "apt" ]; then
        dpkg -s "$1" &> /dev/null
    else
        command -v "$1" &> /dev/null
    fi
}

# ------------------------------------------------------------------------------
#  5. Modular Distribution Setup Functions (Bash)
# ------------------------------------------------------------------------------

# --- 5.1 TERMUX INSTALLER ---
install_termux_packages() {
    log_info "Starting package installation for Termux..."
    UPGRADE_MARKER="$HOME/.last_termux_upgrade"
    
    # 24-hour rate limit on upgrades to keep shells opening quickly
    if [ "$FORCE" = true ] || [ ! -f "$UPGRADE_MARKER" ] || [ "$(find "$UPGRADE_MARKER" -mmin +1440 2>/dev/null)" ]; then
        log_info "Updating package lists and upgrading system packages..."
        pkg upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
        mkdir -p "$(dirname "$UPGRADE_MARKER")"
        touch "$UPGRADE_MARKER"
    else
        log_info "Skipping pkg upgrade (last run less than 24h ago). Use --force to override."
    fi

    # Termux User Repository (TUR) holds custom programming utilities
    if ! pkg_is_installed tur-repo || ! pkg_is_installed root-repo; then
        log_info "Setting up Termux User Repository (tur-repo) and root-repo..."
        pkg install -y tur-repo root-repo
    fi

    if [ "$FORCE" = true ] && [ -t 0 ]; then
        log_info "Interactive prompt requested. Changing Termux mirror repository..."
        termux-change-repo
    fi

    log_info "Installing comprehensive development suite..."
    pkg install -y proot-distro git curl wget neovim termux-api termux-services openssh zsh tree-sitter libllvm make ripgrep fd unzip gitui eza bat oh-my-posh tmux zig clang nnn fzf zoxide rust nodejs sqlite php composer gh lua-language-server stylua dos2unix

    # Bootstraps SSHD & background daemons via termux-services
    if pkg_is_installed termux-services; then
        log_info "Bootstrapping termux-services environment..."
        if [ -f "$PREFIX/etc/profile.d/start-services.sh" ]; then
            . "$PREFIX/etc/profile.d/start-services.sh" 2>/dev/null
        fi

        if command -v sv-enable &> /dev/null; then
            [ -d "$PREFIX/var/service/sshd" ] || { log_info "Enabling sshd service..."; sv-enable sshd || log_warn "Could not enable sshd automatically. It will be enabled when you restart your terminal."; }
            [ -d "$PREFIX/var/service/ssh-agent" ] || { log_info "Enabling ssh-agent service..."; sv-enable ssh-agent || log_warn "Could not enable ssh-agent automatically. It will be enabled when you restart your terminal."; }
        else
            log_warn "sv-enable command not found. Services will be enabled when you reload your terminal."
        fi
    fi

    # Enables Android storage permissions
    if [ ! -d "$HOME/storage" ]; then
        log_info "Setting up Termux storage access..."
        termux-setup-storage
    fi
}

# --- 5.2 DEBIAN / UBUNTU INSTALLER ---
install_debian_ubuntu_packages() {
    log_info "Starting package installation for Debian/Ubuntu..."
    
    # Dotfiles configurations should NEVER run directly under root account to prevent home directory permission skew
    if [ "$EUID" -eq 0 ] || [ "$(id -u)" -eq 0 ]; then
        show_sudo_debian_remediation_message "root"
        exit 1
    fi

    # Make sure we have the privilege tool 'sudo' configured properly
    if ! command -v sudo &> /dev/null; then
        show_sudo_debian_remediation_message "no_sudo"
        exit 1
    fi

    if ! has_sudo_privileges; then
        show_sudo_debian_remediation_message "no_privileges"
        exit 1
    fi

    # Outdated Neovim installs will break modern LSP configurations
    # We remove the package manager version and download the official upstream release later
    if pkg_is_installed neovim; then
        log_warn "Found outdated Neovim installed via apt. Removing it to prevent path collisions..."
        sudo apt-get remove -y neovim
    fi

    log_info "Updating system package lists and upgrading packages..."
    sudo apt update -y && sudo apt upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"

    log_info "Installing development dependencies and CLI tools..."
    sudo apt install -y make gcc ripgrep fd-find tree-sitter-cli git xclip curl wget unzip zsh ssh eza bat sqlite3 zoxide fzf nnn clang tmux nala locales dos2unix

    log_info "Configuring UTF-8 locales..."
    if ! grep -q "^en_US.UTF-8 UTF-8" /etc/locale.gen; then
        echo "en_US.UTF-8 UTF-8" | sudo tee -a /etc/locale.gen
        sudo locale-gen en_US.UTF-8
    fi
    sudo update-locale LANG=en_US.UTF-8

    # Install Official Upstream Neovim Build
    if [ "$FORCE" = true ] || ! command -v nvim &> /dev/null; then
        log_info "Installing official Neovim build..."
        ARCH=$(uname -m)
        case "$ARCH" in
            x86_64) NVIM_ARCH="x86_64" ;;
            aarch64|arm64) NVIM_ARCH="arm64" ;;
            *) 
                log_warn "Unsupported architecture for official Neovim build: $ARCH. Falling back to apt installation."
                sudo apt install -y neovim
                NVIM_ARCH="unknown" 
                ;;
        esac

        if [ "$NVIM_ARCH" != "unknown" ]; then
            TEMP_DIR=$(mktemp -d)
            (
                cd "$TEMP_DIR" || exit 1
                NVIM_TAR="nvim-linux-$NVIM_ARCH.tar.gz"
                log_info "Downloading $NVIM_TAR from GitHub..."
                curl -LO "https://github.com/neovim/neovim/releases/latest/download/$NVIM_TAR"
                sudo rm -rf "/opt/nvim-linux-$NVIM_ARCH"
                sudo mkdir -p "/opt/nvim-linux-$NVIM_ARCH"
                sudo tar -C /opt -xzf "$NVIM_TAR"
                sudo chmod -R a+rX "/opt/nvim-linux-$NVIM_ARCH"
                sudo ln -sf "/opt/nvim-linux-$NVIM_ARCH/bin/nvim" /usr/local/bin/nvim
            )
            rm -rf "$TEMP_DIR"
            log_success "Neovim installation completed successfully."
        fi
    else
        log_info "Neovim is already installed. Use --force to reinstall."
    fi

    # Pacstall (An AUR-like package manager for Debian/Ubuntu distros)
    if ! command -v pacstall &> /dev/null; then
        log_info "Installing Pacstall..."
        sudo bash -c "$(curl -fsSL https://pacstall.dev/q/install)"
    else
        log_info "Pacstall is already installed."
    fi

    # GitHub CLI (official repository setup)
    if ! command -v gh &> /dev/null; then
        log_info "Installing GitHub CLI..."
        sudo mkdir -p -m 755 /etc/apt/keyrings
        out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg
        cat "$out" | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
        sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
        sudo mkdir -p -m 755 /etc/apt/sources.list.d
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
        sudo apt update
        sudo apt install gh -y
        rm -f "$out"
        log_success "GitHub CLI installed."
    else
        log_info "GitHub CLI (gh) is already installed."
    fi

    # PHP 8.5 installation (Sury repository)
    if ! pkg_is_installed php8.5; then
        log_info "Setting up packages.sury.org/php repository..."
        sudo apt update
        sudo apt install -y lsb-release ca-certificates curl
        sudo curl -sSLo /tmp/debsuryorg-archive-keyring.deb https://packages.sury.org/debsuryorg-archive-keyring.deb
        sudo dpkg -i /tmp/debsuryorg-archive-keyring.deb
        sudo tee /etc/apt/sources.list.d/php.sources <<EOF
Types: deb
URIs: https://packages.sury.org/php/
Suites: $(lsb_release -sc)
Components: main
Signed-By: /usr/share/keyrings/debsuryorg-archive-keyring.gpg
EOF
        sudo apt update
        log_info "Installing PHP 8.5..."
        sudo apt install -y php8.5
        log_success "PHP 8.5 installed successfully."
    else
        log_info "PHP 8.5 is already installed."
    fi

    # Composer installation
    if ! command -v composer &> /dev/null; then
        log_info "Installing Composer..."
        TEMP_DIR=$(mktemp -d)
        (
            cd "$TEMP_DIR" || exit 1
            php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
            php -r "if (hash_file('sha384', 'composer-setup.php') === 'c8b085408188070d5f52bcfe4ecfbee5f727afa458b2573b8eaaf77b3419b0bf2768dc67c86944da1544f06fa544fd47') { echo 'Installer verified'.PHP_EOL; } else { echo 'Installer corrupt'.PHP_EOL; unlink('composer-setup.php'); exit(1); }"
            php composer-setup.php
            php -r "unlink('composer-setup.php');"
            sudo mv composer.phar /usr/local/bin/composer
        )
        rm -rf "$TEMP_DIR"
        log_success "Composer installed successfully."
    else
        log_info "Checking for Composer updates..."
        if [ "$OS" = "Termux" ]; then
            composer self-update --quiet 2>/dev/null || log_warn "Composer self-update failed."
        else
            sudo composer self-update --quiet 2>/dev/null || log_warn "Composer self-update failed."
        fi
    fi
}

# --- 5.3 FEDORA INSTALLER ---
install_fedora_packages() {
    log_info "Starting package installation for Fedora..."
    log_warn "Fedora package list configuration is currently a placeholder. Please extend this block!"
    # Implement Fedora specific setup here:
    # sudo dnf update -y
    # sudo dnf install -y make gcc git ripgrep zsh tmux ...
}

# --- 5.4 ARCH LINUX INSTALLER ---
install_arch_packages() {
    log_info "Starting package installation for Arch Linux..."
    log_warn "Arch Linux package list configuration is currently a placeholder. Please extend this block!"
    # Implement Arch specific setup here:
    # sudo pacman -Syu --noconfirm
    # sudo pacman -S --needed --noconfirm make gcc git ripgrep zsh ...
}

# --- 5.5 ALPINE INSTALLER ---
install_alpine_packages() {
    log_info "Starting package installation for Alpine..."
    log_warn "Alpine package list configuration is currently a placeholder. Please extend this block!"
    # Implement Alpine specific setup here:
    # sudo apk update
    # sudo apk add make gcc git ripgrep zsh ...
}

# ------------------------------------------------------------------------------
#  6. Run Core Modular Package Install
# ------------------------------------------------------------------------------
case "$OS" in
    "Termux")
        install_termux_packages
        ;;
    "Debian/Ubuntu")
        install_debian_ubuntu_packages
        ;;
    "Fedora")
        install_fedora_packages
        ;;
    "Arch Linux")
        install_arch_packages
        ;;
    "Alpine")
        install_alpine_packages
        ;;
    *)
        log_warn "Environment '$OS' matches no built-in installers. Skipping package install."
        ;;
esac

# ------------------------------------------------------------------------------
#  7. Clone / Update Repositories
# ------------------------------------------------------------------------------
log_info "Configuring active workspaces..."
NVIM_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"

if [ -d "$NVIM_CONFIG_DIR/.git" ]; then
    log_info "Neovim configuration already exists at $NVIM_CONFIG_DIR. Pulling updates..."
    git -C "$NVIM_CONFIG_DIR" pull
else
    log_info "Cloning Neovim configuration (branch: akrista)..."
    if [ -d "$NVIM_CONFIG_DIR" ]; then
        log_warn "$NVIM_CONFIG_DIR exists but is not a git repository. Backing up..."
        rm -rf "${NVIM_CONFIG_DIR}.bak"
        mv "$NVIM_CONFIG_DIR" "${NVIM_CONFIG_DIR}.bak"
    fi
    git clone -b akrista https://github.com/akrista/nvim "$NVIM_CONFIG_DIR"
fi

if [ -d "$DOTFILES_DIR/.git" ]; then
    log_info ".akrista repository already exists at $DOTFILES_DIR. Pulling updates..."
    git -C "$DOTFILES_DIR" pull
else
    log_info "Cloning .akrista repository..."
    if [ -d "$DOTFILES_DIR" ]; then
        log_warn "$DOTFILES_DIR exists but is not a git repository. Backing up..."
        rm -rf "${DOTFILES_DIR}.bak"
        mv "$DOTFILES_DIR" "${DOTFILES_DIR}.bak"
    fi
    git clone https://github.com/akrista/.akrista "$DOTFILES_DIR"
fi
[ -d "$DOTFILES_DIR" ] && touch "$DOTFILES_DIR/.last_update_check" 2>/dev/null

# ------------------------------------------------------------------------------
#  8. Environment-Specific Configs & Setup
# ------------------------------------------------------------------------------
if [ "$OS" = "Termux" ]; then
    log_info "Configuring Termux GUI and settings..."
    mkdir -p "$HOME/.termux"
    link_file "$DOTFILES_DIR/termux.properties" "$HOME/.termux/termux.properties" "termux.properties"
    
    # Download Meslo Nerd Font
    if [ ! -f "$HOME/.termux/font.ttf" ]; then
        log_info "Downloading and installing MesloLGS NF Regular font..."
        curl -fsSL -o "$HOME/.termux/font.ttf" "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf"
    else
        log_success "MesloLGS NF Regular font is already installed."
    fi
    
    log_info "Reloading Termux settings..."
    termux-reload-settings
elif [ "$IS_PROOT_DISTRO" = true ]; then
    echo ""
    echo -e "${YELLOW}===================================================="
    echo " ⚠️  PROOT-DISTRO DETECTED"
    echo "===================================================="
    echo "   To fix fonts and terminal settings in Termux, please run the"
    echo "   installer in your main Termux shell (outside the container):"
    echo "   curl -fsSL https://github.com/akrista/.akrista/raw/master/install.ps1 | bash"
    echo -e "====================================================${NC}"
    echo ""
fi

# Multi-platform development configurations (non-Termux architectures)
if [ "$OS" != "Termux" ]; then
    log_info "Setting up multi-platform runtime engines..."
    
    # Node Version Manager (NVM)
    if [ ! -d "$HOME/.nvm" ]; then
        log_info "Installing NVM..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
    else
        log_success "NVM is already installed."
    fi
    export NVM_DIR="$HOME/.nvm"
    if [ -s "$NVM_DIR/nvm.sh" ]; then
        . "$NVM_DIR/nvm.sh"
        log_info "Ensuring Node.js LTS is installed and configured..."
        nvm install --lts
        nvm use --lts
        nvm alias default 'lts/*'
    fi

    # Bun Runtime
    if command -v bun &> /dev/null; then
        log_info "Checking for Bun updates..."
        bun upgrade
    elif [ -d "$HOME/.bun" ]; then
        log_success "Bun directory exists. Sourcing bun to check if upgrade is needed..."
        export BUN_INSTALL="$HOME/.bun"
        export PATH="$BUN_INSTALL/bin:$PATH"
        if command -v bun &> /dev/null; then
            log_info "Checking for Bun updates..."
            bun upgrade
        fi
    else
        log_info "Installing Bun..."
        curl -fsSL https://bun.sh/install | bash
    fi
    
    # OpenCode
    if command -v opencode &> /dev/null; then
        log_success "OpenCode is already installed."
    else
        log_info "Installing OpenCode..."
        curl -fsSL https://opencode.ai/install | bash
    fi
    
    # GitHub Copilot CLI helper
    if command -v copilot &> /dev/null; then
        log_success "GitHub Copilot CLI is already installed."
    else
        log_info "Installing GitHub Copilot CLI..."
        curl -fsSL https://gh.io/copilot-install | bash
    fi
    
    # Tmux Pack (tpack / lightweight TPM)
    if [ -d "$HOME/.tmux/plugins/tpm" ]; then
        log_info "Updating tpack (TPM compatible)..."
        git -C "$HOME/.tmux/plugins/tpm" pull -q
    else
        log_info "Installing tpack (TPM compatible)..."
        git clone -q https://github.com/tmuxpack/tpack "$HOME/.tmux/plugins/tpm"
    fi
    
    # Rust toolchain
    if command -v rustup &> /dev/null; then
        log_info "Checking for Rust updates..."
        rustup update
    else
        log_info "Installing Rustup..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    fi

    # Cargo binaries
    if [ "$OS" = "Debian/Ubuntu" ]; then
        if [ -f "$HOME/.cargo/env" ]; then
            . "$HOME/.cargo/env"
        fi

        if ! command -v gitui &> /dev/null; then
            log_info "Installing gitui..."
            cargo install gitui --locked
            log_success "GitUI installed successfully."
        else
            log_success "gitui is already installed."
        fi

        if ! command -v oxker &> /dev/null; then
            log_info "Installing oxker..."
            cargo install oxker --locked
            log_success "oxker installed successfully."
        else
            log_success "oxker is already installed."
        fi
    fi


    # Homebrew OS abstraction
    if ! command -v brew &> /dev/null && [ ! -d "/home/linuxbrew/.linuxbrew" ]; then
        log_info "Installing Homebrew package manager..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        log_success "Homebrew is already installed."
    fi
fi

# ------------------------------------------------------------------------------
#  9. Shell Environments & Auto-completion Plugins
# ------------------------------------------------------------------------------
log_info "Bootstrapping Oh-My-Zsh & interactive shell environments..."

if [ -d "$HOME/.oh-my-zsh" ]; then
    log_success "Oh My Zsh is already installed."
else
    log_info "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended < /dev/null
fi

mkdir -p "$HOME/.zsh"
if [ -d "$HOME/.zsh/zsh-autosuggestions" ]; then
    log_info "Updating zsh-autosuggestions..."
    git -C "$HOME/.zsh/zsh-autosuggestions" pull -q
else
    log_info "Installing zsh-autosuggestions..."
    git clone -q https://github.com/zsh-users/zsh-autosuggestions "$HOME/.zsh/zsh-autosuggestions"
fi

if [ -d "$HOME/.zsh/zsh-syntax-highlighting" ]; then
    log_info "Updating zsh-syntax-highlighting..."
    git -C "$HOME/.zsh/zsh-syntax-highlighting" pull -q
else
    log_info "Installing zsh-syntax-highlighting..."
    git clone -q https://github.com/zsh-users/zsh-syntax-highlighting.git "$HOME/.zsh/zsh-syntax-highlighting"
fi

if [ -d "$HOME/.zsh/zsh-completions" ]; then
    log_info "Updating zsh-completions..."
    git -C "$HOME/.zsh/zsh-completions" pull -q
    rm -f "$HOME/.zcompdump"*
else
    log_info "Installing zsh-completions..."
    git clone -q https://github.com/zsh-users/zsh-completions.git "$HOME/.zsh/zsh-completions"
    rm -f "$HOME/.zcompdump"*
fi

# Oh My Posh shell prompt engine
if command -v oh-my-posh &> /dev/null; then
    log_info "Checking for Oh My Posh updates..."
    oh-my-posh upgrade 2>/dev/null || log_warn "Oh My Posh upgrade check failed."
else
    log_info "Installing Oh My Posh..."
    curl -s https://ohmyposh.dev/install.sh | bash -s
fi

# Unified Global Node/NPM Packages (Cross-Platform)
log_info "Configuring global Node/NPM packages..."
if command -v npm &> /dev/null; then
    # Gemini CLI
    if ! command -v gemini &> /dev/null; then
        log_info "Installing @google/gemini-cli..."
        npm i -g @google/gemini-cli
        log_success "Gemini CLI installed successfully."
    else
        log_info "Updating @google/gemini-cli..."
        npm update -g @google/gemini-cli
        log_success "Gemini CLI updated successfully."
    fi

    # Pi Coding Agent
    if ! command -v pi &> /dev/null; then
        log_info "Installing Pi coding agent..."
        npm i -g --ignore-scripts @earendil-works/pi-coding-agent
        log_success "Pi coding agent installed successfully."
    else
        log_info "Updating Pi coding agent..."
        npm update -g @earendil-works/pi-coding-agent
        log_success "Pi coding agent updated successfully."
    fi
else
    log_warn "npm not found. Skipping global NPM packages installation/updates."
fi

# ------------------------------------------------------------------------------
#  10. Post-Installation Cleanup & Maintenance
# ------------------------------------------------------------------------------
log_info "Performing post-installation package cleanup..."
if [ "$PACKAGER" = "pkg" ]; then
    log_info "Cleaning up Termux packages..."
    pkg autoclean -y
    pkg clean
elif [ "$PACKAGER" = "apt" ]; then
    log_info "Cleaning up Debian/Ubuntu packages..."
    sudo apt-get autoremove -y
    sudo apt-get autoclean -y
    sudo apt-get clean
fi

# ------------------------------------------------------------------------------
#  11. Symlink Dotfile Setup
# ------------------------------------------------------------------------------
log_info "Symlinking runtime configurations..."
link_file "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc" ".zshrc"
link_file "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig" ".gitconfig"
link_file "$DOTFILES_DIR/.sqliterc" "$HOME/.sqliterc" ".sqliterc"
link_file "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf" ".tmux.conf"

# Tmux Plugin Manager & Plugin compilation logic
if command -v tmux &> /dev/null && [ -d "$HOME/.tmux/plugins/tpm" ]; then
    log_info "Installing/Updating tmux plugins..."
    export TMUX_PLUGIN_MANAGER_PATH="$HOME/.tmux/plugins"
    "$HOME/.tmux/plugins/tpm/bin/install_plugins" || log_warn "Could not install tmux plugins automatically."

    # Crucial CRLF formatting cleanup. Often, files cloned on Windows and mapped into Unix directories
    # get marked with CRLF line-endings, breaking bash runtime executions.
    log_info "Fixing line endings in tmux plugins (CRLF to LF)..."
    find "$HOME/.tmux/plugins" -type f \( -name "*.tmux" -o -name "*.sh" \) -exec dos2unix {} +
fi

GITCONFIG_LOCAL="$HOME/.gitconfig.local"
if [ -f "$GITCONFIG_LOCAL" ]; then
    log_success ".gitconfig.local already exists."
else
    log_info "Creating empty .gitconfig.local..."
    touch "$GITCONFIG_LOCAL"
fi

# ------------------------------------------------------------------------------
#  12. Interactive Shell Integration (Default to ZSH)
# ------------------------------------------------------------------------------
echo ""
echo -e "${GREEN}============================================"
echo " 🎉 Installation completed successfully!"
echo -e " ⚠️  Please reload your shell or restart your terminal"
echo "    to ensure all changes and utilities are fully functional."
echo -e "============================================${NC}"
echo ""

case "$SHELL" in
    *zsh)
        log_success "Default shell is already zsh." ;;
    *)
        if command -v zsh &> /dev/null; then
            log_info "Changing default shell to zsh..."
            if [ "$OS" = "Termux" ]; then
                chsh -s zsh
            else
                if command -v chsh &> /dev/null; then
                    sudo chsh -s "$(command -v zsh)" "$USER"
                else
                    log_warn "chsh command not found. Please change your default shell to zsh manually."
                fi
            fi
            log_info "Switching current session to zsh..."
            exec zsh -l </dev/tty;
        else
            log_warn "zsh is not installed. Cannot change default shell."
        fi
        ;;
esac
exit
'@
# '

# ==============================================================================
#  PowerShell Block - Executes on Windows Environments
# ==============================================================================

#region 1. PowerShell Logger Helpers
function Write-LogInfo ($message) {
    Write-Host "[INFO] $message" -ForegroundColor Blue
}

function Write-LogSuccess ($message) {
    Write-Host "[SUCCESS] $message" -ForegroundColor Green
}

function Write-LogWarning ($message) {
    Write-Host "[WARNING] $message" -ForegroundColor Yellow
}

function Write-LogError ($message) {
    Write-Host "[ERROR] $message" -ForegroundColor Red
}
#endregion

#region 2. Initialize Windows Setup Block
Write-LogInfo "Initializing Windows PowerShell setup block..."

# Command-line parameters / override parsing
$Force = $args -contains "--force" -or $args -contains "-f"

if ($Force) {
    Write-LogInfo "Force installation flag enabled."
}
#endregion

#region 3. Core Tools Installation (winget)
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    Write-LogSuccess "Oh My Posh is already installed."
} else {
    Write-LogInfo "Installing Oh My Posh via Windows Package Manager (winget)..."
    winget install -e --accept-source-agreements --accept-package-agreements JanDeDobbeleer.OhMyPosh --source winget
}
#endregion

#region 4. File Linking Helper (PowerShell)
# Helper designed to symlink repository configs into Windows active home profile directories.
# Performs safety copy fallback if the console user lacks Admin/Dev Mode context.
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
            # Verify if path is already symbolic link
            if ($item.Attributes -match "ReparsePoint") {
                $target = $item.Target
                if ($target -eq $SourcePath -or $target -eq (Get-Item $SourcePath).FullName) {
                    Write-LogSuccess "$Name is already linked to the repository's version."
                    $alreadyLinked = $true
                }
            }
            
            if (-not $alreadyLinked) {
                Write-LogInfo "Backing up existing $TargetPath to $TargetPath.bak..."
                if (Test-Path "$TargetPath.bak") {
                    Remove-Item "$TargetPath.bak" -Force
                }
                Move-Item $TargetPath "$TargetPath.bak" -Force
                Write-LogInfo "Creating symlink for $Name..."
                try {
                    New-Item -ItemType SymbolicLink -Path $TargetPath -Value $SourcePath -ErrorAction Stop | Out-Null
                } catch {
                    Write-LogWarning "Failed to create symlink (requires Admin or Developer Mode). Copying file instead..."
                    Copy-Item $SourcePath $TargetPath -Force
                }
            }
        } else {
            Write-LogInfo "Creating symlink for $Name..."
            try {
                New-Item -ItemType SymbolicLink -Path $TargetPath -Value $SourcePath -ErrorAction Stop | Out-Null
            } catch {
                Write-LogWarning "Failed to create symlink. Copying file instead..."
                Copy-Item $SourcePath $TargetPath -Force
            }
        }
    }
}
#endregion

#region 5. Clones & Workspaces Configuration
$nvimConfigPath = Join-Path $env:LOCALAPPDATA "nvim"
if (-not (Test-Path $nvimConfigPath)) {
    Write-LogInfo "Cloning Neovim configuration..."
    git clone -b akrista https://github.com/akrista/nvim $nvimConfigPath
} else {
    Write-LogInfo "Neovim configuration already exists at $nvimConfigPath. Pulling updates..."
    git -C $nvimConfigPath pull
}

$dotfilesPath = Join-Path $HOME ".akrista"
if (-not (Test-Path $dotfilesPath)) {
    Write-LogInfo "Cloning .akrista repository..."
    git clone https://github.com/akrista/.akrista $dotfilesPath
} else {
    Write-LogInfo ".akrista repository already exists at $dotfilesPath. Pulling updates..."
    git -C $dotfilesPath pull
}

if (Test-Path $dotfilesPath) {
    $checkFile = Join-Path $dotfilesPath ".last_update_check"
    New-Item -ItemType File -Path $checkFile -Force | Out-Null
}
#endregion

#region 6. Linking Windows Configurations
Write-LogInfo "Linking local configuration dotfiles..."
Link-File -SourcePath (Join-Path $dotfilesPath ".gitconfig") -TargetPath (Join-Path $HOME ".gitconfig") -Name ".gitconfig"
Link-File -SourcePath (Join-Path $dotfilesPath ".sqliterc") -TargetPath (Join-Path $HOME ".sqliterc") -Name ".sqliterc"

$gitConfigLocal = Join-Path $HOME ".gitconfig.local"
if (-not (Test-Path $gitConfigLocal)) {
    Write-LogInfo "Creating empty $gitConfigLocal..."
    New-Item -ItemType File -Path $gitConfigLocal -Force | Out-Null
}
#endregion

#region 7. Finish Notification
Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host " 🎉 Installation completed successfully!" -ForegroundColor Green
Write-Host " ⚠️  Please reload your shell or restart your terminal" -ForegroundColor Yellow
Write-Host "    to ensure all changes and utilities are fully functional." -ForegroundColor Yellow
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""
#endregion
