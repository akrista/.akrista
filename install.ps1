#!/usr/bin/env bash
# Polyglot installer for Bash (Linux/Termux/macOS) and PowerShell (Windows).

function REM() { return; }
REM @'
REM '; : << "BASH"
BASH

# Logging helpers
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

log_info "Initializing setup..."

# Argument parsing
FORCE=false
for arg in "$@"; do
    case $arg in
        --force|-f)
            FORCE=true
            log_info "Force flag enabled."
            ;;
    esac
done

# OS and package manager detection
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

log_info "Detected OS: $OS"
log_info "Detected Package Manager: $PACKAGER"

IS_PROOT_DISTRO=false
if uname -a | grep -q "PRoot-Distro"; then
    IS_PROOT_DISTRO=true
    log_info "PRoot-Distro environment detected."
fi

DOTFILES_DIR="$HOME/.akrista"

show_sudo_debian_remediation_message() {
    local reason="$1"
    echo ""
    echo -e "${RED}========================================================================"
    echo " SYSTEM CONFIGURATION ERROR"
    echo -e "========================================================================${NC}"
    if [ "$reason" = "root" ]; then
        echo " Error: Running dotfiles setup as root is not supported."
    elif [ "$reason" = "no_sudo" ]; then
        echo " Error: 'sudo' command not found."
    else
        echo " Error: Current user '$USER' does not have sudo privileges."
    fi
    echo ""
    echo " Steps to configure sudo on Debian:"
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
    echo " 4. Ensure an editor is installed:"
    echo "    apt install -y neovim"
    echo ""
    echo " 5. Add user privilege with visudo:"
    echo "    visudo"
    echo "    # Add line under user privilege specification:"
    echo "    username ALL=(ALL:ALL) ALL"
    echo ""
    echo " 6. Switch to your user and rerun the installer:"
    echo "    su - username"
    echo "    cd ~/.username"
    echo "    ./install.ps1"
    echo -e "${RED}========================================================================${NC}"
    echo ""
}

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
    log_info "Checking sudo access..."
    if sudo -v &> /dev/null; then
        return 0
    else
        return 1
    fi
}

link_file() {
    local source_file="$1"
    local target_file="$2"
    local name="$3"

    if [ -L "$target_file" ] && [ ! -e "$target_file" ]; then
        log_warn "$name has a dangling symlink at $target_file. Cleaning up..."
        rm -f "$target_file"
    fi

    [ ! -e "$source_file" ] && log_warn "Repository's $name not found at $source_file" && return

    if [ -L "$target_file" ] && [ "$(readlink "$target_file")" = "$source_file" ]; then
        log_success "$name is already linked to the repository version."
    else
        log_info "Creating symlink for $name..."
        if [ -e "$target_file" ] || [ -L "$target_file" ]; then
            log_info "Backing up existing $target_file to $target_file.bak..."
            mv "$target_file" "$target_file.bak"
        fi
        ln -s "$source_file" "$target_file"
    fi
}

pkg_is_installed() {
    if [ "$PACKAGER" = "pkg" ] || [ "$PACKAGER" = "apt" ]; then
        dpkg -s "$1" &> /dev/null
    elif [ "$PACKAGER" = "dnf" ]; then
        rpm -q "$1" &> /dev/null || command -v "$1" &> /dev/null
    else
        command -v "$1" &> /dev/null
    fi
}

log_info "Verifying system requirements..."

if [ "$PACKAGER" = "unknown" ]; then
    log_error "Unsupported OS/Environment ($OS) or package manager."
    log_error "This script requires one of: pkg, apt, dnf, pacman, apk."
    exit 1
fi

if [ "$PACKAGER" != "pkg" ]; then
    if [ "$EUID" -eq 0 ] || [ "$(id -u)" -eq 0 ]; then
        if [ "$PACKAGER" = "apt" ]; then
            show_sudo_debian_remediation_message "root"
        else
            log_error "Running dotfiles setup as root is not supported."
        fi
        exit 1
    fi

    if ! command -v sudo &> /dev/null; then
        if [ "$PACKAGER" = "apt" ]; then
            show_sudo_debian_remediation_message "no_sudo"
        else
            log_error "Error: 'sudo' command not found."
        fi
        exit 1
    fi

    if ! has_sudo_privileges; then
        if [ "$PACKAGER" = "apt" ]; then
            show_sudo_debian_remediation_message "no_privileges"
        else
            log_error "Error: User '$USER' does not have sudo privileges."
        fi
        exit 1
    fi
fi

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
    exit 1
fi

log_success "Pre-installation checks passed."

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

    log_info "Installing development suite..."
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
            [ -d "$PREFIX/var/service/ssh-agent" ] || { log_info "Enabling ssh-agent service..."; sv-enable ssh-agent || log_warn "Could not enable ssh-agent automatically."; }
        else
            log_warn "sv-enable command not found."
        fi
    fi

    if [ ! -d "$HOME/storage" ]; then
        log_info "Setting up Termux storage access..."
        termux-setup-storage
    fi
}

install_debian_ubuntu_packages() {
    log_info "Starting package installation for Debian/Ubuntu..."

    if pkg_is_installed neovim; then
        log_warn "Removing distro Neovim to prevent collisions with official release..."
        sudo apt-get remove -y neovim
    fi

    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [ "$ID" = "debian" ] && [ "${VERSION_ID:-0}" -le 12 ]; then
            log_warn "Debian $VERSION_ID ($VERSION_CODENAME) detected."
            log_warn "Several modern developer packages (eza, fastfetch, tree-sitter, scrcpy) are not available in Debian 12 apt repositories."
            log_warn "Upgrading to Debian 13 (Trixie)+ is recommended for full native package management."
        fi
    fi

    log_info "Enabling contrib repository in apt sources..."
    if [ -f /etc/apt/sources.list ]; then
        sudo sed -i 's/^deb \(.*\) main$/deb \1 main contrib non-free-firmware/' /etc/apt/sources.list
        sudo sed -i 's/^deb-src \(.*\) main$/deb-src \1 main contrib non-free-firmware/' /etc/apt/sources.list
    fi

    log_info "Updating system package lists and upgrading packages..."
    sudo apt update -y && sudo apt upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"

    log_info "Installing development dependencies and CLI tools..."
    sudo apt install -y make gcc ripgrep fd-find git xclip wl-clipboard curl wget unzip zip tar rsync jq socat lsof p7zip-full gnupg mosh axel zsh ssh bat sqlite3 zoxide fzf nnn clang tmux locales dos2unix btop adb || true

    for opt_pkg in tree-sitter-cli fastfetch scrcpy alacritty nala eza; do
        sudo apt install -y "$opt_pkg" 2>/dev/null || true
    done

    log_info "Configuring UTF-8 locales..."
    if ! grep -q "^en_US.UTF-8 UTF-8" /etc/locale.gen; then
        echo "en_US.UTF-8 UTF-8" | sudo tee -a /etc/locale.gen
        sudo locale-gen en_US.UTF-8
    fi
    sudo update-locale LANG=en_US.UTF-8

    if [ "$FORCE" = true ] || ! command -v nvim &> /dev/null; then
        log_info "Installing official Neovim build..."
        ARCH=$(uname -m)
        case "$ARCH" in
            x86_64) NVIM_ARCH="x86_64" ;;
            aarch64|arm64) NVIM_ARCH="arm64" ;;
            *)
                log_warn "Unsupported architecture for official Neovim build: $ARCH. Falling back to apt."
                sudo apt install -y neovim
                NVIM_ARCH="unknown"
                ;;
        esac

        if [ "$NVIM_ARCH" != "unknown" ]; then
            TEMP_DIR=$(mktemp -d)
            (
                cd "$TEMP_DIR" || exit 1
                NVIM_TAR="nvim-linux-$NVIM_ARCH.tar.gz"
                log_info "Downloading $NVIM_TAR..."
                curl -LO "https://github.com/neovim/neovim/releases/latest/download/$NVIM_TAR"
                sudo rm -rf "/opt/nvim-linux-$NVIM_ARCH"
                sudo mkdir -p "/opt/nvim-linux-$NVIM_ARCH"
                sudo tar -C /opt -xzf "$NVIM_TAR"
                sudo chmod -R a+rX "/opt/nvim-linux-$NVIM_ARCH"
                sudo ln -sf "/opt/nvim-linux-$NVIM_ARCH/bin/nvim" /usr/local/bin/nvim
            )
            rm -rf "$TEMP_DIR"
            log_success "Neovim installation completed."
        fi
    else
        log_info "Neovim is already installed."
    fi

    if ! command -v pacstall &> /dev/null; then
        log_info "Installing Pacstall..."
        sudo bash -c "$(curl -fsSL https://pacstall.dev/q/install)"
    else
        log_info "Pacstall is already installed."
    fi

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

    if [ -f "$DOTFILES_DIR/config/docker/daemon.json" ]; then
        if command -v docker &> /dev/null || [ -d "/etc/docker" ]; then
            log_info "Configuring Docker daemon..."
            sudo mkdir -p /etc/docker
            if [ ! -f /etc/docker/daemon.json ] || [ "$FORCE" = true ]; then
                sudo cp "$DOTFILES_DIR/config/docker/daemon.json" /etc/docker/daemon.json
                log_success "Docker daemon.json configured."
            fi
        fi
    fi

    if [ -f "$DOTFILES_DIR/config/sshd/99-hardening.conf" ]; then
        if [ -d "/etc/ssh/sshd_config.d" ] || command -v sshd &> /dev/null; then
            log_info "Deploying SSHD hardening configuration..."
            sudo mkdir -p /etc/ssh/sshd_config.d
            sudo cp "$DOTFILES_DIR/config/sshd/99-hardening.conf" /etc/ssh/sshd_config.d/99-hardening.conf
            sudo chmod 644 /etc/ssh/sshd_config.d/99-hardening.conf

            if sudo sshd -t 2>/dev/null; then
                log_success "SSHD configuration validated."
                if systemctl is-active --quiet ssh 2>/dev/null; then
                    sudo systemctl reload ssh 2>/dev/null || true
                fi
            else
                log_warn "SSHD configuration test failed. Reverting..."
                sudo rm -f /etc/ssh/sshd_config.d/99-hardening.conf
            fi
        fi
    fi

    if [ -f "$DOTFILES_DIR/config/environment.d/10-path.conf" ]; then
        if [ -d "/etc/environment.d" ]; then
            log_info "Deploying system-wide environment.d configuration..."
            sudo ln -sf "$DOTFILES_DIR/config/environment.d/10-path.conf" /etc/environment.d/10-path.conf
            log_success "System-wide environment.d 10-path.conf configured."
        fi
    fi
}

install_fedora_packages() {
    log_info "Starting package installation for Fedora..."

    if pkg_is_installed neovim; then
        log_warn "Removing distro Neovim to prevent collisions with official release..."
        sudo dnf remove -y neovim
    fi

    log_info "Updating system package lists and upgrading packages..."
    sudo dnf update -y

    log_info "Installing development dependencies and CLI tools..."
    sudo dnf install -y make gcc ripgrep fd-find tree-sitter-cli git xclip wl-clipboard curl wget unzip zip tar rsync jq socat lsof p7zip p7zip-plugins gnupg2 mosh axel zsh openssh-clients eza bat sqlite zoxide fzf nnn clang tmux dos2unix btop alacritty fastfetch android-tools scrcpy gh

    log_info "Configuring UTF-8 locales..."
    if ! grep -q "^en_US.UTF-8 UTF-8" /etc/locale.gen 2>/dev/null; then
        if [ -f /etc/locale.gen ]; then
            echo "en_US.UTF-8 UTF-8" | sudo tee -a /etc/locale.gen
            sudo locale-gen en_US.UTF-8 2>/dev/null || true
        fi
    fi
    sudo localectl set-locale LANG=en_US.UTF-8 2>/dev/null || sudo update-locale LANG=en_US.UTF-8 2>/dev/null || true

    if [ "$FORCE" = true ] || ! command -v nvim &> /dev/null; then
        log_info "Installing official Neovim build..."
        ARCH=$(uname -m)
        case "$ARCH" in
            x86_64) NVIM_ARCH="x86_64" ;;
            aarch64|arm64) NVIM_ARCH="arm64" ;;
            *)
                log_warn "Unsupported architecture for official Neovim build: $ARCH. Falling back to dnf."
                sudo dnf install -y neovim
                NVIM_ARCH="unknown"
                ;;
        esac

        if [ "$NVIM_ARCH" != "unknown" ]; then
            TEMP_DIR=$(mktemp -d)
            (
                cd "$TEMP_DIR" || exit 1
                NVIM_TAR="nvim-linux-$NVIM_ARCH.tar.gz"
                log_info "Downloading $NVIM_TAR..."
                curl -LO "https://github.com/neovim/neovim/releases/latest/download/$NVIM_TAR"
                sudo rm -rf "/opt/nvim-linux-$NVIM_ARCH"
                sudo mkdir -p "/opt/nvim-linux-$NVIM_ARCH"
                sudo tar -C /opt -xzf "$NVIM_TAR"
                sudo chmod -R a+rX "/opt/nvim-linux-$NVIM_ARCH"
                sudo ln -sf "/opt/nvim-linux-$NVIM_ARCH/bin/nvim" /usr/local/bin/nvim
            )
            rm -rf "$TEMP_DIR"
            log_success "Neovim installation completed."
        fi
    else
        log_info "Neovim is already installed."
    fi

    if [ -f "$DOTFILES_DIR/config/docker/daemon.json" ]; then
        if command -v docker &> /dev/null || [ -d "/etc/docker" ]; then
            log_info "Configuring Docker daemon..."
            sudo mkdir -p /etc/docker
            if [ ! -f /etc/docker/daemon.json ] || [ "$FORCE" = true ]; then
                sudo cp "$DOTFILES_DIR/config/docker/daemon.json" /etc/docker/daemon.json
                log_success "Docker daemon.json configured."
            fi
        fi
    fi

    if [ -f "$DOTFILES_DIR/config/sshd/99-hardening.conf" ]; then
        if [ -d "/etc/ssh/sshd_config.d" ] || command -v sshd &> /dev/null; then
            log_info "Deploying SSHD hardening configuration..."
            sudo mkdir -p /etc/ssh/sshd_config.d
            sudo cp "$DOTFILES_DIR/config/sshd/99-hardening.conf" /etc/ssh/sshd_config.d/99-hardening.conf
            sudo chmod 644 /etc/ssh/sshd_config.d/99-hardening.conf

            if sudo sshd -t 2>/dev/null; then
                log_success "SSHD configuration validated."
                if systemctl is-active --quiet ssh 2>/dev/null; then
                    sudo systemctl reload ssh 2>/dev/null || true
                elif systemctl is-active --quiet sshd 2>/dev/null; then
                    sudo systemctl reload sshd 2>/dev/null || true
                fi
            else
                log_warn "SSHD configuration test failed. Reverting..."
                sudo rm -f /etc/ssh/sshd_config.d/99-hardening.conf
            fi
        fi
    fi

    if [ -f "$DOTFILES_DIR/config/environment.d/10-path.conf" ]; then
        if [ -d "/etc/environment.d" ]; then
            log_info "Deploying system-wide environment.d configuration..."
            sudo ln -sf "$DOTFILES_DIR/config/environment.d/10-path.conf" /etc/environment.d/10-path.conf
            log_success "System-wide environment.d 10-path.conf configured."
        fi
    fi
}

install_arch_packages() {
    log_info "Starting package installation for Arch Linux..."
    log_warn "Arch Linux package list configuration placeholder."
}

install_alpine_packages() {
    log_info "Starting package installation for Alpine..."
    log_warn "Alpine package list configuration placeholder."
}

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

# Workspaces
log_info "Configuring workspaces..."
NVIM_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"

if [ -d "$NVIM_CONFIG_DIR/.git" ]; then
    log_info "Neovim configuration exists at $NVIM_CONFIG_DIR. Pulling updates..."
    git -C "$NVIM_CONFIG_DIR" pull
else
    log_info "Cloning Neovim configuration..."
    if [ -d "$NVIM_CONFIG_DIR" ]; then
        log_warn "$NVIM_CONFIG_DIR exists but is not a git repository. Backing up..."
        rm -rf "${NVIM_CONFIG_DIR}.bak"
        mv "$NVIM_CONFIG_DIR" "${NVIM_CONFIG_DIR}.bak"
    fi
    git clone -b akrista https://github.com/akrista/nvim "$NVIM_CONFIG_DIR"
fi

if [ -d "$DOTFILES_DIR/.git" ]; then
    log_info ".akrista repository exists at $DOTFILES_DIR. Pulling updates..."
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

FIREFOX_DIR="$HOME/Projects/notakrista/.firefox"
if [ -d "$FIREFOX_DIR/.git" ]; then
    log_info ".firefox repository exists at $FIREFOX_DIR. Pulling updates..."
    git -C "$FIREFOX_DIR" pull
else
    log_info "Cloning .firefox repository..."
    if [ -d "$FIREFOX_DIR" ]; then
        log_warn "$FIREFOX_DIR exists but is not a git repository. Backing up..."
        rm -rf "${FIREFOX_DIR}.bak"
        mv "$FIREFOX_DIR" "${FIREFOX_DIR}.bak"
    fi
    mkdir -p "$(dirname "$FIREFOX_DIR")"
    git clone -b akrista https://github.com/akrista/.firefox "$FIREFOX_DIR"
fi

# Deploy the Firefox Mod Blur customization into whichever profile Firefox
# actually launches into (the profiles.ini [Install...] Default= entry),
# not a hardcoded profile hash.
FF_PROFILES_INI="$HOME/.mozilla/firefox/profiles.ini"
if [ -d "$FIREFOX_DIR" ] && [ -f "$FF_PROFILES_INI" ]; then
    FF_INSTALL_REL=$(awk -F= '/^\[Install/{flag=1; next} /^\[/{flag=0} flag && /^Default=/{print $2; exit}' "$FF_PROFILES_INI")
    if [ -n "$FF_INSTALL_REL" ]; then
        FF_PROFILE_DIR="$HOME/.mozilla/firefox/$FF_INSTALL_REL"
        mkdir -p "$FF_PROFILE_DIR/chrome"
        link_file "$FIREFOX_DIR/user.js" "$FF_PROFILE_DIR/user.js" "Firefox user.js"
        for item in "$FIREFOX_DIR"/*; do
            base="$(basename "$item")"
            case "$base" in
                "EXTRA MODS"|README.md|user.js) continue ;;
            esac
            link_file "$item" "$FF_PROFILE_DIR/chrome/$base" "Firefox chrome/$base"
        done
    else
        log_warn "Could not determine the active Firefox profile from $FF_PROFILES_INI. Skipping Firefox customization."
    fi
else
    log_warn "No Firefox profile found. Skipping Firefox customization."
fi

# Environment-specific configuration
if [ "$OS" = "Termux" ]; then
    log_info "Configuring Termux..."
    mkdir -p "$HOME/.termux"
    link_file "$DOTFILES_DIR/config/termux/termux.properties" "$HOME/.termux/termux.properties" "termux.properties"

    if [ ! -f "$HOME/.termux/font.ttf" ]; then
        log_info "Downloading MesloLGS NF Regular font..."
        curl -fsSL -o "$HOME/.termux/font.ttf" "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf"
    else
        log_success "MesloLGS NF Regular font is already installed."
    fi

    log_info "Reloading Termux settings..."
    termux-reload-settings
elif [ "$IS_PROOT_DISTRO" = true ]; then
    echo ""
    echo -e "${YELLOW}PROOT-DISTRO DETECTED${NC}"
    echo "To configure fonts and terminal settings in Termux, run the installer outside the container:"
    echo "curl -fsSL https://github.com/akrista/.akrista/raw/master/install.ps1 | bash"
    echo ""
else
    MESLO_FONT_DIR="$HOME/.local/share/fonts/MesloLGS NF"
    if [ ! -f "$MESLO_FONT_DIR/MesloLGS NF Regular.ttf" ]; then
        log_info "Downloading MesloLGS NF fonts..."
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

if [ "$OS" != "Termux" ]; then
    log_info "Setting up runtime engines..."

    # Bun
    if command -v bun &> /dev/null; then
        log_info "Checking for Bun updates..."
        bun upgrade
    elif [ -d "$HOME/.bun" ]; then
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

    # fnm
    if ! command -v fnm &> /dev/null && [ ! -d "$HOME/.local/share/fnm" ]; then
        log_info "Installing fnm..."
        curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell
    else
        log_success "fnm is already installed."
    fi
    export PATH="$HOME/.local/share/fnm:$PATH"
    if command -v fnm &> /dev/null; then
        eval "$(fnm env)"
        log_info "Configuring Node.js LTS via fnm..."
        fnm install --lts
        fnm default lts-latest
    fi

    # uv
    if ! command -v uv &> /dev/null && [ ! -f "$HOME/.local/bin/uv" ]; then
        log_info "Installing uv..."
        curl -fsSL https://astral.sh/uv/install.sh | sh
    elif command -v uv &> /dev/null; then
        log_info "Checking for uv updates..."
        uv self update 2>/dev/null || true
    fi

    # mise
    if ! command -v mise &> /dev/null && [ ! -f "$HOME/.local/bin/mise" ]; then
        log_info "Installing mise..."
        curl -fsSL https://mise.run | sh
    elif command -v mise &> /dev/null || [ -x "$HOME/.local/bin/mise" ]; then
        log_info "Checking for mise updates..."
        MISE_BIN="$(command -v mise 2>/dev/null || echo "$HOME/.local/bin/mise")"
        "$MISE_BIN" self-update -y 2>/dev/null || true
    fi

    # GitHub Copilot CLI
    if command -v copilot &> /dev/null; then
        log_success "GitHub Copilot CLI is already installed."
    else
        log_info "Installing GitHub Copilot CLI..."
        curl -fsSL https://gh.io/copilot-install | bash
    fi

    if command -v copilot &> /dev/null; then
        mkdir -p "$HOME/.zsh/completions" "$HOME/.local/share/bash-completion/completions"
        copilot completion zsh > "$HOME/.zsh/completions/_copilot"
        copilot completion bash > "$HOME/.local/share/bash-completion/completions/copilot"
    fi

    # Tmux Pack (tpack / lightweight TPM)
    if [ -d "$HOME/.tmux/plugins/tpm" ]; then
        log_info "Updating tpack (TPM compatible)..."
        git -C "$HOME/.tmux/plugins/tpm" pull -q
    else
        log_info "Installing tpack (TPM compatible)..."
        git clone -q https://github.com/tmuxpack/tpack "$HOME/.tmux/plugins/tpm"
    fi

    # Refresh the compiled tpack binary as well as the checkout. The binary is
    # released separately, so git pull alone can leave an older self-updater.
    if [ -f "$HOME/.tmux/plugins/tpm/lib/download_binary.sh" ]; then
        source "$HOME/.tmux/plugins/tpm/lib/download_binary.sh"
        _download_tpack "$HOME/.tmux/plugins/tpm" \
            || log_warn "Could not download the latest tpack binary."
    fi

    # Rust
    if command -v rustup &> /dev/null; then
        log_info "Checking for Rust updates..."
        rustup update
    else
        log_info "Installing Rustup..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    fi

    # Cargo binaries
    if [ "$OS" = "Debian/Ubuntu" ] || [ "$OS" = "Fedora" ]; then
        if [ -f "$HOME/.cargo/env" ]; then
            . "$HOME/.cargo/env"
        fi

        if ! command -v gitui &> /dev/null; then
            log_info "Installing gitui..."
            cargo install gitui --locked
            log_success "gitui installed."
        else
            log_success "gitui is already installed."
        fi

        if ! command -v oxker &> /dev/null; then
            log_info "Installing oxker..."
            cargo install oxker --locked
            log_success "oxker installed."
        else
            log_success "oxker is already installed."
        fi

        if ! command -v eza &> /dev/null; then
            log_info "Installing eza via Cargo..."
            cargo install eza --locked
            log_success "eza installed."
        else
            log_success "eza is already installed."
        fi

        if ! command -v systemctl-tui &> /dev/null; then
            log_info "Installing systemctl-tui..."
            cargo install systemctl-tui --locked
            log_success "systemctl-tui installed."
        else
            log_success "systemctl-tui is already installed."
        fi

        if ! command -v tree-sitter &> /dev/null; then
            if command -v bun &> /dev/null; then
                log_info "Installing tree-sitter-cli via Bun..."
                bun add -g tree-sitter-cli
            fi
        fi
    fi

    # Homebrew
    if ! command -v brew &> /dev/null && [ ! -d "/home/linuxbrew/.linuxbrew" ]; then
        log_info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        log_success "Homebrew is already installed."
    fi
fi

# Shell configuration and plugins
log_info "Bootstrapping Oh My Zsh and plugins..."

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
    rm -rf "$HOME/.zcompdump"* "$DOTFILES_DIR/config/zsh/.zcompdump"* 2>/dev/null || true
else
    log_info "Installing zsh-completions..."
    git clone -q https://github.com/zsh-users/zsh-completions.git "$HOME/.zsh/zsh-completions"
    rm -rf "$HOME/.zcompdump"* "$DOTFILES_DIR/config/zsh/.zcompdump"* 2>/dev/null || true
fi

# Secure zsh completion directories against compaudit warnings
chmod -R go-w "$HOME/.zsh" 2>/dev/null || true
if [ -d "$HOME/.local/share/zsh" ]; then
    chmod -R go-w "$HOME/.local/share/zsh" 2>/dev/null || true
fi

# Oh My Posh
if command -v oh-my-posh &> /dev/null; then
    log_info "Checking for Oh My Posh updates..."
    oh-my-posh upgrade 2>/dev/null || log_warn "Oh My Posh upgrade check failed."
else
    log_info "Installing Oh My Posh..."
    curl -s https://ohmyposh.dev/install.sh | bash -s
fi

# CLI agents and global packages
log_info "Configuring CLI agents..."

supports_agy=false
if [ "$OS" != "Termux" ] && [ "$(uname -m)" = "x86_64" ] && grep -q -E "avx|avx2" /proc/cpuinfo 2>/dev/null; then
    supports_agy=true
fi

if [ "$supports_agy" = true ]; then
    if [ ! -f "$HOME/.local/bin/agy" ]; then
        log_info "Installing Antigravity CLI (agy)..."
        curl -fsSL https://antigravity.google/cli/install.sh | bash
        log_success "Antigravity CLI installed."
    else
        log_info "Antigravity CLI (agy) is already installed."
    fi
fi

if [ "$OS" != "Termux" ]; then
    if command -v claude &> /dev/null; then
        log_info "Claude Code is already installed."
    else
        log_info "Installing Claude Code..."
        curl -fsSL https://claude.ai/install.sh | bash
        log_success "Claude Code installed."
    fi
fi

if [ "$OS" != "Termux" ]; then
    if [ ! -f "$HOME/.opencode/bin/opencode" ]; then
        log_info "Installing OpenCode..."
        curl -fsSL https://opencode.ai/install | bash
        log_success "OpenCode installed."
    else
        log_info "OpenCode is already installed."
    fi
fi

if command -v bun &> /dev/null; then
    if ! command -v pi &> /dev/null; then
        log_info "Installing Pi coding agent via Bun..."
        bun add -g @earendil-works/pi-coding-agent
        log_success "Pi coding agent installed."
    else
        log_info "Updating Pi coding agent via Bun..."
        bun update -g @earendil-works/pi-coding-agent
        log_success "Pi coding agent updated."
    fi
elif command -v npm &> /dev/null; then
    if ! command -v pi &> /dev/null; then
        log_info "Installing Pi coding agent via npm..."
        npm i -g --ignore-scripts @earendil-works/pi-coding-agent
        log_success "Pi coding agent installed."
    else
        log_info "Updating Pi coding agent via npm..."
        npm update -g @earendil-works/pi-coding-agent
        log_success "Pi coding agent updated."
    fi
else
    log_warn "Neither bun nor npm found. Skipping global packages."
fi

if [ "$OS" != "Termux" ]; then
    GROK_BIN=""
    if command -v grok &> /dev/null; then
        GROK_BIN="$(command -v grok)"
    elif [ -x "$HOME/.grok/bin/grok" ]; then
        GROK_BIN="$HOME/.grok/bin/grok"
    elif [ -x "$HOME/.local/bin/grok" ]; then
        GROK_BIN="$HOME/.local/bin/grok"
    fi

    if [ -n "$GROK_BIN" ]; then
        log_info "Grok is already installed."
        "$GROK_BIN" update 2>/dev/null || true
    else
        log_info "Installing Grok..."
        curl -fsSL https://x.ai/cli/install.sh | bash
        log_success "Grok installed."
    fi

    if [ -f "$HOME/.cargo/env" ]; then
        . "$HOME/.cargo/env"
    fi

    if [ "$FORCE" = true ] || ! command -v maga &> /dev/null; then
        if command -v cargo &> /dev/null; then
            log_info "Installing maga..."
            cargo install --git https://github.com/akrista/maga --locked
            log_success "maga installed."
        else
            log_warn "cargo not found. Skipping maga installation."
        fi
    else
        log_success "maga is already installed."
    fi
fi

# Post-installation package cleanup
if [ "$PACKAGER" = "pkg" ]; then
    log_info "Cleaning up Termux packages..."
    pkg autoclean -y
    pkg clean
elif [ "$PACKAGER" = "apt" ]; then
    log_info "Cleaning up Debian/Ubuntu packages..."
    sudo apt-get autoremove -y
    sudo apt-get autoclean -y
    sudo apt-get clean
elif [ "$PACKAGER" = "dnf" ]; then
    log_info "Cleaning up Fedora packages..."
    sudo dnf autoremove -y
    sudo dnf clean all
fi

# Symlink dotfiles
log_info "Symlinking configuration files..."
link_file "$DOTFILES_DIR/config/zsh/.zshrc" "$HOME/.zshrc" ".zshrc"
link_file "$DOTFILES_DIR/config/bash/.bashrc" "$HOME/.bashrc" ".bashrc"
link_file "$DOTFILES_DIR/config/git/.gitconfig" "$HOME/.gitconfig" ".gitconfig"
link_file "$DOTFILES_DIR/config/sqlite/.sqliterc" "$HOME/.sqliterc" ".sqliterc"
link_file "$DOTFILES_DIR/config/tmux/.tmux.conf" "$HOME/.tmux.conf" ".tmux.conf"

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
        rm -f "$OXKER_CONFIG_FILE"
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

CONTAINERS_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/containers"
mkdir -p "$CONTAINERS_CONFIG_DIR"
link_file "$DOTFILES_DIR/config/containers/containers.conf" "$CONTAINERS_CONFIG_DIR/containers.conf" "containers.conf"

ALACRITTY_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/alacritty"
mkdir -p "$ALACRITTY_CONFIG_DIR"
link_file "$DOTFILES_DIR/config/alacritty/alacritty.toml" "$ALACRITTY_CONFIG_DIR/alacritty.toml" "alacritty.toml"

ZELLIJ_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/zellij"
mkdir -p "$ZELLIJ_CONFIG_DIR"
link_file "$DOTFILES_DIR/config/zellij/config.kdl" "$ZELLIJ_CONFIG_DIR/config.kdl" "zellij config.kdl"

MISE_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/mise"
mkdir -p "$MISE_CONFIG_DIR"
link_file "$DOTFILES_DIR/config/mise/config.toml" "$MISE_CONFIG_DIR/config.toml" "mise config.toml"

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
link_file "$DOTFILES_DIR/config/zed/keymap.json" "$ZED_CONFIG_DIR/keymap.json" "zed keymap.json"

ENVIRONMENT_D_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/environment.d"
mkdir -p "$ENVIRONMENT_D_CONFIG_DIR"
link_file "$DOTFILES_DIR/config/environment.d/10-path.conf" "$ENVIRONMENT_D_CONFIG_DIR/10-path.conf" "environment.d 10-path.conf"

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

MAGA_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/maga"
mkdir -p "$MAGA_CONFIG_DIR"
link_file "$DOTFILES_DIR/slop/maga/config.toml" "$MAGA_CONFIG_DIR/config.toml" "maga config.toml"

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
link_file "$DOTFILES_DIR/slop/opencode/tui.json" "$OPENCODE_CONFIG_DIR/tui.json" "opencode tui.json"
link_file "$DOTFILES_DIR/slop/opencode/themes" "$OPENCODE_CONFIG_DIR/themes" "opencode themes"

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

AGY_HOOKS_LOCAL="$DOTFILES_DIR/slop/agy/hooks.json"
if [ ! -f "$AGY_HOOKS_LOCAL" ]; then
    log_info "Initializing slop/agy/hooks.json from template..."
    if [ -f "$DOTFILES_DIR/slop/agy/hooks.json.example" ]; then
        cp "$DOTFILES_DIR/slop/agy/hooks.json.example" "$AGY_HOOKS_LOCAL"
        chmod 600 "$AGY_HOOKS_LOCAL"
    fi
fi
link_file "$AGY_HOOKS_LOCAL" "$GEMINI_CONFIG_DIR/hooks.json" "antigravity hooks.json"
mkdir -p "$HOME/.gemini/antigravity-cli"
link_file "$AGY_HOOKS_LOCAL" "$HOME/.gemini/antigravity-cli/hooks.json" "antigravity-cli hooks.json"
link_file "$AGY_CONFIG_LOCAL" "$HOME/.gemini/antigravity-cli/config.json" "antigravity-cli config.json"

link_file "$DOTFILES_DIR/slop/skills-lock.json" "$HOME/skills-lock.json" "skills-lock.json"

if [ -f "$DOTFILES_DIR/slop/skills-lock.json" ] && command -v bunx &> /dev/null; then
    log_info "Synchronizing Agent Skills via bunx skills..."
    (cd "$HOME" && bunx -y skills experimental_install 2>/dev/null || true)
fi

# Expose shared ~/.agents/skills copies to Antigravity and Gemini CLI.
GEMINI_SKILLS_DIR="$GEMINI_CONFIG_DIR/skills"
mkdir -p "$GEMINI_SKILLS_DIR"
if [ -d "$HOME/.agents/skills" ]; then
    for skill_path in "$HOME/.agents/skills"/*; do
        [ -d "$skill_path" ] || continue
        skill_name="$(basename "$skill_path")"
        link_file "$skill_path" "$GEMINI_SKILLS_DIR/$skill_name" "Antigravity $skill_name skill"
    done
fi
mkdir -p "$HOME/.gemini"
link_file "$GEMINI_SKILLS_DIR" "$HOME/.gemini/skills" "Gemini CLI skills directory"

GUIDELINES_FILE="$DOTFILES_DIR/slop/guidelines/AGENTS.md"
if [ -f "$GUIDELINES_FILE" ]; then
    link_file "$GUIDELINES_FILE" "$HOME/.claude/CLAUDE.md" "Claude Code global CLAUDE.md"
    mkdir -p "$HOME/.copilot"
    link_file "$GUIDELINES_FILE" "$HOME/.copilot/copilot-instructions.md" "GitHub Copilot global instructions"
    link_file "$GUIDELINES_FILE" "$HOME/.copilot/AGENTS.md" "GitHub Copilot CLI global AGENTS.md"
    mkdir -p "$HOME/.config/opencode"
    link_file "$GUIDELINES_FILE" "$HOME/.config/opencode/AGENTS.md" "OpenCode global AGENTS.md"
    mkdir -p "$HOME/.gemini" "$HOME/.pi/agent" "$HOME/.grok"
    link_file "$GUIDELINES_FILE" "$HOME/.gemini/GEMINI.md" "Antigravity (agy) global GEMINI.md"
    link_file "$GUIDELINES_FILE" "$HOME/.gemini/AGENTS.md" "Antigravity (agy) global AGENTS.md (cross-tool)"
    link_file "$GUIDELINES_FILE" "$HOME/.pi/agent/AGENTS.md" "Pi global AGENTS.md"
    link_file "$GUIDELINES_FILE" "$HOME/.grok/AGENTS.md" "Grok CLI global AGENTS.md"
fi

mkdir -p "$HOME/.local/bin"
if command -v batcat &> /dev/null && [ ! -e "$HOME/.local/bin/bat" ]; then
    ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
fi
if command -v fdfind &> /dev/null && [ ! -e "$HOME/.local/bin/fd" ]; then
    ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
fi

if command -v tmux &> /dev/null && [ -d "$HOME/.tmux/plugins/tpm" ]; then
    log_info "Installing/updating tmux plugins..."
    export TMUX_PLUGIN_MANAGER_PATH="$HOME/.tmux/plugins"
    "$HOME/.tmux/plugins/tpm/bin/install_plugins" || log_warn "Could not install tmux plugins automatically."

    log_info "Fixing line endings in tmux plugins (CRLF to LF)..."
    find "$HOME/.tmux/plugins" -type f \( -name "*.tmux" -o -name "*.sh" \) -exec dos2unix {} +
fi

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
    log_info "Populating ~/.ssh/config..."
    cat << 'EOF' > "$SSH_CONFIG_FILE"
Include ~/.ssh/config.local
Include ~/.akrista/config/ssh/config
EOF
    chmod 600 "$SSH_CONFIG_FILE"
    log_success "~/.ssh/config configured."
fi

echo ""
echo -e "${GREEN}Installation completed.${NC}"
echo "Reload your shell or restart your terminal to apply changes."
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

# PowerShell installer for Windows

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

Write-LogInfo "Initializing Windows setup..."

$Force = $args -contains "--force" -or $args -contains "-f"

if ($Force) {
    Write-LogInfo "Force flag enabled."
}

# Windows symlink helper with Junction/Copy fallback
function Link-File {
    param (
        [string]$SourcePath,
        [string]$TargetPath,
        [string]$Name
    )
    if (Test-Path -LiteralPath $SourcePath -Force) {
        $sourceItem = Get-Item -LiteralPath $SourcePath -Force
        $sourceFull = $sourceItem.FullName.TrimEnd('\')
        $isDir = $sourceItem.PSIsContainer
        $alreadyLinked = $false

        $parentDir = Split-Path -Path $TargetPath -Parent
        if ($parentDir -and -not (Test-Path -LiteralPath $parentDir -Force)) {
            New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
        }

        if (Test-Path -LiteralPath $TargetPath -Force) {
            $item = Get-Item -LiteralPath $TargetPath -Force
            if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
                $targets = @($item.Target) | Where-Object { $_ } | ForEach-Object {
                    try {
                        [System.IO.Path]::GetFullPath($_).TrimEnd('\')
                    } catch {
                        $_.TrimEnd('\')
                    }
                }
                if ($targets -contains $sourceFull -or $item.Target -contains $SourcePath) {
                    Write-LogSuccess "$Name is already linked to the repository version."
                    $alreadyLinked = $true
                }
            }

            if (-not $alreadyLinked) {
                Write-LogInfo "Backing up existing $TargetPath to $TargetPath.bak..."
                if (Test-Path -LiteralPath "$TargetPath.bak" -Force) {
                    Remove-Item -LiteralPath "$TargetPath.bak" -Recurse -Force
                }
                Move-Item -LiteralPath $TargetPath -Destination "$TargetPath.bak" -Force
            }
        }

        if (-not $alreadyLinked) {
            Write-LogInfo "Creating symlink for $Name..."
            try {
                New-Item -ItemType SymbolicLink -Path $TargetPath -Value $sourceItem.FullName -ErrorAction Stop | Out-Null
                Write-LogSuccess "Linked $Name"
            } catch {
                if ($isDir) {
                    try {
                        New-Item -ItemType Junction -Path $TargetPath -Value $sourceItem.FullName -ErrorAction Stop | Out-Null
                        Write-LogSuccess "Linked $Name (junction)"
                        return
                    } catch {}
                }
                Write-LogWarning "Failed to create symlink for $Name. Copying instead..."
                Copy-Item -LiteralPath $sourceItem.FullName -Destination $TargetPath -Force -Recurse
            }
        }
    }
}

function Initialize-RepoConfig {
    param (
        [string]$RepoLocalPath,
        [string]$ExamplePath,
        [string]$LiveTargetPath,
        [string]$Label,
        [switch]$AllowEmptyFallback
    )
    if (Test-Path -LiteralPath $RepoLocalPath -Force) {
        return
    }
    $repoParent = Split-Path -Path $RepoLocalPath -Parent
    if ($repoParent -and -not (Test-Path -LiteralPath $repoParent -Force)) {
        New-Item -ItemType Directory -Path $repoParent -Force | Out-Null
    }
    if ($LiveTargetPath -and (Test-Path -LiteralPath $LiveTargetPath -Force)) {
        $liveItem = Get-Item -LiteralPath $LiveTargetPath -Force
        if (-not ($liveItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint)) {
            Write-LogInfo "Seeding $Label from existing $LiveTargetPath..."
            Copy-Item -LiteralPath $LiveTargetPath -Destination $RepoLocalPath -Force
            return
        }
    }
    if ($ExamplePath -and (Test-Path -LiteralPath $ExamplePath -Force)) {
        Write-LogInfo "Initializing $Label from template..."
        Copy-Item -LiteralPath $ExamplePath -Destination $RepoLocalPath -Force
    } elseif ($AllowEmptyFallback) {
        Write-LogInfo "Initializing empty $Label..."
        New-Item -ItemType File -Path $RepoLocalPath -Force | Out-Null
    }
}

# Repositories
$nvimConfigPath = Join-Path $env:LOCALAPPDATA "nvim"
if (-not (Test-Path $nvimConfigPath)) {
    Write-LogInfo "Cloning Neovim configuration..."
    git clone -b akrista https://github.com/akrista/nvim $nvimConfigPath
} else {
    Write-LogInfo "Neovim configuration exists at $nvimConfigPath. Pulling updates..."
    git -C $nvimConfigPath pull
}

$dotfilesPath = Join-Path $HOME ".akrista"
if (-not (Test-Path $dotfilesPath)) {
    Write-LogInfo "Cloning .akrista repository..."
    git clone https://github.com/akrista/.akrista $dotfilesPath
} else {
    Write-LogInfo ".akrista repository exists at $dotfilesPath. Pulling updates..."
    git -C $dotfilesPath pull
}

if (Test-Path $dotfilesPath) {
    $checkFile = Join-Path $dotfilesPath ".last_update_check"
    New-Item -ItemType File -Path $checkFile -Force | Out-Null
}

$firefoxDir = Join-Path $HOME "Projects\notakrista\.firefox"
if (-not (Test-Path $firefoxDir)) {
    Write-LogInfo "Cloning .firefox repository..."
    New-Item -ItemType Directory -Path (Split-Path $firefoxDir -Parent) -Force | Out-Null
    git clone -b akrista https://github.com/akrista/.firefox $firefoxDir
} else {
    Write-LogInfo ".firefox repository exists at $firefoxDir. Pulling updates..."
    git -C $firefoxDir pull
}

# Deploy the Firefox Mod Blur customization into whichever profile Firefox
# actually launches into (the profiles.ini [Install...] Default= entry),
# not a hardcoded profile hash.
$ffProfilesIni = Join-Path $env:APPDATA "Mozilla\Firefox\profiles.ini"
if ((Test-Path $firefoxDir) -and (Test-Path $ffProfilesIni)) {
    $ffInstallRel = $null
    $inInstallSection = $false
    foreach ($line in Get-Content $ffProfilesIni) {
        if ($line -match '^\[Install') { $inInstallSection = $true; continue }
        if ($line -match '^\[') { $inInstallSection = $false; continue }
        if ($inInstallSection -and $line -match '^Default=(.*)$') {
            $ffInstallRel = $Matches[1]
            break
        }
    }
    if ($ffInstallRel) {
        $ffProfileDir = Join-Path (Split-Path $ffProfilesIni -Parent) $ffInstallRel
        $ffChromeDir = Join-Path $ffProfileDir "chrome"
        New-Item -ItemType Directory -Path $ffChromeDir -Force | Out-Null
        Link-File -SourcePath (Join-Path $firefoxDir "user.js") -TargetPath (Join-Path $ffProfileDir "user.js") -Name "Firefox user.js"
        Get-ChildItem -Path $firefoxDir | Where-Object {
            $_.Name -notin @("EXTRA MODS", "README.md", "user.js", ".git")
        } | ForEach-Object {
            Link-File -SourcePath $_.FullName -TargetPath (Join-Path $ffChromeDir $_.Name) -Name "Firefox chrome/$($_.Name)"
        }
    } else {
        Write-LogWarning "Could not determine the active Firefox profile from $ffProfilesIni. Skipping Firefox customization."
    }
} else {
    Write-LogWarning "No Firefox profile found. Skipping Firefox customization."
}

# PowerShell profile setup (pwsh-pf)
Write-LogInfo "Running pwsh-pf setup..."
Invoke-Expression "& { $(Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/akrista/pwsh-pf/master/setup.ps1') } @args"

# Configuration dotfiles
Write-LogInfo "Linking configuration files..."
Link-File -SourcePath (Join-Path $dotfilesPath "config/git/.gitconfig") -TargetPath (Join-Path $HOME ".gitconfig") -Name ".gitconfig"
Link-File -SourcePath (Join-Path $dotfilesPath "config/sqlite/.sqliterc") -TargetPath (Join-Path $HOME ".sqliterc") -Name ".sqliterc"

$alacrittyDir = Join-Path $env:APPDATA "alacritty"
New-Item -ItemType Directory -Path $alacrittyDir -Force | Out-Null
Link-File -SourcePath (Join-Path $dotfilesPath "config/alacritty/alacritty.windows.toml") -TargetPath (Join-Path $alacrittyDir "alacritty.toml") -Name "alacritty.toml"

$zellijDir = Join-Path $HOME ".config\zellij"
New-Item -ItemType Directory -Path $zellijDir -Force | Out-Null
Link-File -SourcePath (Join-Path $dotfilesPath "config/zellij/config.kdl") -TargetPath (Join-Path $zellijDir "config.kdl") -Name "zellij config.kdl"

$zedDir = Join-Path $env:APPDATA "Zed"
New-Item -ItemType Directory -Path $zedDir -Force | Out-Null
$zedRepoLocal = Join-Path $dotfilesPath "config/zed/settings.json"
$zedTarget = Join-Path $zedDir "settings.json"
Initialize-RepoConfig `
    -RepoLocalPath $zedRepoLocal `
    -ExamplePath (Join-Path $dotfilesPath "config/zed/settings.json.example") `
    -LiveTargetPath $zedTarget `
    -Label "config/zed/settings.json"
Link-File -SourcePath $zedRepoLocal -TargetPath $zedTarget -Name "zed settings.json"
Link-File -SourcePath (Join-Path $dotfilesPath "config/zed/keymap.json") -TargetPath (Join-Path $zedDir "keymap.json") -Name "zed keymap.json"

$claudeDir = Join-Path $HOME ".claude"
New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null
$claudeRepoLocal = Join-Path $dotfilesPath "slop/claude/settings.json"
$claudeSettingsTarget = Join-Path $claudeDir "settings.json"
Initialize-RepoConfig `
    -RepoLocalPath $claudeRepoLocal `
    -ExamplePath (Join-Path $dotfilesPath "slop/claude/settings.json.example") `
    -LiveTargetPath $claudeSettingsTarget `
    -Label "slop/claude/settings.json"
Link-File -SourcePath $claudeRepoLocal -TargetPath $claudeSettingsTarget -Name "claude settings.json"

$magaDir = Join-Path $HOME ".config\maga"
New-Item -ItemType Directory -Path $magaDir -Force | Out-Null
Link-File -SourcePath (Join-Path $dotfilesPath "slop/maga/config.toml") -TargetPath (Join-Path $magaDir "config.toml") -Name "maga config.toml"

$opencodeDir = Join-Path $HOME ".config\opencode"
New-Item -ItemType Directory -Path $opencodeDir -Force | Out-Null
$opencodeRepoLocal = Join-Path $dotfilesPath "slop/opencode/opencode.json"
$opencodeTarget = Join-Path $opencodeDir "opencode.json"
Initialize-RepoConfig `
    -RepoLocalPath $opencodeRepoLocal `
    -ExamplePath (Join-Path $dotfilesPath "slop/opencode/opencode.json.example") `
    -LiveTargetPath $opencodeTarget `
    -Label "slop/opencode/opencode.json"
Link-File -SourcePath $opencodeRepoLocal -TargetPath $opencodeTarget -Name "opencode.json"
Link-File -SourcePath $opencodeRepoLocal -TargetPath (Join-Path $opencodeDir "config.json") -Name "opencode config.json"
Link-File -SourcePath (Join-Path $dotfilesPath "slop/opencode/tui.json") -TargetPath (Join-Path $opencodeDir "tui.json") -Name "opencode tui.json"
Link-File -SourcePath (Join-Path $dotfilesPath "slop/opencode/themes") -TargetPath (Join-Path $opencodeDir "themes") -Name "opencode themes"

$opencodeDesktopDir = Join-Path $env:APPDATA "ai.opencode.desktop"
New-Item -ItemType Directory -Path $opencodeDesktopDir -Force | Out-Null
$opencodeDatLocal = Join-Path $dotfilesPath "slop/opencode/opencode.global.dat"
$opencodeDatTarget = Join-Path $opencodeDesktopDir "opencode.global.dat"
Initialize-RepoConfig `
    -RepoLocalPath $opencodeDatLocal `
    -ExamplePath (Join-Path $dotfilesPath "slop/opencode/opencode.global.dat.example") `
    -LiveTargetPath $opencodeDatTarget `
    -Label "slop/opencode/opencode.global.dat" `
    -AllowEmptyFallback
Link-File -SourcePath $opencodeDatLocal -TargetPath $opencodeDatTarget -Name "opencode desktop global.dat"

$geminiConfigDir = Join-Path $HOME ".gemini\config"
New-Item -ItemType Directory -Path $geminiConfigDir -Force | Out-Null

$agyConfigLocal = Join-Path $dotfilesPath "slop/agy/config.json"
$agyConfigTarget = Join-Path $geminiConfigDir "config.json"
Initialize-RepoConfig `
    -RepoLocalPath $agyConfigLocal `
    -ExamplePath (Join-Path $dotfilesPath "slop/agy/config.json.example") `
    -LiveTargetPath $agyConfigTarget `
    -Label "slop/agy/config.json"
Link-File -SourcePath $agyConfigLocal -TargetPath $agyConfigTarget -Name "antigravity config.json"

$agyHooksLocal = Join-Path $dotfilesPath "slop/agy/hooks.json"
$agyHooksTarget = Join-Path $geminiConfigDir "hooks.json"
Initialize-RepoConfig `
    -RepoLocalPath $agyHooksLocal `
    -ExamplePath (Join-Path $dotfilesPath "slop/agy/hooks.json.example") `
    -LiveTargetPath $agyHooksTarget `
    -Label "slop/agy/hooks.json"
Link-File -SourcePath $agyHooksLocal -TargetPath $agyHooksTarget -Name "antigravity hooks.json"
$agyCliDir = Join-Path $HOME ".gemini\antigravity-cli"
New-Item -ItemType Directory -Path $agyCliDir -Force | Out-Null
Link-File -SourcePath $agyHooksLocal -TargetPath (Join-Path $agyCliDir "hooks.json") -Name "antigravity-cli hooks.json"
Link-File -SourcePath $agyConfigLocal -TargetPath (Join-Path $agyCliDir "config.json") -Name "antigravity-cli config.json"

$skillsLockLocal = Join-Path $dotfilesPath "slop/skills-lock.json"
Link-File -SourcePath $skillsLockLocal -TargetPath (Join-Path $HOME "skills-lock.json") -Name "skills-lock.json"

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

# Expose shared ~/.agents/skills copies to Antigravity and Gemini CLI.
$geminiSkillsDir = Join-Path $geminiConfigDir "skills"
New-Item -ItemType Directory -Path $geminiSkillsDir -Force | Out-Null
$agentsSkillsDir = Join-Path $HOME ".agents\skills"
if (Test-Path $agentsSkillsDir) {
    Get-ChildItem -Path $agentsSkillsDir -Directory | ForEach-Object {
        $skillName = $_.Name
        Link-File -SourcePath $_.FullName `
            -TargetPath (Join-Path $geminiSkillsDir $skillName) `
            -Name "Antigravity $skillName skill"
    }
}
$geminiDir = Join-Path $HOME ".gemini"
New-Item -ItemType Directory -Path $geminiDir -Force | Out-Null
Link-File -SourcePath $geminiSkillsDir `
    -TargetPath (Join-Path $geminiDir "skills") `
    -Name "Gemini CLI skills directory"

$guidelinesFile = Join-Path $dotfilesPath "slop/guidelines/AGENTS.md"
if (Test-Path $guidelinesFile) {
    Link-File -SourcePath $guidelinesFile -TargetPath (Join-Path $HOME ".claude\CLAUDE.md") -Name "Claude Code global CLAUDE.md"
    $copilotDir = Join-Path $HOME ".copilot"
    New-Item -ItemType Directory -Path $copilotDir -Force | Out-Null
    Link-File -SourcePath $guidelinesFile -TargetPath (Join-Path $copilotDir "copilot-instructions.md") -Name "GitHub Copilot global instructions"
    Link-File -SourcePath $guidelinesFile -TargetPath (Join-Path $copilotDir "AGENTS.md") -Name "GitHub Copilot CLI global AGENTS.md"
    $opencodeGlobalDir = Join-Path $HOME ".config\opencode"
    New-Item -ItemType Directory -Path $opencodeGlobalDir -Force | Out-Null
    Link-File -SourcePath $guidelinesFile -TargetPath (Join-Path $opencodeGlobalDir "AGENTS.md") -Name "OpenCode global AGENTS.md"
    $geminiDir = Join-Path $HOME ".gemini"
    $piAgentDir = Join-Path $HOME ".pi\agent"
    $grokDir = Join-Path $HOME ".grok"
    New-Item -ItemType Directory -Path $geminiDir -Force | Out-Null
    New-Item -ItemType Directory -Path $piAgentDir -Force | Out-Null
    New-Item -ItemType Directory -Path $grokDir -Force | Out-Null
    Link-File -SourcePath $guidelinesFile -TargetPath (Join-Path $geminiDir "GEMINI.md") -Name "Antigravity (agy) global GEMINI.md"
    Link-File -SourcePath $guidelinesFile -TargetPath (Join-Path $geminiDir "AGENTS.md") -Name "Antigravity (agy) global AGENTS.md (cross-tool)"
    Link-File -SourcePath $guidelinesFile -TargetPath (Join-Path $piAgentDir "AGENTS.md") -Name "Pi global AGENTS.md"
    Link-File -SourcePath $guidelinesFile -TargetPath (Join-Path $grokDir "AGENTS.md") -Name "Grok CLI global AGENTS.md"
}

$gitRepoLocal = Join-Path $dotfilesPath "config/git/.gitconfig.local"
$gitTarget = Join-Path $HOME ".gitconfig.local"
Initialize-RepoConfig `
    -RepoLocalPath $gitRepoLocal `
    -ExamplePath (Join-Path $dotfilesPath "config/git/.gitconfig.local.example") `
    -LiveTargetPath $gitTarget `
    -Label "config/git/.gitconfig.local" `
    -AllowEmptyFallback
Link-File -SourcePath $gitRepoLocal -TargetPath $gitTarget -Name ".gitconfig.local"

$envRepoLocal = Join-Path $dotfilesPath "config/env/.env.local"
$envTarget = Join-Path $HOME ".env.local"
Initialize-RepoConfig `
    -RepoLocalPath $envRepoLocal `
    -ExamplePath (Join-Path $dotfilesPath "config/env/.env.local.example") `
    -LiveTargetPath $envTarget `
    -Label "config/env/.env.local" `
    -AllowEmptyFallback
Link-File -SourcePath $envRepoLocal -TargetPath $envTarget -Name ".env.local"

$sshDir = Join-Path $HOME ".ssh"
if (-not (Test-Path $sshDir)) {
    New-Item -ItemType Directory -Path $sshDir -Force | Out-Null
}

$sshRepoLocal = Join-Path $dotfilesPath "config/ssh/config.local"
$sshLocalTarget = Join-Path $sshDir "config.local"
Initialize-RepoConfig `
    -RepoLocalPath $sshRepoLocal `
    -ExamplePath (Join-Path $dotfilesPath "config/ssh/config.local.example") `
    -LiveTargetPath $sshLocalTarget `
    -Label "config/ssh/config.local" `
    -AllowEmptyFallback
Link-File -SourcePath $sshRepoLocal -TargetPath $sshLocalTarget -Name ".ssh/config.local"

$sshConfigFile = Join-Path $sshDir "config"
if ($Force -or (-not (Test-Path $sshConfigFile))) {
    Write-LogInfo "Populating ~/.ssh/config..."
    @"
Include ~/.ssh/config.local
Include ~/.akrista/config/ssh/config
"@ | Out-File -FilePath $sshConfigFile -Encoding utf8
}

Write-Host ""
Write-Host "Installation completed." -ForegroundColor Green
Write-Host "Reload your shell or restart your terminal to apply changes." -ForegroundColor Yellow
Write-Host ""
