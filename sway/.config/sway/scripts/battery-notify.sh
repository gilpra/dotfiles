#!/usr/bin/env bash
PIDFILE="/tmp/battery-notify.pid"

# Kill instance lama kalau masih hidup
if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
    kill "$(cat "$PIDFILE")"
fi
echo $$ >"$PIDFILE"

BAT_PATH=$(find /sys/class/power_supply -maxdepth 1 -name "BAT*" | head -n1)
LOW=20
CRITICAL=10
[ -n "$BAT_PATH" ] || exit 0
STATE="normal"
while true; do
    BAT=$(<"$BAT_PATH/capacity")
    STATUS=$(<"$BAT_PATH/status")
    if [ "$STATUS" = "Discharging" ]; then
        if [ "$BAT" -le "$CRITICAL" ]; then
            if [ "$STATE" != "critical" ]; then
                notify-send -u critical -t 0 "Battery Critical" "$BAT% remaining!"
                STATE="critical"
            fi
        elif [ "$BAT" -le "$LOW" ]; then
            if [ "$STATE" = "normal" ]; then
                notify-send -u normal -t 5000 "Battery Low" "$BAT% remaining"
                STATE="low"
            fi
        else
            STATE="normal"
        fi
    else
        STATE="normal"
    fi
    sleep 60
done
