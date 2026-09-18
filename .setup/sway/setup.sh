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

# Set zsh as default shell
if command -v zsh >/dev/null 2>&1; then
    zsh_path="$(command -v zsh)"
    current_shell="$(basename "$SHELL")"

    if [[ "$current_shell" != "zsh" ]]; then
        log "Setting zsh as the default shell..."
        if chsh -s "$zsh_path"; then
            ok "zsh is now the default shell"
        else
            warn "Failed to change shell. Run manually: chsh -s $zsh_path"
        fi
    else
        ok "zsh is already the default shell"
    fi
else
    warn "zsh not found, skipping shell configuration"
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
