#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$HOME/.dotfiles"
XFCE_DIR="$DOTFILES_DIR/dots-xfce"
PKG_FILE="$XFCE_DIR/packages.txt"

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

if [[ ! -d "$XFCE_DIR" ]]; then
    die "dots-xfce directory not found: $XFCE_DIR"
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

# Enable lightdm display manager
if pacman -Q lightdm &>/dev/null; then
    log "Enabling lightdm display manager..."
    if sudo systemctl enable lightdm.service >/dev/null 2>&1; then
        ok "lightdm enabled"
    else
        warn "Failed to enable lightdm"
    fi
else
    warn "lightdm.service not found, display manager not enabled"
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
    "$HOME/.local/share/themes"

cd "$DOTFILES_DIR"
stow -R --target="$HOME" dots-xfce

# Clone Tokyonight-Dark theme
if [[ ! -d "$HOME/.local/share/themes/Gruvbox-Dark" ]]; then
    log "Installing Gruvbox-dark icon theme..."
    gruvbox_tmp="$(mktemp -d)"
    trap 'rm -rf "$gruvbox_tmp"' EXIT

    git clone https://github.com/Fausto-Korpsvart/Gruvbox-GTK-Theme "$gruvbox_tmp/gruvbox-dark"
    bash "$gruvbox_tmp/gruvbox-dark/themes/install.sh" -d "$HOME/.local/share/themes" -c dark --tweaks macos

    trap - EXIT
    rm -rf "$gruvbox_tmp"
    ok "Gruvbox-dark icon theme installed"
fi

ok "Setup completed!"
