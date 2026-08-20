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

    # Remove dangling symlinks to prevent cp or linking errors
    if [ -L "$target_file" ] && [ ! -e "$target_file" ]; then
        log_warn "$name has a dangling symlink at $target_file. Cleaning up..."
        rm -f "$target_file"
    fi

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
#  4.5 Check Installation Capabilities & System Issues (Bash)
# ------------------------------------------------------------------------------
log_info "Verifying installation capabilities and system requirements..."

# 1. Verify that we have a supported package manager/OS
if [ "$PACKAGER" = "unknown" ]; then
    log_error "Unsupported OS/Environment ($OS) or package manager."
    log_error "This script requires one of the following package managers: pkg, apt, dnf, pacman, apk."
    log_error "Interrupting the script to prevent partial/failed installation."
    exit 1
fi

# 2. Check for privilege and permission issues
# Termux (pkg) runs in a user environment and doesn't require root/sudo.
# Other environments require either root or sudo privileges.
if [ "$PACKAGER" != "pkg" ]; then
    if [ "$EUID" -eq 0 ] || [ "$(id -u)" -eq 0 ]; then
        if [ "$PACKAGER" = "apt" ]; then
            show_sudo_debian_remediation_message "root"
        else
            log_error "You are currently running this script as root! Running dotfiles setup as root is not supported or recommended."
        fi
        exit 1
    fi

    if ! command -v sudo &> /dev/null; then
        if [ "$PACKAGER" = "apt" ]; then
            show_sudo_debian_remediation_message "no_sudo"
        else
            log_error "Error: 'sudo' command not found! Sudo is required to install system packages."
        fi
        exit 1
    fi

    if ! has_sudo_privileges; then
        if [ "$PACKAGER" = "apt" ]; then
            show_sudo_debian_remediation_message "no_privileges"
        else
            log_error "Error: Current user '$USER' does not have sudo privileges! Sudo privileges are required."
        fi
        exit 1
    fi
fi

# 3. Check for internet connectivity issues
log_info "Verifying internet connection..."
has_internet=false
if command -v curl &> /dev/null; then
    if curl -s --connect-timeout 5 https://www.google.com &>/dev/null || curl -s --connect-timeout 5 https://github.com &>/dev/null; then
        has_internet=true
    fi
elif command -v wget &> /dev/null; then
    if wget -q --spider --timeout=5 https://www.google.com &>/dev/null || wget -q --spider --timeout=5 https://github.com &>/dev/null; then
        has_internet=true
    fi
elif ping -c 1 -W 5 1.1.1.1 &>/dev/null || ping -c 1 -W 5 8.8.8.8 &>/dev/null; then
    has_internet=true
fi

if [ "$has_internet" = false ]; then
    log_error "No internet connection detected."
    log_error "An active internet connection is required to download packages and configure development tools."
    log_error "Interrupting the script."
    exit 1
fi

log_success "All pre-installation checks passed successfully!"

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

    # Termux User Repository (TUR) and glibc repositories
    if ! pkg_is_installed tur-repo || ! pkg_is_installed root-repo || ! pkg_is_installed glibc-repo; then
        log_info "Setting up Termux User Repository (tur-repo), root-repo, and glibc-repo..."
        pkg install -y tur-repo root-repo glibc-repo
    fi

    if [ "$FORCE" = true ] && [ -t 0 ]; then
        log_info "Interactive prompt requested. Changing Termux mirror repository..."
        termux-change-repo
    fi

    log_info "Installing comprehensive development suite..."
    pkg install -y proot-distro git curl wget neovim termux-api termux-services openssh zsh tree-sitter libllvm make ripgrep fd unzip gitui eza bat oh-my-posh tmux zig clang nnn fzf zoxide rust nodejs sqlite gh lua-language-server stylua dos2unix glibc-runner

    # Verify key utilities are functional and repair dependencies if broken
    if ! curl --version &>/dev/null || ! git --version &>/dev/null; then
        log_warn "Detected broken library links in curl/git. Running dependency self-repair..."
        pkg reinstall -y openssl git curl || apt install --reinstall -y openssl git curl
    fi

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

    # Outdated Neovim installs will break modern LSP configurations
    # We remove the package manager version and download the official upstream release later
    if pkg_is_installed neovim; then
        log_warn "Found outdated Neovim installed via apt. Removing it to prevent path collisions..."
        sudo apt-get remove -y neovim
    fi

    log_info "Updating system package lists and upgrading packages..."
    sudo apt update -y && sudo apt upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"

    log_info "Installing development dependencies and CLI tools..."
    sudo apt install -y make gcc ripgrep fd-find tree-sitter-cli git xclip wl-clipboard curl wget unzip zip tar rsync jq socat lsof p7zip-full gnupg mosh axel zsh ssh eza bat sqlite3 zoxide fzf nnn clang tmux nala locales dos2unix btop alacritty

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

    # Docker daemon configuration
    if [ -f "$DOTFILES_DIR/config/docker/daemon.json" ]; then
        if command -v docker &> /dev/null || [ -d "/etc/docker" ]; then
            log_info "Configuring Docker daemon settings (/etc/docker/daemon.json)..."
            sudo mkdir -p /etc/docker
            if [ ! -f /etc/docker/daemon.json ] || [ "$FORCE" = true ]; then
                sudo cp "$DOTFILES_DIR/config/docker/daemon.json" /etc/docker/daemon.json
                log_success "Docker daemon.json configured."
            fi
        fi
    fi

    # OpenSSH Server daemon hardening (Debian/Ubuntu)
    if [ -f "$DOTFILES_DIR/config/sshd/99-hardening.conf" ]; then
        if [ -d "/etc/ssh/sshd_config.d" ] || command -v sshd &> /dev/null; then
            log_info "Deploying SSHD hardening configuration (/etc/ssh/sshd_config.d/99-hardening.conf)..."
            sudo mkdir -p /etc/ssh/sshd_config.d
            sudo cp "$DOTFILES_DIR/config/sshd/99-hardening.conf" /etc/ssh/sshd_config.d/99-hardening.conf
            sudo chmod 644 /etc/ssh/sshd_config.d/99-hardening.conf

            # Validate syntax before reloading service
            if sudo sshd -t 2>/dev/null; then
                log_success "SSHD configuration validated successfully."
                if systemctl is-active --quiet ssh 2>/dev/null; then
                    sudo systemctl reload ssh 2>/dev/null || true
                fi
            else
                log_warn "SSHD configuration test failed. Reverting 99-hardening.conf..."
                sudo rm -f /etc/ssh/sshd_config.d/99-hardening.conf
            fi
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
    link_file "$DOTFILES_DIR/config/termux/termux.properties" "$HOME/.termux/termux.properties" "termux.properties"

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
else
    # Install MesloLGS NF fonts for desktop terminal emulators (alacritty/ghostty)
    MESLO_FONT_DIR="$HOME/.local/share/fonts/MesloLGS NF"
    if [ ! -f "$MESLO_FONT_DIR/MesloLGS NF Regular.ttf" ]; then
        log_info "Downloading and installing MesloLGS NF fonts..."
        mkdir -p "$MESLO_FONT_DIR"
        curl -fsSL -o "$MESLO_FONT_DIR/MesloLGS NF Regular.ttf" "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf"
        curl -fsSL -o "$MESLO_FONT_DIR/MesloLGS NF Bold.ttf" "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf"
        curl -fsSL -o "$MESLO_FONT_DIR/MesloLGS NF Italic.ttf" "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf"
        curl -fsSL -o "$MESLO_FONT_DIR/MesloLGS NF Bold Italic.ttf" "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf"
        command -v fc-cache &> /dev/null && fc-cache -f "$MESLO_FONT_DIR"
        log_success "MesloLGS NF fonts installed."
    else
        log_success "MesloLGS NF fonts are already installed."
    fi
fi

# Multi-platform development configurations (non-Termux architectures)
if [ "$OS" != "Termux" ]; then
    log_info "Setting up multi-platform runtime engines..."

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

    # Fast Node Manager (fnm)
    if ! command -v fnm &> /dev/null && [ ! -d "$HOME/.local/share/fnm" ]; then
        log_info "Installing Fast Node Manager (fnm)..."
        curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell
    else
        log_success "fnm is already installed."
    fi
    export PATH="$HOME/.local/share/fnm:$PATH"
    if command -v fnm &> /dev/null; then
        eval "$(fnm env)"
        log_info "Ensuring Node.js LTS is installed and configured via fnm..."
        fnm install --lts
        fnm default lts-latest
    fi

    # Deno Runtime
    if ! command -v deno &> /dev/null && [ ! -d "$HOME/.deno" ]; then
        log_info "Installing Deno..."
        curl -fsSL https://deno.land/install.sh | sh -s -- -y
    elif command -v deno &> /dev/null; then
        log_info "Checking for Deno updates..."
        deno upgrade 2>/dev/null || log_warn "Deno upgrade check failed."
    fi

    # Generate dynamic shell completions for Deno
    if command -v deno &> /dev/null || [ -x "$HOME/.deno/bin/deno" ]; then
        DENO_BIN="$(command -v deno 2>/dev/null || echo "$HOME/.deno/bin/deno")"
        mkdir -p "$HOME/.zsh/completions"
        "$DENO_BIN" completions zsh > "$HOME/.zsh/completions/_deno" 2>/dev/null || true
        mkdir -p "$HOME/.local/share/bash-completion/completions"
        "$DENO_BIN" completions bash > "$HOME/.local/share/bash-completion/completions/deno.bash" 2>/dev/null || true
    fi

    # Astral uv (Fast Python Package & Tool Manager)
    if ! command -v uv &> /dev/null && [ ! -f "$HOME/.local/bin/uv" ]; then
        log_info "Installing Astral uv (Python tool manager)..."
        curl -fsSL https://astral.sh/uv/install.sh | sh
    elif command -v uv &> /dev/null; then
        log_info "Checking for uv updates..."
        uv self update 2>/dev/null || true
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
    log_info "Updating Oh My Zsh..."
    if command -v zsh &> /dev/null; then
        zsh -c "export ZSH=\"\$HOME/.oh-my-zsh\"; \$ZSH/tools/upgrade.sh"
    fi
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

# Unified Global Node/NPM Packages & CLI Agents
log_info "Configuring CLI agents and global packages..."

# CLI Agent Installation (Antigravity CLI)
supports_agy=false
if [ "$OS" != "Termux" ] && [ "$(uname -m)" = "x86_64" ] && grep -q -E "avx|avx2" /proc/cpuinfo 2>/dev/null; then
    supports_agy=true
fi

if [ "$supports_agy" = true ]; then
    if [ ! -f "$HOME/.local/bin/agy" ]; then
        log_info "Installing Antigravity CLI (agy)..."
        curl -fsSL https://antigravity.google/cli/install.sh | bash
        log_success "Antigravity CLI installed successfully."
    else
        log_info "Antigravity CLI (agy) is already installed."
    fi
fi

# OpenCode Installation (Non-Termux)
if [ "$OS" != "Termux" ]; then
    if [ ! -f "$HOME/.opencode/bin/opencode" ]; then
        log_info "Installing OpenCode..."
        curl -fsSL https://opencode.ai/install | bash
        log_success "OpenCode installed successfully."
    else
        log_info "OpenCode is already installed."
    fi
fi

# Pi Coding Agent (installed via Bun)
if command -v bun &> /dev/null; then
    if ! command -v pi &> /dev/null; then
        log_info "Installing Pi coding agent via Bun..."
        bun add -g @earendil-works/pi-coding-agent
        log_success "Pi coding agent installed successfully."
    else
        log_info "Updating Pi coding agent via Bun..."
        bun update -g @earendil-works/pi-coding-agent
        log_success "Pi coding agent updated successfully."
    fi
elif command -v npm &> /dev/null; then
    if ! command -v pi &> /dev/null; then
        log_info "Installing Pi coding agent via npm..."
        npm i -g --ignore-scripts @earendil-works/pi-coding-agent
        log_success "Pi coding agent installed successfully."
    else
        log_info "Updating Pi coding agent via npm..."
        npm update -g @earendil-works/pi-coding-agent
        log_success "Pi coding agent updated successfully."
    fi
else
    log_warn "Neither bun nor npm found. Skipping global packages installation/updates."
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
link_file "$DOTFILES_DIR/config/zsh/.zshrc" "$HOME/.zshrc" ".zshrc"
link_file "$DOTFILES_DIR/config/bash/.bashrc" "$HOME/.bashrc" ".bashrc"
link_file "$DOTFILES_DIR/config/git/.gitconfig" "$HOME/.gitconfig" ".gitconfig"
link_file "$DOTFILES_DIR/config/sqlite/.sqliterc" "$HOME/.sqliterc" ".sqliterc"
link_file "$DOTFILES_DIR/config/tmux/.tmux.conf" "$HOME/.tmux.conf" ".tmux.conf"

# oxker reads config from $XDG_CONFIG_HOME/oxker/config.toml — ask which
# container backend it should target (Docker or Podman's rootless socket).
OXKER_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/oxker"
OXKER_CONFIG_FILE="$OXKER_CONFIG_DIR/config.toml"
mkdir -p "$OXKER_CONFIG_DIR"

if [ "$FORCE" = true ] || [ ! -e "$OXKER_CONFIG_FILE" ]; then
    OXKER_BACKEND="docker"
    if [ -t 0 ]; then
        echo ""
        read -rp "Configure oxker for Podman instead of Docker? [y/N] " oxker_ans
        [[ "$oxker_ans" =~ ^[Yy]$ ]] && OXKER_BACKEND="podman"
    fi

    if [ "$OXKER_BACKEND" = "podman" ]; then
        log_info "Configuring oxker for Podman (uid $(id -u))..."
        sed "s/__OXKER_UID__/$(id -u)/" "$DOTFILES_DIR/config/oxker/config.podman.toml" > "$OXKER_CONFIG_FILE"
        if command -v podman &> /dev/null && ! systemctl --user is-active --quiet podman.socket; then
            log_info "Enabling podman.socket (user) for oxker..."
            systemctl --user enable --now podman.socket
        fi
        log_success "oxker configured for Podman."
    else
        link_file "$DOTFILES_DIR/config/oxker/config.docker.toml" "$OXKER_CONFIG_FILE" "oxker config.toml (docker)"
    fi
else
    log_success "oxker config already exists at $OXKER_CONFIG_FILE. Use --force to reconfigure."
fi

# Alacritty reads config from $XDG_CONFIG_HOME/alacritty/alacritty.toml
ALACRITTY_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/alacritty"
mkdir -p "$ALACRITTY_CONFIG_DIR"
link_file "$DOTFILES_DIR/config/alacritty/alacritty.toml" "$ALACRITTY_CONFIG_DIR/alacritty.toml" "alacritty.toml"

# Zellij reads config from $XDG_CONFIG_HOME/zellij/config.kdl
ZELLIJ_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/zellij"
mkdir -p "$ZELLIJ_CONFIG_DIR"
link_file "$DOTFILES_DIR/config/zellij/config.kdl" "$ZELLIJ_CONFIG_DIR/config.kdl" "zellij config.kdl"

# Zed Editor config (~/.config/zed/settings.json - Gitignored local file symlinked from repo)
ZED_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/zed"
mkdir -p "$ZED_CONFIG_DIR"
ZED_REPO_LOCAL="$DOTFILES_DIR/config/zed/settings.json"
if [ ! -f "$ZED_REPO_LOCAL" ]; then
    log_info "Initializing config/zed/settings.json from template..."
    if [ -f "$DOTFILES_DIR/config/zed/settings.json.example" ]; then
        cp "$DOTFILES_DIR/config/zed/settings.json.example" "$ZED_REPO_LOCAL"
        chmod 600 "$ZED_REPO_LOCAL"
    fi
fi
link_file "$ZED_REPO_LOCAL" "$ZED_CONFIG_DIR/settings.json" "zed settings.json"

# Claude Code configuration (~/.claude/settings.json - Gitignored local file symlinked from repo)
CLAUDE_DIR="$HOME/.claude"
mkdir -p "$CLAUDE_DIR"
CLAUDE_REPO_LOCAL="$DOTFILES_DIR/slop/claude/settings.json"
if [ ! -f "$CLAUDE_REPO_LOCAL" ]; then
    log_info "Initializing slop/claude/settings.json from template..."
    if [ -f "$DOTFILES_DIR/slop/claude/settings.json.example" ]; then
        cp "$DOTFILES_DIR/slop/claude/settings.json.example" "$CLAUDE_REPO_LOCAL"
        chmod 600 "$CLAUDE_REPO_LOCAL"
    fi
fi
link_file "$CLAUDE_REPO_LOCAL" "$CLAUDE_DIR/settings.json" "claude settings.json"

# Claude Code global profile (~/.claude.json - Gitignored local file symlinked from repo)
CLAUDE_JSON_LOCAL="$DOTFILES_DIR/slop/claude/.claude.json"
if [ ! -f "$CLAUDE_JSON_LOCAL" ]; then
    log_info "Initializing slop/claude/.claude.json from template..."
    if [ -f "$DOTFILES_DIR/slop/claude/.claude.json.example" ]; then
        cp "$DOTFILES_DIR/slop/claude/.claude.json.example" "$CLAUDE_JSON_LOCAL"
        chmod 600 "$CLAUDE_JSON_LOCAL"
    fi
fi
link_file "$CLAUDE_JSON_LOCAL" "$HOME/.claude.json" ".claude.json"

# OpenCode configuration (~/.config/opencode/opencode.json - Gitignored local file symlinked from repo)
OPENCODE_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
mkdir -p "$OPENCODE_CONFIG_DIR"
OPENCODE_REPO_LOCAL="$DOTFILES_DIR/slop/opencode/opencode.json"
if [ ! -f "$OPENCODE_REPO_LOCAL" ]; then
    log_info "Initializing slop/opencode/opencode.json from template..."
    if [ -f "$DOTFILES_DIR/slop/opencode/opencode.json.example" ]; then
        cp "$DOTFILES_DIR/slop/opencode/opencode.json.example" "$OPENCODE_REPO_LOCAL"
        chmod 600 "$OPENCODE_REPO_LOCAL"
    fi
fi
link_file "$OPENCODE_REPO_LOCAL" "$OPENCODE_CONFIG_DIR/opencode.json" "opencode opencode.json"
link_file "$OPENCODE_REPO_LOCAL" "$OPENCODE_CONFIG_DIR/config.json" "opencode config.json"

# OpenCode Desktop App State (~/.config/ai.opencode.desktop/opencode.global.dat)
OPENCODE_DESKTOP_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ai.opencode.desktop"
mkdir -p "$OPENCODE_DESKTOP_DIR"
OPENCODE_DAT_LOCAL="$DOTFILES_DIR/slop/opencode/opencode.global.dat"
if [ ! -f "$OPENCODE_DAT_LOCAL" ]; then
    if [ -f "$DOTFILES_DIR/slop/opencode/opencode.global.dat.example" ]; then
        cp "$DOTFILES_DIR/slop/opencode/opencode.global.dat.example" "$OPENCODE_DAT_LOCAL"
    else
        touch "$OPENCODE_DAT_LOCAL"
    fi
fi
link_file "$OPENCODE_DAT_LOCAL" "$OPENCODE_DESKTOP_DIR/opencode.global.dat" "opencode desktop global.dat"

# Antigravity (agy) configuration (~/.gemini/config/{config.json,mcp_config.json} - Gitignored local file symlinked from repo)
GEMINI_CONFIG_DIR="$HOME/.gemini/config"
mkdir -p "$GEMINI_CONFIG_DIR"

AGY_CONFIG_LOCAL="$DOTFILES_DIR/slop/agy/config.json"
if [ ! -f "$AGY_CONFIG_LOCAL" ]; then
    log_info "Initializing slop/agy/config.json from template..."
    if [ -f "$DOTFILES_DIR/slop/agy/config.json.example" ]; then
        cp "$DOTFILES_DIR/slop/agy/config.json.example" "$AGY_CONFIG_LOCAL"
        chmod 600 "$AGY_CONFIG_LOCAL"
    fi
fi
link_file "$AGY_CONFIG_LOCAL" "$GEMINI_CONFIG_DIR/config.json" "antigravity config.json"

AGY_MCP_LOCAL="$DOTFILES_DIR/slop/agy/mcp_config.json"
if [ ! -f "$AGY_MCP_LOCAL" ]; then
    log_info "Initializing slop/agy/mcp_config.json from template..."
    if [ -f "$DOTFILES_DIR/slop/agy/mcp_config.json.example" ]; then
        cp "$DOTFILES_DIR/slop/agy/mcp_config.json.example" "$AGY_MCP_LOCAL"
        chmod 600 "$AGY_MCP_LOCAL"
    fi
fi
link_file "$AGY_MCP_LOCAL" "$GEMINI_CONFIG_DIR/mcp_config.json" "antigravity mcp_config.json"

# Agent Skills Global Installation & Synchronization
link_file "$DOTFILES_DIR/slop/skills-lock.json" "$HOME/skills-lock.json" "skills-lock.json"

# Restore ALL skills — community and custom alike — from skills-lock.json.
# Custom skills (slop/skills/custom/skills/) are tracked in skills-lock.json the
# same way as community ones (source: Akrista/.akrista); there is no separate
# direct-symlink step — the skills CLI is the single mechanism for all of them.
if [ -f "$DOTFILES_DIR/slop/skills-lock.json" ] && command -v bunx &> /dev/null; then
    log_info "Synchronizing Agent Skills via bunx skills..."
    (cd "$HOME" && bunx -y skills experimental_install 2>/dev/null || true)
fi

# Link the global AI guideline file to every tool's global instructions path
GUIDELINES_FILE="$DOTFILES_DIR/slop/guidelines/AGENTS.md"
if [ -f "$GUIDELINES_FILE" ]; then
    link_file "$GUIDELINES_FILE" "$HOME/.claude/CLAUDE.md" "Claude Code global CLAUDE.md"
    mkdir -p "$HOME/.config/opencode"
    link_file "$GUIDELINES_FILE" "$HOME/.config/opencode/AGENTS.md" "OpenCode global AGENTS.md"
    mkdir -p "$HOME/.gemini" "$HOME/.pi/agent"
    link_file "$GUIDELINES_FILE" "$HOME/.gemini/GEMINI.md" "Antigravity (agy) global GEMINI.md"
    link_file "$GUIDELINES_FILE" "$HOME/.gemini/AGENTS.md" "Antigravity (agy) global AGENTS.md (cross-tool)"
    link_file "$GUIDELINES_FILE" "$HOME/.pi/agent/AGENTS.md" "Pi global AGENTS.md"
fi

# Symlink bat and fd for standard naming on Debian/Ubuntu
mkdir -p "$HOME/.local/bin"
if command -v batcat &> /dev/null && [ ! -e "$HOME/.local/bin/bat" ]; then
    ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
fi
if command -v fdfind &> /dev/null && [ ! -e "$HOME/.local/bin/fd" ]; then
    ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
fi

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

# Local Git Configuration (~/.gitconfig.local - Gitignored local file symlinked from repo)
GIT_REPO_LOCAL="$DOTFILES_DIR/config/git/.gitconfig.local"
if [ ! -f "$GIT_REPO_LOCAL" ]; then
    log_info "Initializing config/git/.gitconfig.local from template..."
    if [ -f "$DOTFILES_DIR/config/git/.gitconfig.local.example" ]; then
        cp "$DOTFILES_DIR/config/git/.gitconfig.local.example" "$GIT_REPO_LOCAL"
    else
        touch "$GIT_REPO_LOCAL"
    fi
    chmod 600 "$GIT_REPO_LOCAL"
fi
link_file "$GIT_REPO_LOCAL" "$HOME/.gitconfig.local" ".gitconfig.local"

# Local Environment Variables (~/.env.local - Gitignored local file symlinked from repo)
ENV_REPO_LOCAL="$DOTFILES_DIR/config/env/.env.local"
if [ ! -f "$ENV_REPO_LOCAL" ]; then
    log_info "Initializing config/env/.env.local from template..."
    if [ -f "$DOTFILES_DIR/config/env/.env.local.example" ]; then
        cp "$DOTFILES_DIR/config/env/.env.local.example" "$ENV_REPO_LOCAL"
    else
        touch "$ENV_REPO_LOCAL"
    fi
    chmod 600 "$ENV_REPO_LOCAL"
fi
link_file "$ENV_REPO_LOCAL" "$HOME/.env.local" ".env.local"

# SSH Client Configuration (~/.ssh/config with Include pattern & gitignored config.local)
SSH_DIR="$HOME/.ssh"
mkdir -p "$SSH_DIR" && chmod 700 "$SSH_DIR"
SSH_REPO_LOCAL="$DOTFILES_DIR/config/ssh/config.local"
if [ ! -f "$SSH_REPO_LOCAL" ]; then
    log_info "Initializing config/ssh/config.local from template..."
    if [ -f "$DOTFILES_DIR/config/ssh/config.local.example" ]; then
        cp "$DOTFILES_DIR/config/ssh/config.local.example" "$SSH_REPO_LOCAL"
    else
        touch "$SSH_REPO_LOCAL"
    fi
    chmod 600 "$SSH_REPO_LOCAL"
fi
link_file "$SSH_REPO_LOCAL" "$SSH_DIR/config.local" ".ssh/config.local"

SSH_CONFIG_FILE="$SSH_DIR/config"
if [ "$FORCE" = true ] || [ ! -f "$SSH_CONFIG_FILE" ]; then
    log_info "Populating ~/.ssh/config with Include directives..."
    cat << 'EOF' > "$SSH_CONFIG_FILE"
# ==============================================================================
#  🔑 OpenSSH Client Configuration
# ==============================================================================
# Local/Private host overrides (untracked)
Include ~/.ssh/config.local

# Base shared configurations from .akrista dotfiles
Include ~/.akrista/config/ssh/config
EOF
    chmod 600 "$SSH_CONFIG_FILE"
    log_success "~/.ssh/config configured."
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

# Astral uv (Fast Python Package & Tool Manager)
if (Get-Command uv -ErrorAction SilentlyContinue) {
    Write-LogSuccess "Astral uv is already installed."
} else {
    Write-LogInfo "Installing Astral uv via official installer..."
    Invoke-RestMethod https://astral.sh/uv/install.ps1 | Invoke-Expression
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

$pwshPfPath = Join-Path $HOME ".pwsh-pf"
if (-not (Test-Path $pwshPfPath)) {
    Write-LogInfo "Cloning pwsh-pf repository..."
    git clone https://github.com/akrista/pwsh-pf $pwshPfPath
} else {
    Write-LogInfo "pwsh-pf repository already exists at $pwshPfPath. Pulling updates..."
    git -C $pwshPfPath pull
}
#endregion

#region 6. PowerShell Profile Setup (pwsh-pf)
Write-LogInfo "Setting up PowerShell profile and tools via pwsh-pf setup..."
$pwshPfSetupScript = Join-Path $pwshPfPath "setup.ps1"
if (Test-Path $pwshPfSetupScript) {
    & $pwshPfSetupScript
} else {
    Write-LogInfo "Fetching and executing pwsh-pf setup script from repository..."
    Invoke-Expression (Invoke-RestMethod -Uri "https://raw.githubusercontent.com/akrista/pwsh-pf/master/setup.ps1")
}
#endregion

#region 7. Linking Windows Configurations
Write-LogInfo "Linking local configuration dotfiles..."
Link-File -SourcePath (Join-Path $dotfilesPath "config/git/.gitconfig") -TargetPath (Join-Path $HOME ".gitconfig") -Name ".gitconfig"
Link-File -SourcePath (Join-Path $dotfilesPath "config/sqlite/.sqliterc") -TargetPath (Join-Path $HOME ".sqliterc") -Name ".sqliterc"

# Alacritty reads config from %APPDATA%\alacritty\alacritty.toml (Windows overlay imports the shared base)
$alacrittyDir = Join-Path $env:APPDATA "alacritty"
New-Item -ItemType Directory -Path $alacrittyDir -Force | Out-Null
Link-File -SourcePath (Join-Path $dotfilesPath "config/alacritty/alacritty.windows.toml") -TargetPath (Join-Path $alacrittyDir "alacritty.toml") -Name "alacritty.toml"

# Zellij reads config from %APPDATA%\zellij\config.kdl or $HOME\.config\zellij\config.kdl
$zellijDir = Join-Path $HOME ".config\zellij"
New-Item -ItemType Directory -Path $zellijDir -Force | Out-Null
Link-File -SourcePath (Join-Path $dotfilesPath "config/zellij/config.kdl") -TargetPath (Join-Path $zellijDir "config.kdl") -Name "zellij config.kdl"

# Zed Editor config (%APPDATA%\Zed\settings.json - Gitignored local file symlinked from repo)
$zedDir = Join-Path $env:APPDATA "Zed"
New-Item -ItemType Directory -Path $zedDir -Force | Out-Null
$zedRepoLocal = Join-Path $dotfilesPath "config/zed/settings.json"
if (-not (Test-Path $zedRepoLocal)) {
    Write-LogInfo "Initializing config/zed/settings.json from template..."
    $zedExample = Join-Path $dotfilesPath "config/zed/settings.json.example"
    if (Test-Path $zedExample) {
        Copy-Item $zedExample $zedRepoLocal
    }
}
Link-File -SourcePath $zedRepoLocal -TargetPath (Join-Path $zedDir "settings.json") -Name "zed settings.json"

# Claude Code configuration (%USERPROFILE%\.claude\settings.json - Gitignored local file symlinked from repo)
$claudeDir = Join-Path $HOME ".claude"
New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null
$claudeRepoLocal = Join-Path $dotfilesPath "slop/claude/settings.json"
if (-not (Test-Path $claudeRepoLocal)) {
    Write-LogInfo "Initializing slop/claude/settings.json from template..."
    $claudeExample = Join-Path $dotfilesPath "slop/claude/settings.json.example"
    if (Test-Path $claudeExample) {
        Copy-Item $claudeExample $claudeRepoLocal
    }
}
Link-File -SourcePath $claudeRepoLocal -TargetPath (Join-Path $claudeDir "settings.json") -Name "claude settings.json"

# Claude Code global profile (%USERPROFILE%\.claude.json)
$claudeJsonLocal = Join-Path $dotfilesPath "slop/claude/.claude.json"
if (-not (Test-Path $claudeJsonLocal)) {
    Write-LogInfo "Initializing slop/claude/.claude.json from template..."
    $claudeJsonExample = Join-Path $dotfilesPath "slop/claude/.claude.json.example"
    if (Test-Path $claudeJsonExample) {
        Copy-Item $claudeJsonExample $claudeJsonLocal
    }
}
Link-File -SourcePath $claudeJsonLocal -TargetPath (Join-Path $HOME ".claude.json") -Name ".claude.json"

# OpenCode configuration (%USERPROFILE%\.config\opencode\opencode.json - Gitignored local file symlinked from repo)
$opencodeDir = Join-Path $HOME ".config\opencode"
New-Item -ItemType Directory -Path $opencodeDir -Force | Out-Null
$opencodeRepoLocal = Join-Path $dotfilesPath "slop/opencode/opencode.json"
if (-not (Test-Path $opencodeRepoLocal)) {
    Write-LogInfo "Initializing slop/opencode/opencode.json from template..."
    $opencodeExample = Join-Path $dotfilesPath "slop/opencode/opencode.json.example"
    if (Test-Path $opencodeExample) {
        Copy-Item $opencodeExample $opencodeRepoLocal
    }
}
Link-File -SourcePath $opencodeRepoLocal -TargetPath (Join-Path $opencodeDir "opencode.json") -Name "opencode.json"
Link-File -SourcePath $opencodeRepoLocal -TargetPath (Join-Path $opencodeDir "config.json") -Name "opencode config.json"

# OpenCode Desktop App State (%APPDATA%\ai.opencode.desktop\opencode.global.dat)
$opencodeDesktopDir = Join-Path $env:APPDATA "ai.opencode.desktop"
New-Item -ItemType Directory -Path $opencodeDesktopDir -Force | Out-Null
$opencodeDatLocal = Join-Path $dotfilesPath "slop/opencode/opencode.global.dat"
if (-not (Test-Path $opencodeDatLocal)) {
    $opencodeDatExample = Join-Path $dotfilesPath "slop/opencode/opencode.global.dat.example"
    if (Test-Path $opencodeDatExample) {
        Copy-Item $opencodeDatExample $opencodeDatLocal
    } else {
        New-Item -ItemType File -Path $opencodeDatLocal -Force | Out-Null
    }
}
Link-File -SourcePath $opencodeDatLocal -TargetPath (Join-Path $opencodeDesktopDir "opencode.global.dat") -Name "opencode desktop global.dat"

# Antigravity (agy) configuration (%USERPROFILE%\.gemini\config\{config.json,mcp_config.json} - Gitignored local file symlinked from repo)
$geminiConfigDir = Join-Path $HOME ".gemini\config"
New-Item -ItemType Directory -Path $geminiConfigDir -Force | Out-Null

$agyConfigLocal = Join-Path $dotfilesPath "slop/agy/config.json"
if (-not (Test-Path $agyConfigLocal)) {
    Write-LogInfo "Initializing slop/agy/config.json from template..."
    $agyConfigExample = Join-Path $dotfilesPath "slop/agy/config.json.example"
    if (Test-Path $agyConfigExample) {
        Copy-Item $agyConfigExample $agyConfigLocal
    }
}
Link-File -SourcePath $agyConfigLocal -TargetPath (Join-Path $geminiConfigDir "config.json") -Name "antigravity config.json"

$agyMcpLocal = Join-Path $dotfilesPath "slop/agy/mcp_config.json"
if (-not (Test-Path $agyMcpLocal)) {
    Write-LogInfo "Initializing slop/agy/mcp_config.json from template..."
    $agyMcpExample = Join-Path $dotfilesPath "slop/agy/mcp_config.json.example"
    if (Test-Path $agyMcpExample) {
        Copy-Item $agyMcpExample $agyMcpLocal
    }
}
Link-File -SourcePath $agyMcpLocal -TargetPath (Join-Path $geminiConfigDir "mcp_config.json") -Name "antigravity mcp_config.json"

# Agent Skills Global Installation & Synchronization
$skillsLockLocal = Join-Path $dotfilesPath "slop/skills-lock.json"
Link-File -SourcePath $skillsLockLocal -TargetPath (Join-Path $HOME "skills-lock.json") -Name "skills-lock.json"

# Restore ALL skills — community and custom alike — from skills-lock.json.
# Custom skills (slop/skills/custom/skills/) are tracked in skills-lock.json the
# same way as community ones (source: Akrista/.akrista); there is no separate
# direct-symlink step — the skills CLI is the single mechanism for all of them.
if ((Test-Path $skillsLockLocal) -and (Get-Command bunx -ErrorAction SilentlyContinue)) {
    Write-LogInfo "Synchronizing Agent Skills via bunx skills..."
    try {
        Push-Location $HOME
        bunx -y skills experimental_install 2>$null
    } catch {
        Write-LogWarning "Could not run skills automatically."
    } finally {
        Pop-Location
    }
}

# Link the global AI guideline file to every tool's global instructions path
$guidelinesFile = Join-Path $dotfilesPath "slop/guidelines/AGENTS.md"
if (Test-Path $guidelinesFile) {
    Link-File -SourcePath $guidelinesFile -TargetPath (Join-Path $HOME ".claude\CLAUDE.md") -Name "Claude Code global CLAUDE.md"
    $opencodeGlobalDir = Join-Path $HOME ".config\opencode"
    New-Item -ItemType Directory -Path $opencodeGlobalDir -Force | Out-Null
    Link-File -SourcePath $guidelinesFile -TargetPath (Join-Path $opencodeGlobalDir "AGENTS.md") -Name "OpenCode global AGENTS.md"
    $geminiDir = Join-Path $HOME ".gemini"
    $piAgentDir = Join-Path $HOME ".pi\agent"
    New-Item -ItemType Directory -Path $geminiDir -Force | Out-Null
    New-Item -ItemType Directory -Path $piAgentDir -Force | Out-Null
    Link-File -SourcePath $guidelinesFile -TargetPath (Join-Path $geminiDir "GEMINI.md") -Name "Antigravity (agy) global GEMINI.md"
    Link-File -SourcePath $guidelinesFile -TargetPath (Join-Path $geminiDir "AGENTS.md") -Name "Antigravity (agy) global AGENTS.md (cross-tool)"
    Link-File -SourcePath $guidelinesFile -TargetPath (Join-Path $piAgentDir "AGENTS.md") -Name "Pi global AGENTS.md"
}

# Local Git Configuration (~/.gitconfig.local - Gitignored local file symlinked from repo)
$gitRepoLocal = Join-Path $dotfilesPath "config/git/.gitconfig.local"
if (-not (Test-Path $gitRepoLocal)) {
    Write-LogInfo "Initializing config/git/.gitconfig.local from template..."
    $gitExample = Join-Path $dotfilesPath "config/git/.gitconfig.local.example"
    if (Test-Path $gitExample) {
        Copy-Item $gitExample $gitRepoLocal
    } else {
        New-Item -ItemType File -Path $gitRepoLocal -Force | Out-Null
    }
}
Link-File -SourcePath $gitRepoLocal -TargetPath (Join-Path $HOME ".gitconfig.local") -Name ".gitconfig.local"

# Local Environment Variables (~/.env.local - Gitignored local file symlinked from repo)
$envRepoLocal = Join-Path $dotfilesPath "config/env/.env.local"
if (-not (Test-Path $envRepoLocal)) {
    Write-LogInfo "Initializing config/env/.env.local from template..."
    $envExample = Join-Path $dotfilesPath "config/env/.env.local.example"
    if (Test-Path $envExample) {
        Copy-Item $envExample $envRepoLocal
    } else {
        New-Item -ItemType File -Path $envRepoLocal -Force | Out-Null
    }
}
Link-File -SourcePath $envRepoLocal -TargetPath (Join-Path $HOME ".env.local") -Name ".env.local"

# SSH Client Configuration (%USERPROFILE%\.ssh\config & gitignored config.local)
$sshDir = Join-Path $HOME ".ssh"
if (-not (Test-Path $sshDir)) {
    New-Item -ItemType Directory -Path $sshDir -Force | Out-Null
}

$sshRepoLocal = Join-Path $dotfilesPath "config/ssh/config.local"
if (-not (Test-Path $sshRepoLocal)) {
    Write-LogInfo "Initializing config/ssh/config.local from template..."
    $sshExample = Join-Path $dotfilesPath "config/ssh/config.local.example"
    if (Test-Path $sshExample) {
        Copy-Item $sshExample $sshRepoLocal
    } else {
        New-Item -ItemType File -Path $sshRepoLocal -Force | Out-Null
    }
}
Link-File -SourcePath $sshRepoLocal -TargetPath (Join-Path $sshDir "config.local") -Name ".ssh/config.local"

$sshConfigFile = Join-Path $sshDir "config"
if ($Force -or (-not (Test-Path $sshConfigFile))) {
    Write-LogInfo "Populating ~/.ssh/config..."
    @"
# ==============================================================================
#  🔑 OpenSSH Client Configuration
# ==============================================================================
# Local/Private host overrides (untracked)
Include ~/.ssh/config.local

# Base shared configurations from .akrista dotfiles
Include ~/.akrista/config/ssh/config
"@ | Out-File -FilePath $sshConfigFile -Encoding utf8
}
#endregion

#region 8. Finish Notification
Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host " 🎉 Installation completed successfully!" -ForegroundColor Green
Write-Host " ⚠️  Please reload your shell or restart your terminal" -ForegroundColor Yellow
Write-Host "    to ensure all changes and utilities are fully functional." -ForegroundColor Yellow
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""
#endregion
