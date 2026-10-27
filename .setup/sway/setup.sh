#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
PROFILE_DIR="$ROOT_DIR/sway"
PKG_FILE="$SCRIPT_DIR/packages.txt"

log()  { printf '[INFO] %s\n' "$1"; }
warn() { printf '[WARN] %s\n' "$1" >&2; }
ok()   { printf '[OK]   %s\n' "$1"; }
die()  { printf '[ERR]  %s\n' "$1" >&2; exit 1; }

TEMP_DIRS=()
cleanup() {
    local dir
    for dir in "${TEMP_DIRS[@]}"; do
        [[ -n "$dir" && -d "$dir" ]] && rm -rf -- "$dir"
    done
}
trap cleanup EXIT

make_tmpdir() {
    LAST_TMP_DIR="$(mktemp -d)"
    TEMP_DIRS+=("$LAST_TMP_DIR")
}

# Do not run this setup as root: files must be owned by the current user.
[[ "$EUID" -ne 0 ]] || die 'Do not run this script as root. Run it as a regular user.'

[[ -r /etc/os-release ]] || die 'Cannot detect operating system: /etc/os-release is missing.'
# shellcheck source=/dev/null
source /etc/os-release
[[ "${ID:-}" == fedora ]] || die "Fedora is required (detected: ${ID:-unknown})."
[[ "${VERSION_ID:-}" == 44 ]] || die "This script targets Fedora 44 (detected: ${VERSION_ID:-unknown})."

for cmd in dnf rpm sudo; do
    command -v "$cmd" >/dev/null 2>&1 || die "Required command not found: $cmd"
done
[[ -d "$ROOT_DIR" ]] || die "Dotfiles directory not found: $ROOT_DIR"
[[ -d "$PROFILE_DIR" ]] || die "Sway dotfiles directory not found: $PROFILE_DIR"
[[ -f "$PKG_FILE" ]] || die "Package list not found: $PKG_FILE"

log 'Requesting sudo authentication...'
sudo -v

install_packages() {
    local file="$1"
    local pkg
    local -a missing=()

    log "Checking packages from '$file'..."
    while IFS= read -r pkg || [[ -n "$pkg" ]]; do
        # Trim leading/trailing whitespace.
        pkg="${pkg#"${pkg%%[![:space:]]*}"}"
        pkg="${pkg%"${pkg##*[![:space:]]}"}"

        # Ignore blank lines and comments.
        [[ -z "$pkg" || "$pkg" == \#* ]] && continue

        if rpm -q -- "$pkg" >/dev/null 2>&1; then
            ok "$pkg already installed"
        else
            missing+=("$pkg")
        fi
    done < "$file"

    if ((${#missing[@]} == 0)); then
        ok 'All packages listed in packages.txt are installed'
        return 0
    fi

    log "Installing ${#missing[@]} missing packages (without weak dependencies)..."
    sudo dnf --setopt=install_weak_deps=False install -y "${missing[@]}"
    ok 'Fedora packages installed'
}

install_packages "$PKG_FILE"

# Set Zsh as the user's login shell.
if command -v zsh >/dev/null 2>&1; then
    zsh_path="$(command -v zsh)"
    current_shell="$(getent passwd "$USER" | cut -d: -f7 || true)"

    if [[ "$(basename -- "${current_shell:-sh}")" != zsh ]]; then
        log 'Setting Zsh as the default login shell...'
        if chsh -s "$zsh_path"; then
            ok 'Zsh is now the default login shell'
        else
            warn "Could not change login shell automatically. Run: chsh -s $zsh_path"
        fi
    else
        ok 'Zsh is already the default login shell'
    fi
else
    warn 'Zsh is not installed; skipping login-shell configuration.'
fi

# Set up user directories and link only the custom sway profile.
log 'Creating user directories...'
mkdir -p \
    "$HOME/.local/bin" \
    "$HOME/.local/share/fonts" \
    "$HOME/.local/share/themes" \
    "$HOME/.local/share/icons" \
    "$HOME/.local/share/bin"

log 'Linking the Sway dotfiles with GNU Stow...'
cd "$ROOT_DIR"
stow --restow --dir="$ROOT_DIR" --target="$HOME" sway
ok 'Sway dotfiles linked'

# Install 0xProto Nerd Font locally (no root access needed).
FONT_DIR="$HOME/.local/share/fonts/0xProto"
if [[ -d "$FONT_DIR" ]] && find "$FONT_DIR" -type f -print -quit | grep -q .; then
    ok '0xProto Nerd Font already installed'
else
    log 'Installing 0xProto Nerd Font...'
    make_tmpdir
    proto_tmp="$LAST_TMP_DIR"
    proto_url='https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/0xProto.tar.xz'
    curl --fail --location --retry 3 --output "$proto_tmp/proto.tar.xz" "$proto_url"
    mkdir -p "$proto_tmp/extracted" "$HOME/.local/share/fonts"
    tar -xJf "$proto_tmp/proto.tar.xz" -C "$proto_tmp/extracted"
    rm -rf -- "$FONT_DIR"
    mv "$proto_tmp/extracted" "$FONT_DIR"
    ok '0xProto Nerd Font installed'
fi

# Install Monochrome GTK theme locally.
THEME_DIR="$HOME/.local/share/themes/Monochrome-Dark"
if [[ -d "$THEME_DIR" ]]; then
    ok 'Monochrome-Dark GTK theme already present'
else
    log 'Cloning Monochrome-Dark GTK theme...'
    git clone --depth 1 \
        https://github.com/gilpra/monochrome-gtk \
        "$THEME_DIR"
    ok 'Monochrome-Dark GTK theme installed'
fi

# Install Tela-circle icons locally.
TELA_DIR="$HOME/.local/share/icons/Tela-circle"
if [[ -d "$TELA_DIR" ]]; then
    ok 'Tela-circle icon theme already present'
else
    log 'Installing Tela-circle icon theme...'
    make_tmpdir
    tela_tmp="$LAST_TMP_DIR"
    git clone --depth 1 \
        https://github.com/vinceliuice/Tela-circle-icon-theme \
        "$tela_tmp/tela-circle"
    bash "$tela_tmp/tela-circle/install.sh" -c -d "$HOME/.local/share/icons"
    [[ -d "$TELA_DIR" ]] || warn 'Tela-circle installer finished but its theme directory was not found; check the installer output.'
fi

# Install Bibata cursor locally.
BIBATA_DIR="$HOME/.local/share/icons/Bibata-Modern-Ice"
if [[ -d "$BIBATA_DIR" ]]; then
    ok 'Bibata-Modern-Ice cursor already present'
else
    log 'Installing Bibata-Modern-Ice cursor...'
    make_tmpdir
    bibata_tmp="$LAST_TMP_DIR"
    bibata_url='https://github.com/ful1e5/Bibata_Cursor/releases/download/v2.0.7/Bibata-Modern-Ice.tar.xz'
    curl --fail --location --retry 3 --output "$bibata_tmp/bibata.tar.xz" "$bibata_url"
    tar -xJf "$bibata_tmp/bibata.tar.xz" -C "$HOME/.local/share/icons"
    [[ -d "$BIBATA_DIR" ]] || warn 'Bibata extracted, but the expected theme directory was not found; check the archive contents.'
fi

# Refresh user font cache after a local font installation.
if command -v fc-cache >/dev/null 2>&1; then
    fc-cache --force "$HOME/.local/share/fonts"
fi

# These services power the network/Bluetooth menus and laptop power menu.
# Keep failures non-fatal for systems where a service is unavailable/masked.
enable_service() {
    local service="$1"
    if sudo systemctl enable --now "$service"; then
        ok "$service enabled"
    else
        warn "Could not enable $service; check it manually if you use this feature."
    fi
}

if command -v systemctl >/dev/null 2>&1; then
    enable_service NetworkManager.service
    enable_service bluetooth.service
    enable_service power-profiles-daemon.service
fi

cat <<'MESSAGE'

Setup finished.

Next steps:
  1. Check the optional commands listed in README.md (for example Firefox,
     Neovim, fzf, lazygit, tmux, ouch, ani-cli, and custom menu scripts).
  2. Add your wallpaper at ~/.local/share/wallpapers/furina_1_mono.jpg or
     comment out the corresponding line in ~/.config/sway/conf.d/output.conf.
  3. Log out, switch to a TTY, and start Sway with your normal user account.

This setup intentionally does not install a desktop environment or display manager.
MESSAGE

ok 'Fedora 44 Sway setup completed'
