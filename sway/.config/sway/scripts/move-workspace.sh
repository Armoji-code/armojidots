#!/bin/sh
# Move ALL windows on the focused workspace to workspace N of the same
# monitor group (swaysome numbering: group digit + N), then follow.
# Usage: move-workspace.sh <1-10>

n="$1"
cur=$(swaymsg -t get_workspaces --raw | jq -r '.[] | select(.focused).name')
group=$(printf '%s' "$cur" | cut -c1)
target="${group}${n}"

[ "$cur" = "$target" ] && exit 0

swaymsg "[workspace=__focused__] move container to workspace number $target"
swaymsg "workspace number $target"
