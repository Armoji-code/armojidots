#!/bin/sh
# Duplicate the laptop panel onto any external display (Windows "Duplicate").
#
# sway can't mirror natively, so: the panel (eDP-1) stays the only real
# desktop; every external output is forced down to the panel's resolution,
# parked far away in the layout (the cursor and workspaces can never wander
# onto it) and covered by a fullscreen wl-mirror of the panel. A native-4K
# external at scale 1 under SwayFX blur is what made the machine crawl and
# waybar freeze, so the external never renders more than the panel's size.
#
#   mirror.sh apply    reconcile outputs + mirrors (idempotent; run on hotplug)
#   mirror.sh status   what it sees / is doing
#
# Extend instead: `echo extend > ~/.local/state/armojidots/display-mode`
# (spotlight's Monitors page does this) — then the layout is yours.
#
# Test hooks: MIRROR_TEST_JSON=<file> reads `swaymsg -t get_outputs` from a
# file, MIRROR_DRY_RUN=1 prints the commands instead of running them.

INTERNAL=eDP-1
GAP=8000      # layout distance panel -> external; the cursor can't cross it
LOG="${XDG_RUNTIME_DIR:-/tmp}/mirror.log"
MODE_FILE="$HOME/.local/state/armojidots/display-mode"   # mirror (default) | extend

get_outputs() {
  if [ -n "$MIRROR_TEST_JSON" ]; then cat "$MIRROR_TEST_JSON"; else swaymsg -t get_outputs --raw; fi
}

run() {
  if [ -n "$MIRROR_DRY_RUN" ]; then echo "swaymsg $*"; else swaymsg "$@" >/dev/null; fi
}

mirror_running() { pgrep -f "^wl-mirror --fullscreen-output $1 " >/dev/null 2>&1; }

stop_mirror() {
  [ -n "$MIRROR_DRY_RUN" ] && { echo "stop wl-mirror $1"; return; }
  pkill -f "^wl-mirror --fullscreen-output $1 " 2>/dev/null
}

start_mirror() {
  if [ -n "$MIRROR_DRY_RUN" ]; then echo "start wl-mirror --fullscreen-output $1 $INTERNAL"; return; fi
  if ! command -v wl-mirror >/dev/null 2>&1; then
    echo "$(date +%T) wl-mirror not installed (sudo pacman -S wl-mirror)" >> "$LOG"
    notify-send -u critical "Display mirroring" "wl-mirror is not installed:  sudo pacman -S wl-mirror"
    return
  fi
  # 9>&-: don't let the long-lived mirror inherit (and forever hold) the apply lock
  setsid -f wl-mirror --fullscreen-output "$1" "$INTERNAL" >> "$LOG" 2>&1 9>&-
}

# best mode for the external: the panel's own size, else the largest 16:9-ish
# mode that fits inside it; refresh capped at 60 Hz. Prints "WxH@HzHz" or nothing.
pick_mode() {  # json ext w h
  printf '%s' "$1" | jq -r --arg e "$2" --argjson w "$3" --argjson h "$4" '
    ($w / $h) as $r
    | .[] | select(.name == $e) | .modes
    | ( map(select(.width == $w and .height == $h and .refresh <= 60500)) | sort_by(-.refresh) | .[0] )
      // ( map(select(.width <= $w and .height <= $h and .refresh <= 60500
                       and ((((.width / .height) - $r) | fabs) < 0.01)))
           | sort_by(-(.width * .height), -.refresh) | .[0] )
      // empty
    | "\(.width)x\(.height)@\(.refresh / 1000)Hz"'
}

apply() {
  json=$(get_outputs) || exit 1
  set -- $(printf '%s' "$json" | jq -r --arg i "$INTERNAL" \
    '.[] | select(.name == $i and .active) | "\(.current_mode.width) \(.current_mode.height) \(.rect.x)"')
  iw=$1 ih=$2 ix=$3
  # no panel at all (desktop): leave the layout to sway/outputs
  printf '%s' "$json" | jq -e --arg i "$INTERNAL" 'any(.[]; .name == $i)' >/dev/null || return 0
  exts=$(printf '%s' "$json" | jq -r --arg i "$INTERNAL" '.[] | select(.name != $i) | .name')

  # extend mode (spotlight's Monitors page): no mirrors; an external still
  # parked far away from mirror mode moves next to the panel
  if [ "$(cat "$MODE_FILE" 2>/dev/null)" = extend ]; then
    for e in $exts; do
      stop_mirror "$e"
      ex=$(printf '%s' "$json" | jq -r --arg e "$e" '.[] | select(.name == $e) | .rect.x')
      [ "${ex:-0}" -ge "$GAP" ] && run output "$e" pos "${iw:-1920}" 0
    done
    return 0
  fi

  if [ -z "$iw" ]; then
    # panel is off (lid closed?) -> nothing to mirror; external works normally
    for e in $exts; do stop_mirror "$e"; run output "$e" enable pos 0 0; done
    return
  fi

  [ "$ix" != 0 ] && run output "$INTERNAL" pos 0 0

  if [ -z "$exts" ]; then
    if [ -n "$MIRROR_DRY_RUN" ]; then echo "no external output"; else pkill -x wl-mirror 2>/dev/null; fi
    return 0
  fi

  k=0
  for e in $exts; do
    k=$((k + 1))
    x=$((iw + GAP * k))
    mode=$(pick_mode "$json" "$e" "$iw" "$ih")
    want_w=${mode%%x*}; rest=${mode#*x}; want_h=${rest%%@*}
    cur=$(printf '%s' "$json" | jq -r --arg e "$e" '.[] | select(.name == $e)
          | "\(.current_mode.width // 0) \(.current_mode.height // 0) \(.rect.x) \(.rect.y) \(.scale) \(.active)"')
    changed=0
    if [ "$cur" != "${want_w:-0} ${want_h:-0} $x 0 1 true" ] && [ "$cur" != "${want_w:-0} ${want_h:-0} $x 0 1.0 true" ]; then
      # no usable mode (odd aspect ratio) -> leave the mode alone, only park it
      if [ -n "$mode" ]; then
        run output "$e" enable mode "$mode" scale 1 transform normal pos "$x" 0 adaptive_sync off
      else
        run output "$e" enable scale 1 transform normal pos "$x" 0 adaptive_sync off
      fi
      changed=1
    fi
    if [ "$changed" = 1 ]; then stop_mirror "$e"; sleep 0.6; fi
    if [ -n "$MIRROR_DRY_RUN" ] || ! mirror_running "$e"; then start_mirror "$e"; fi
  done
  return 0
}

case "$1" in
  apply)
    exec 9> "${XDG_RUNTIME_DIR:-/tmp}/mirror.lock"
    flock 9
    apply
    ;;
  status)
    get_outputs | jq -r '.[] | "\(.name)  \(.current_mode.width)x\(.current_mode.height)  at \(.rect.x),\(.rect.y)  scale \(.scale)  active=\(.active)"'
    pgrep -af '^wl-mirror ' || echo "wl-mirror: not running"
    ;;
  *) echo "usage: mirror.sh apply | status" >&2; exit 1 ;;
esac
