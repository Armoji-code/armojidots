#!/bin/sh
# /set monitors: reuse an already-open nwg-displays window instead of opening
# a second one. Checked via the sway tree, not `pgrep` — a zombie process
# (exited but unreaped by its parent) still matches pgrep by name, which
# would wrongly "find" a window that's no longer there.
# A fresh launch is floated/centered/focused by the [app_id="nwg-displays"]
# rule in rules.conf, right at map time.
if swaymsg -t get_tree | grep -q '"app_id": "nwg-displays"'; then
  swaymsg '[app_id="nwg-displays"] focus'
  exit 0
fi
exec nwg-displays
