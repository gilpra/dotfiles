#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$HOME/.dotfiles"
SWAY_DIR="$DOTFILES_DIR/dots-sway"
PKG_FILE="$SWAY_DIR/packages.txt"
AUR_FILE="$SWAY_DIR/aur-packages.txt"

log() { printf "[INFO] %s\n" "$1"; }
warn() { printf "[WARN] %s\n" "$1"; }
ok() { printf "[OK] %s\n" "$1"; }

install_packages() {
    local file="$1"
    local installer="$2"
    local query_cmd="$3"

    if [[ ! -f "$file" ]]; then
        warn "File '$file' not found, skipping."
        return
    fi

    log "Installing packages from '$file'..."
    readarray -t packages <"$file"
    for pkg in "${packages[@]}"; do
        [[ -z "$pkg" || "$pkg" == \#* ]] && continue
        if ! $query_cmd "$pkg" &>/dev/null; then
            log "Installing $pkg..."
            $installer "$pkg"
        else
            ok "$pkg already installed"
        fi
    done
}

log "Installing required packages..."

# Pacman packages
install_packages \
    "$PKG_FILE" \
    'sudo pacman -S --needed --noconfirm' \
    'pacman -Q'

# Install yay if missing
if ! command -v yay >/dev/null 2>&1; then
    log "yay not found, installing..."
    sudo pacman -S --needed --noconfirm git base-devel
    tmpdir="$(mktemp -d)"
    git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
    (cd "$tmpdir/yay" && makepkg -si --noconfirm)
    rm -rf "$tmpdir"
    ok "yay installed"
fi

# AUR packages
install_packages \
    "$AUR_FILE" \
    'yay -S --needed --noconfirm' \
    'yay -Q'

# Enable Fish shell
if command -v fish >/dev/null 2>&1; then
    current_shell=$(basename "$SHELL")
    if [[ "$current_shell" != "fish" ]]; then
        log "Setting fish as default shell..."
        if chsh -s "$(command -v fish)"; then
            ok "Fish shell activated"
        else
            warn "Failed to change shell, run 'chsh -s $(command -v fish)' manually."
        fi
    fi
fi

# Enable ly display manager
if command -v ly >/dev/null 2>&1; then
    log "Enabling ly display manager..."
    sudo systemctl enable ly.service
    ok "ly enabled"
else
    warn "ly not found, display manager not enabled"
fi

# Ensure stow installed
if ! command -v stow >/dev/null 2>&1; then
    log "stow not found, installing..."
    sudo pacman -S --needed --noconfirm stow
    ok "stow installed"
fi

log "Creating symlinks using stow..."
cd "$DOTFILES_DIR"
stow --target="$HOME" dots-sway

ok "Setup completed"
