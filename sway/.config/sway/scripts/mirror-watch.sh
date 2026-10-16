#!/bin/bash
# Keep the display duplicate (mirror.sh) in sync with hotplug: reconcile once
# at login, then again whenever sway reports an output change. mirror.sh is
# idempotent, so the events its own `output` commands cause settle immediately.
exec 9> "${XDG_RUNTIME_DIR:-/tmp}/mirror-watch.lock"
flock -n 9 || exit 0

M="$HOME/.config/sway/scripts/mirror.sh"
"$M" apply

swaymsg -t subscribe -m '["output"]' 9>&- | while read -r _; do
  sleep 1.5                                    # let the hotplug burst settle
  while read -r -t 0.2 _; do :; done           # drop the rest of the burst
  "$M" apply
done
