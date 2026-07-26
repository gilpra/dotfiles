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
if systemctl list-unit-files | grep -q "^ly.service"; then
  log "Enabling ly display manager..."
  if sudo systemctl enable ly@tty2.service >/dev/null 2>&1; then
    ok "ly enabled"
  else
    warn "Failed to enable ly"
  fi
else
  warn "ly.service not found, display manager not enabled"
fi

# Ensure stow installed
if ! command -v stow >/dev/null 2>&1; then
    log "stow not found, installing..."
    sudo pacman -S --needed --noconfirm stow
    ok "stow installed"
fi

log "Creating symlinks using stow..."
mkdir -p \
    "$HOME/.local/share/themes" \
    "$HOME/.local/share/icons"

cd "$DOTFILES_DIR"
stow --target="$HOME" dots-sway

# Clone script for screenshot in wayland
curl -fsSL https://raw.githubusercontent.com/gilpra/dotbin/main/screenshot-wayland -o ~/.local/bin/screenshot-wayland && chmod +x ~/.local/bin/screenshot-wayland

# Clone script for toggle waybar
curl -fsSL https://raw.githubusercontent.com/gilpra/dotbin/main/toggle-waybar -o ~/.local/bin/toggle-waybar && chmod +x ~/.local/bin/toggle-waybar

# Clone Tokyonight-Night theme
if [[ ! -d "$HOME/.local/share/themes/Tokyonight-Night" ]]; then
  log "Cloning Tokyonight-Night theme..."
  git clone https://github.com/garpra/tokyonight-gtk \
    "$HOME/.local/share/themes/Tokyonight-Night"
  ok "Tokyonight-Night Gtk theme installed"
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

ok "Setup completed"
