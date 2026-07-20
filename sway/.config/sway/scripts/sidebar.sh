#!/bin/sh
# Quick-access sidebar terminals (scratchpad-backed: hidden, never killed).
# usage: sidebar.sh term | claude

name="sidebar-$1"
case "$1" in
  term)   cmd="env SIDEBAR=1 foot --app-id=$name" ;;
  claude) cmd="foot --app-id=$name claude --resume" ;;
  *)      exit 1 ;;
esac

if swaymsg -t get_tree --raw | jq -e --arg a "$name" \
     '[recurse | objects | select(.app_id? == $a)] | length > 0' >/dev/null; then
  # exists → toggle visibility; every show resets to the default spot/size
  swaymsg "[app_id=\"$name\"] scratchpad show" >/dev/null
  swaymsg "[app_id=\"$name\"] resize set 480 px 1014 px" >/dev/null 2>&1 || true
  swaymsg "[app_id=\"$name\"] move position 0 0" >/dev/null 2>&1 || true
else
  $cmd &
fi
