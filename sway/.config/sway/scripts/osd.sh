#!/bin/sh
# Volume/brightness change for media-keys.conf. The OSD pill (armoji-shell,
# Osd.qml) watches the levels itself, so nothing needs to be told here.
case "$1" in
  volume-up)       wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+ ;;
  volume-down)     wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- ;;
  mute-toggle)     wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
  brightness-up)   brightnessctl set 5%+ >/dev/null ;;
  brightness-down) brightnessctl set 5%- >/dev/null ;;
esac
