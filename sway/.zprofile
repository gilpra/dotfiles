# ============================
# Start Sway on TTY1
# ============================

if [ -z "$WAYLAND_DISPLAY" ] && [ "$XDG_VTNR" = "1" ]; then
    # Temporary workaround for Void Linux audio
    sudo udevadm trigger --subsystem-match=sound

    exec "$HOME/.config/sway/scripts/start-sway"
fi

