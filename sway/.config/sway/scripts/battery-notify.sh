#!/bin/bash

BAT_PATH="/sys/class/power_supply/BAT1"
LOW=20
CRITICAL=10

[ -f "$BAT_PATH/capacity" ] || exit 0

STATE="normal"

while true; do
  BAT=$(cat "$BAT_PATH/capacity")
  STATUS=$(cat "$BAT_PATH/status")

  if [ "$STATUS" = "Discharging" ]; then

    if [ "$BAT" -le "$CRITICAL" ] && [ "$STATE" != "critical" ]; then
      notify-send -u critical "Battery Critical" "$BAT% remaining!"
      STATE="critical"

    elif [ "$BAT" -le "$LOW" ] && [ "$STATE" != "low" ] && [ "$STATE" != "critical" ]; then
      notify-send "Battery Low" "$BAT% remaining"
      STATE="low"
    fi

  else
    STATE="normal"
  fi

  sleep 60
done
