#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/../.." && pwd)"

PROFILE_DIR="$ROOT_DIR/hyprland"
PKG_FILE="$SCRIPT_DIR/packages.txt"

log() { printf "[INFO] %s\n" "$1"; }
warn() { printf "[WARN] %s\n" "$1"; }
ok() { printf "[OK]   %s\n" "$1"; }
die() {
    printf "[ERR]  %s\n" "$1" >&2
    exit 1
}

if [[ "$EUID" -eq 0 ]]; then
    die "Do not run this script as root. Run as a regular user."
fi

if [[ ! -d "$ROOT_DIR" ]]; then
    die "Dotfiles directory not found: $ROOT_DIR"
fi

if [[ ! -d "$PROFILE_DIR" ]]; then
    die "dots-hypr directory not found: $PROFILE_DIR"
fi

install_packages() {
    local file="$1"
    local -n _installer="$2"
    local -n _query="$3"

    if [[ ! -f "$file" ]]; then
        warn "Package file '$file' not found, skipping."
        return
    fi

    log "Installing packages from '$file'..."

    while IFS= read -r pkg || [[ -n "$pkg" ]]; do
        # Skip blank lines and comments
        [[ -z "$pkg" || "$pkg" =~ ^[[:space:]]*$ || "$pkg" == \#* ]] && continue

        # Strip leading and trailing whitespace
        pkg="${pkg#"${pkg%%[![:space:]]*}"}"
        pkg="${pkg%"${pkg##*[![:space:]]}"}"

        if "${_query[@]}" "$pkg" &>/dev/null; then
            ok "$pkg already installed"
        else
            log "Installing $pkg..."
            "${_installer[@]}" "$pkg"
        fi
    done <"$file"
}

# Pacman packages
log "Installing pacman packages..."
pacman_inst=("sudo" "pacman" "-S" "--needed" "--noconfirm")
pacman_qry=("pacman" "-Q")
install_packages "$PKG_FILE" pacman_inst pacman_qry

# Set fish as default shell
if command -v fish >/dev/null 2>&1; then
    fish_path="$(command -v fish)"
    current_shell="$(basename "$SHELL")"

    if [[ "$current_shell" != "fish" ]]; then
        log "Setting fish as the default shell..."
        if chsh -s "$fish_path"; then
            ok "fish is now the default shell"
        else
            warn "Failed to change shell. Run manually: chsh -s $fish_path"
        fi
    else
        ok "fish is already the default shell"
    fi
else
    warn "fish not found, skipping shell configuration"
fi

# Ensure stow is installed
if ! command -v stow >/dev/null 2>&1; then
    log "stow not found, installing..."
    sudo pacman -S --needed --noconfirm stow
    ok "stow installed"
fi

# Create symlinks with stow
log "Creating symlinks using stow..."
mkdir -p \
    "$HOME/.local/share/themes" \
    "$HOME/.local/share/icons"

cd "$ROOT_DIR"
stow -R \
    --dir="$ROOT_DIR" \
    --target="$HOME" \
    hyprland

# Clone Tokyonight-Dark theme
if [[ ! -d "$HOME/.local/share/themes/Tokyonight-Dark" ]]; then
    log "Cloning Tokyonight-Dark theme..."
    git clone https://github.com/garpra/tokyodark-gtk \
        "$HOME/.local/share/themes/Tokyonight-Dark"
    ok "Tokyonight-Dark theme installed"
fi

# Install Tela-circle icon theme
if [[ ! -d "$HOME/.local/share/icons/Tela-circle" ]]; then
    log "Installing Tela-circle icon theme..."
    tela_tmp="$(mktemp -d)"
    trap 'rm -rf "$tela_tmp"' EXIT

    git clone https://github.com/vinceliuice/Tela-circle-icon-theme "$tela_tmp/tela-circle"
    bash "$tela_tmp/tela-circle/install.sh"

    trap - EXIT
    rm -rf "$tela_tmp"
    ok "Tela-circle icon theme installed"
fi

# Install Bibata-Modern-Ice cursor
if [[ ! -d "$HOME/.local/share/icons/Bibata-Modern-Ice" ]]; then
    log "Downloading Bibata-Modern-Ice cursor..."
    bibata_url="https://github.com/ful1e5/Bibata_Cursor/releases/download/v2.0.7/Bibata-Modern-Ice.tar.xz"
    bibata_tmp="$(mktemp -d)"
    trap 'rm -rf "$bibata_tmp"' EXIT

    curl -L --fail --output "$bibata_tmp/bibata.tar.xz" "$bibata_url"
    tar -xJf "$bibata_tmp/bibata.tar.xz" -C "$HOME/.local/share/icons"

    trap - EXIT
    rm -rf "$bibata_tmp"
    ok "Bibata-Modern-Ice cursor installed"
fi

ok "Setup completed!"
