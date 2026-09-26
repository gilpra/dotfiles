# ============================
# Start Sway on TTY1
# ============================

if [ -z "$WAYLAND_DISPLAY" ] && [ "$XDG_VTNR" = "1" ]; then
    exec "$HOME/.config/sway/scripts/start-sway"
fi
