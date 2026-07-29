#!/bin/sh
# Waybar blue-light filter pill: ON (always warm) → OFF (never) → AUTO
# (warm 21:00–05:00) → … via wlsunset. State persists across reboots.

STATE_FILE="$HOME/.local/state/armojidots/bluelight"
mkdir -p "$(dirname "$STATE_FILE")"
cur=$(cat "$STATE_FILE" 2>/dev/null || echo auto)

apply() {
  pkill -x wlsunset 2>/dev/null
  case "$1" in
    # wlsunset rejects an equal low/high temp outright, so "always warm" is
    # done by making the day window zero-length (sunset == sunrise) instead
    # — it's then perpetually in the "night" (low-temp) phase.
    on)   setsid -f wlsunset -t 3000 -T 6500 -s 00:00 -S 00:00 >/dev/null 2>&1 ;;
    auto) setsid -f wlsunset -t 3000 -T 6500 -s 21:00 -S 05:00 >/dev/null 2>&1 ;;
    off)  ;;   # no process running = no gamma adjustment (wlsunset resets on exit)
  esac
}

case "$1" in
  status)
    case "$cur" in
      on)   icon="󰛨"; tip="blue light: ON (always)" ;;
      off)  icon="󰃟"; tip="blue light: OFF" ;;
      *)    icon="󰥔"; tip="blue light: AUTO (21:00-05:00)" ;;
    esac
    printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' "$icon" "$tip" "$cur"
    ;;
  toggle)
    case "$cur" in
      on)   next=off ;;
      off)  next=auto ;;
      *)    next=on ;;
    esac
    printf '%s\n' "$next" > "$STATE_FILE"
    apply "$next"
    pkill -SIGRTMIN+9 waybar
    ;;
  startup)
    apply "$cur"
    ;;
esac
