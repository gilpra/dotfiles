#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$HOME/.dotfiles"
SWAY_DIR="$DOTFILES_DIR/sway-dots"
PKG_FILE="$SWAY_DIR/packages.txt"
AUR_FILE="$SWAY_DIR/aur-packages.txt"

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

if [[ ! -d "$DOTFILES_DIR" ]]; then
    die "Dotfiles directory not found: $DOTFILES_DIR"
fi

if [[ ! -d "$SWAY_DIR" ]]; then
    die "sway-dots directory not found: $SWAY_DIR"
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

# Install yay if missing
if ! command -v yay >/dev/null 2>&1; then
    log "yay not found, installing..."
    sudo pacman -S --needed --noconfirm git base-devel

    tmpdir="$(mktemp -d)"
    trap 'rm -rf "$tmpdir"' EXIT

    git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
    (cd "$tmpdir/yay" && makepkg -si --noconfirm)

    trap - EXIT
    rm -rf "$tmpdir"

    ok "yay installed"
fi

# AUR packages
log "Installing AUR packages..."
yay_inst=("yay" "-S" "--needed" "--noconfirm")
yay_qry=("yay" "-Q")
install_packages "$AUR_FILE" yay_inst yay_qry

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

# Enable ly display manager
if systemctl cat ly@.service >/dev/null 2>&1; then
    if systemctl is-enabled --quiet ly@tty2.service 2>/dev/null; then
        ok "Ly display manager already enabled"
    else
        log "Enabling Ly display manager..."

        sudo systemctl disable --now getty@tty2.service >/dev/null 2>&1

        if sudo systemctl enable ly@tty2.service >/dev/null 2>&1; then
            ok "Ly enabled on tty2"
        else
            warn "Failed to enable Ly"
        fi
    fi
else
    warn "Ly systemd service not found, skipping"
fi

# Ensure stow is installed
if ! command -v stow >/dev/null 2>&1; then
    log "stow not found, installing..."
    sudo pacman -S --needed --noconfirm stow
    ok "stow installed"
fi

# Create symlinks with stow
log "Creating symlinks using stow..."
mkdir -p "$HOME/.local/bin"
rm -f "$HOME/.config/fish/config.fish"
mkdir -p \
    "$HOME/.local/share/fonts" \
    "$HOME/.local/share/themes" \
    "$HOME/.local/share/icons" \
    "$HOME/.local/share/bin"

cd "$DOTFILES_DIR"
stow -R --target="$HOME" sway-dots

# Clone script for screenshot in wayland
curl -fsSL https://raw.githubusercontent.com/gilpra/dotbin/main/screenshot-wayland -o ~/.local/bin/screenshot-wayland && chmod +x ~/.local/bin/screenshot-wayland

# Clone script for toggle waybar
curl -fsSL https://raw.githubusercontent.com/gilpra/dotbin/main/toggle-waybar -o ~/.local/bin/toggle-waybar && chmod +x ~/.local/bin/toggle-waybar

# Install 0xProto
if [[ ! -d "$HOME/.local/share/fonts/0xProto" ]]; then
    log "Downloading 0xProto Nerd Font..."
    proto_url="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/0xProto.tar.xz"
    proto_tmp="$(mktemp -d)"
    trap 'rm -rf "$proto_tmp"' EXIT

    curl -L --fail --output "$proto_tmp/proto.tar.xz" "$proto_url"
    mkdir -p "$HOME/.local/share/fonts/0xProto"
    tar -xJf "$proto_tmp/proto.tar.xz" -C "$HOME/.local/share/fonts/0xProto"

    trap - EXIT
    rm -rf "$proto_tmp"
    ok "0xProto Nerd Font installed"
fi

# Clone Monochrome theme
if [[ ! -d "$HOME/.local/share/themes/Monochrome-Dark" ]]; then
    log "Cloning Monochrome-Dark theme..."
    git clone https://github.com/gilpra/monochrome-gtk \
        "$HOME/.local/share/themes/Monochrome-Dark"
    ok "Monochrome-Dark Gtk theme installed"
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
