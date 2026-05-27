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

echo "Installing Oh My Zsh..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

echo "Installing Oh My Posh..."
curl -s https://ohmyposh.dev/install.sh | bash -s

exit
'@

Write-Host "Windows: Powershell"

Write-Host "Installing Oh My Posh..."
winget install -e --accept-source-agreements --accept-package-agreements JanDeDobbeleer.OhMyPosh --source winget