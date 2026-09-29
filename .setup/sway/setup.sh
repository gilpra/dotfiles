#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
PROFILE_DIR="$ROOT_DIR/sway"
PKG_FILE="$SCRIPT_DIR/packages.txt"

log() { printf '[INFO] %s\n' "$1"; }
warn() { printf '[WARN] %s\n' "$1" >&2; }
ok() { printf '[OK]   %s\n' "$1"; }
die() {
    printf '[ERR]  %s\n' "$1" >&2
    exit 1
}

if [[ $EUID -eq 0 ]]; then
    die 'Do not run this script as root. Run it as a regular user.'
fi

[[ -d "$ROOT_DIR" ]] || die "Dotfiles directory not found: $ROOT_DIR"
[[ -d "$PROFILE_DIR" ]] || die "Sway profile directory not found: $PROFILE_DIR"
[[ -f "$PKG_FILE" ]] || die "Package file not found: $PKG_FILE"

command -v sudo >/dev/null 2>&1 || die 'sudo is required.'
command -v xbps-install >/dev/null 2>&1 || die 'This profile is for Void Linux (xbps-install not found).'
command -v git >/dev/null 2>&1 || die 'git is required.'
command -v curl >/dev/null 2>&1 || die 'curl is required.'
command -v stow >/dev/null 2>&1 || {
    log 'stow is not installed; installing it first...'
    sudo xbps-install -y stow
}

read_packages() {
    local file="$1"
    local line

    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"
        [[ -z "$line" || "$line" == \#* ]] && continue
        printf '%s\n' "$line"
    done <"$file"
}

mapfile -t packages < <(read_packages "$PKG_FILE")
((${#packages[@]})) || die 'No packages found in packages.txt.'

log 'Synchronizing and upgrading Void Linux...'
sudo xbps-install -Suy

log 'Installing Sway profile packages...'
sudo xbps-install -y "${packages[@]}"

# Ensure the Bluetooth daemon is enabled under runit.
if [[ -d /etc/sv/bluetoothd ]]; then
    sudo ln -sfn /etc/sv/bluetoothd /var/service/bluetoothd
    sudo usermod -aG bluetooth "$USER"
    ok 'bluetoothd enabled and user added to bluetooth group'
else
    warn 'bluez installed but /etc/sv/bluetoothd was not found.'
fi

# Set zsh as the login shell when available.
if command -v zsh >/dev/null 2>&1; then
    zsh_path="$(command -v zsh)"
    if [[ "${SHELL:-}" != "$zsh_path" ]]; then
        log 'Setting zsh as the default login shell...'
        if chsh -s "$zsh_path"; then
            ok "zsh is now the default shell"
        else
            warn "Failed to change shell. Run manually: chsh -s $zsh_path"
        fi
    else
        ok 'zsh is already the default login shell'
    fi
fi

# Create user directories used by the profile/assets.
mkdir -p \
    "$HOME/.local/bin" \
    "$HOME/.local/share/fonts" \
    "$HOME/.local/share/themes" \
    "$HOME/.local/share/icons" \
    "$HOME/.local/share/bin"

# GNU Stow links the complete Sway profile into $HOME.
log 'Creating dotfile symlinks with GNU Stow...'
cd "$ROOT_DIR"
stow -R --dir="$ROOT_DIR" --target="$HOME" sway

# Install 0xProto Nerd Font.
if [[ ! -d "$HOME/.local/share/fonts/0xProto" ]]; then
    log 'Downloading 0xProto Nerd Font...'
    proto_url="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/0xProto.tar.xz"
    proto_tmp="$(mktemp -d)"
    trap 'rm -rf "$proto_tmp"' EXIT

    curl -fL --output "$proto_tmp/proto.tar.xz" "$proto_url"
    mkdir -p "$HOME/.local/share/fonts/0xProto"
    tar -xJf "$proto_tmp/proto.tar.xz" -C "$HOME/.local/share/fonts/0xProto"

    rm -rf "$proto_tmp"
    trap - EXIT
    ok '0xProto Nerd Font installed'
fi

# Refresh Fontconfig cache after installing the custom font.
fc-cache -f "$HOME/.local/share/fonts"

# Clone Monochrome GTK theme.
if [[ ! -d "$HOME/.local/share/themes/Monochrome-Dark" ]]; then
    log 'Cloning Monochrome-Dark theme...'
    git clone --depth 1 https://github.com/gilpra/monochrome-gtk \
        "$HOME/.local/share/themes/Monochrome-Dark"
    ok 'Monochrome-Dark GTK theme installed'
fi

# Install Tela-circle icon theme.
if [[ ! -d "$HOME/.local/share/icons/Tela-circle" ]]; then
    log 'Installing Tela-circle icon theme...'
    tela_tmp="$(mktemp -d)"
    trap 'rm -rf "$tela_tmp"' EXIT

    git clone --depth 1 https://github.com/vinceliuice/Tela-circle-icon-theme \
        "$tela_tmp/tela-circle"
    bash "$tela_tmp/tela-circle/install.sh"

    rm -rf "$tela_tmp"
    trap - EXIT
    ok 'Tela-circle icon theme installed'
fi

# Install Bibata cursor.
if [[ ! -d "$HOME/.local/share/icons/Bibata-Modern-Ice" ]]; then
    log 'Downloading Bibata-Modern-Ice cursor...'
    bibata_url="https://github.com/ful1e5/Bibata_Cursor/releases/download/v2.0.7/Bibata-Modern-Ice.tar.xz"
    bibata_tmp="$(mktemp -d)"
    trap 'rm -rf "$bibata_tmp"' EXIT

    curl -fL --output "$bibata_tmp/bibata.tar.xz" "$bibata_url"
    tar -xJf "$bibata_tmp/bibata.tar.xz" -C "$HOME/.local/share/icons"

    rm -rf "$bibata_tmp"
    trap - EXIT
    ok 'Bibata-Modern-Ice cursor installed'
fi

echo
echo 'Setup completed.'
echo 'Log out and log in again once so new group membership (bluetooth) is active.'
