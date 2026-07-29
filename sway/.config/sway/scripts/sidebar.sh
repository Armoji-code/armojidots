#!/bin/sh
# Quick-access sidebar terminals (scratchpad-backed: hidden, never killed).
# kitty as a NORMAL window (not the layer-shell quick-access-terminal kitten
# — that had a persistent hide-transition blur artifact bug).
# Position/size are controlled separately (sidebar-control.sh, Win+Shift+Arrows
# / Win+Arrows) and persisted per-sidebar; every show re-applies the saved
# geometry, defaulting to left-docked/480px on first-ever launch.
# usage: sidebar.sh term | claude

name="sidebar-$1"
case "$1" in
  term)   cmd="kitty --app-id=$name -o env=SIDEBAR=1 fish" ;;
  claude) cmd="kitty --app-id=$name claude" ;;
  *)      exit 1 ;;
esac

if swaymsg -t get_tree --raw | jq -e --arg a "$name" \
     '[recurse | objects | select(.app_id? == $a)] | length > 0' >/dev/null; then
  swaymsg "[app_id=\"$name\"] scratchpad show" >/dev/null
else
  $cmd &
  sleep 0.3   # let the window map before rules.conf's for_window + our resize race
fi
# Win+Shift+Arrows / Win+Arrows act on whichever sidebar was shown/toggled
# most recently — recorded here since "currently focused window" is
# unreliable (the sidebar doesn't always hold keyboard focus after summon)
printf '%s' "$name" > "$HOME/.local/state/armojidots/last-sidebar"
~/.config/sway/scripts/sidebar-control.sh apply "$name"
