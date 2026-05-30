#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$HOME/.dotfiles"
SWAY_DIR="$DOTFILES_DIR/dots-sway"
PKG_FILE="$SWAY_DIR/packages.txt"
AUR_FILE="$SWAY_DIR/aur-packages.txt"

log() { printf "[INFO] %s\n" "$1"; }
warn() { printf "[WARN] %s\n" "$1"; }
ok() { printf "[OK] %s\n" "$1"; }
