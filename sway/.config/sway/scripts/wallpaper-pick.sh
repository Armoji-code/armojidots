#!/bin/sh
# Set the wallpaper and persist it via the `current` symlink that swaybg and
# theme.sh both read. Wallpapers live in ~/Pictures/Wallpapers.
#   wallpaper-pick.sh "<path>"   set that image (spotlight's /wallpaper page)
LINK="$HOME/dotfiles/wallpapers/current"

pick="$1"
[ -f "$pick" ] || { notify-send "wallpaper" "not found: $pick"; exit 1; }

mkdir -p "$(dirname "$LINK")"
ln -sf "$pick" "$LINK"
pkill -x swaybg
swaymsg exec "swaybg -i '$LINK' -m fill"

# the wallpaper-driven palette follows the new wallpaper
if [ "$(cat "$HOME/.local/state/armojidots/theme" 2>/dev/null)" = "wallpaper" ]; then
  "$HOME/.config/sway/scripts/theme.sh" apply wallpaper
fi
