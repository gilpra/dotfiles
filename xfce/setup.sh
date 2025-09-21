#!/usr/bin/env bash
set -euo pipefail

DOTFILES_REPO="$HOME/.dotfiles/dots-xfce"
PKG_FILE="$DOTFILES_REPO/packages.txt"

echo "==> Installing required packages..."

if [[ -f "$PKG_FILE" ]]; then
    echo -e "\nInstalling packages from 'packages.txt'..."
    while IFS= read -r pkg; do
        [[ -z "$pkg" || "$pkg" == \#* ]] && continue
        if ! pacman -Q "$pkg" &>/dev/null; then
            echo "  ➜ Installing $pkg..."
            sudo pacman -S --needed --noconfirm "$pkg"
        else
            echo "  ✓ $pkg already installed"
        fi
    done <"$PKG_FILE"
else
    echo "No 'packages.txt' found, skipped."
fi

