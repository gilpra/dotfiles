#!/usr/bin/env bash

BAT_PATH=$(find /sys/class/power_supply -maxdepth 1 -name 'BAT*' -print -quit)
LOW=20
CRITICAL=10

[[ -n "$BAT_PATH" ]] || exit 0

state=normal

while sleep 60; do
    battery=$(<"$BAT_PATH/capacity")
    status=$(<"$BAT_PATH/status")

    if [[ "$status" != "Discharging" ]]; then
        state=normal
        continue
    fi

    if ((battery <= CRITICAL)) && [[ "$state" != "critical" ]]; then
        notify-send -u critical -t 0 \
            "Battery Critical" "$battery% remaining!"
        state=critical

    elif ((battery <= LOW)) && [[ "$state" == "normal" ]]; then
        notify-send -u normal -t 5000 \
            "Battery Low" "$battery% remaining"
        state=low

    elif ((battery > LOW)); then
        state=normal
    fi
done
