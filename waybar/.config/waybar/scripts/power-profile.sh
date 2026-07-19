#!/bin/sh
# Waybar power-profile pill: shows current profile, click cycles
# power-saver → balanced → performance → …

cur=$(powerprofilesctl get)

case "$1" in
  status)
    case "$cur" in
      performance) icon="󰓅" ;;
      balanced)    icon="󰾅" ;;
      power-saver) icon="󰾆" ;;
      *)           icon="󰾅" ;;
    esac
    printf '{"text":"%s","tooltip":"profile: %s","class":"%s"}\n' "$icon" "$cur" "$cur"
    ;;
  toggle)
    case "$cur" in
      power-saver) powerprofilesctl set balanced ;;
      balanced)    powerprofilesctl set performance ;;
      performance) powerprofilesctl set power-saver ;;
    esac
    pkill -SIGRTMIN+8 waybar
    ;;
esac
