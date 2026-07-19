#!/bin/sh
# /set wallpaper: pick from the repo wallpapers, apply + persist via symlink
WALLDIR="$HOME/dotfiles/wallpapers"

pick=$(find "$WALLDIR" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
         -printf '%f\n' | sort | walker --dmenu -p "wallpaper ❯")
[ -z "$pick" ] && exit 0

ln -sf "$WALLDIR/$pick" "$WALLDIR/current"
pkill -x swaybg
swaymsg exec "swaybg -i '$WALLDIR/current' -m fill"
