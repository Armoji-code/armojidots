#!/bin/sh
# Set the wallpaper and persist it via the `current` symlink that swaybg and
# theme.sh both read. Wallpapers live in ~/Pictures/Wallpapers.
#   wallpaper-pick.sh "<path>"   set that image directly
#                                (used by spotlight's /set wallpaper thumbnails)
#   wallpaper-pick.sh            no arg → dmenu picker (fallback)
WALLDIR="$HOME/Pictures/Wallpapers"
LINK="$HOME/dotfiles/wallpapers/current"

if [ -n "$1" ]; then
  pick="$1"
else
  name=$(find "$WALLDIR" -maxdepth 1 -type f \
           \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
           -printf '%f\n' | sort | walker --dmenu -p "wallpaper ❯")
  [ -z "$name" ] && exit 0
  pick="$WALLDIR/$name"
fi
[ -f "$pick" ] || { notify-send "wallpaper" "not found: $pick"; exit 1; }

ln -sf "$pick" "$LINK"
pkill -x swaybg
swaymsg exec "swaybg -i '$LINK' -m fill"

# the wallpaper-driven palette follows the new wallpaper
if [ "$(cat "$HOME/.local/state/armojidots/theme" 2>/dev/null)" = "wallpaper" ]; then
  "$HOME/.config/sway/scripts/theme.sh" apply wallpaper
fi
