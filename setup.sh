#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case "$1" in
    sway|hyprland|xfce)
        "$SCRIPT_DIR/.setup/$1/setup.sh" "${@:2}"
        ;;
    *)
        echo "Usage: $0 {sway|hyprland|xfce}"
        exit 1
        ;;
esac
