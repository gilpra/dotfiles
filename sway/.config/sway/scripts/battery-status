#!/usr/bin/env bash

BAT_PATH=$(find /sys/class/power_supply -maxdepth 1 -name 'BAT*' -print -quit)

[[ -n "$BAT_PATH" ]] || exit 1

capacity=$(<"$BAT_PATH/capacity")
status=$(<"$BAT_PATH/status")

case "$status" in
Charging)
    icon="󰂄"
    class="charging"
    ;;
Full)
    icon="󰁹"
    class="full"
    ;;
Discharging)
    if ((capacity <= 15)); then
        icon="󰂎"
        class="critical"
    elif ((capacity <= 30)); then
        icon="󰁺"
        class="warning"
    else
        index=$(((capacity + 9) / 10))
        ((index > 10)) && index=10
        icon=$(printf '%s\n' \
            "󰂎" \
            "󰁺" \
            "󰁻" \
            "󰁼" \
            "󰁽" \
            "󰁾" \
            "󰁿" \
            "󰂀" \
            "󰂁" \
            "󰂂" \
            "󰁹" |
            sed -n "$((index + 1))p")
        class="good"
    fi
    ;;
*)
    icon="󰁹"
    class="unknown"
    ;;
esac

printf '{"text":"%s %s%%","tooltip":"%s: %s%%","class":"%s"}\n' \
    "$icon" \
    "$capacity" \
    "$status" \
    "$capacity" \
    "$class"
