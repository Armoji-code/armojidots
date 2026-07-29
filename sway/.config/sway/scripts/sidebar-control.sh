#!/bin/sh
# Sidebar terminal geometry: position (which edge) + size (3 stages).
#   sidebar-control.sh apply <name>                 re-apply saved geometry
#   sidebar-control.sh position <l|r|top|bottom>     set + apply, on last-shown sidebar
#   sidebar-control.sh resize <up|down|left|right>   grow/shrink + apply, on last-shown
#
# Position: which edge it docks to — left/right keep it vertical (full
# height); top/bottom flip it horizontal (a slim, centered 90-cell-wide
# strip, not full width).
# Size: 3 stages on the "thickness" axis (width for left/right, height for
# top/bottom) — default (25%) -> half (50%) -> full (100% of the true safe
# max for that axis, so "full" always means the actual biggest it can go).
# Resize direction is POSITION-RELATIVE: whichever arrow points toward the
# screen center grows it (right for left-docked, left for right-docked,
# down for top-docked, up for bottom-docked) — matches the physical
# direction the panel visibly grows in.
#
# State is kept per-sidebar (term vs claude). Which sidebar these keybinds
# act on is the LAST ONE SHOWN (scripts/sidebar.sh records this on every
# show) — NOT "currently focused window", which is unreliable here (the
# sidebar doesn't always hold keyboard focus after being summoned).
#
# IMPORTANT: sway adds a CONSTANT offset to every floating `move position`
# request on this setup — always +12 to x, always +61 to y, regardless of
# the requested value (verified empirically, not a proximity/clamp thing).
# Every formula below requests (desired - offset) so the true on-screen
# result lands exactly at the desired inset from the real screen edge.

STATE_DIR="$HOME/.local/state/armojidots"
mkdir -p "$STATE_DIR"

OX=12    # sway's constant x offset on `move position`
OY=61    # sway's constant y offset on `move position` (also clears the bar)
GAP=12   # visual inset from a true screen edge, no bar involved
CROSS_TB=920   # ~90 terminal cells at font_size 13 (JetBrainsMono Nerd Font)

last_sidebar() {
  cat "$STATE_DIR/last-sidebar" 2>/dev/null
}

apply() {
  name="$1"
  pos=$(cat "$STATE_DIR/${name}.pos" 2>/dev/null || echo left)
  stage=$(cat "$STATE_DIR/${name}.stage" 2>/dev/null || echo default)

  set -- $(swaymsg -t get_outputs | python3 -c '
import sys, json
for o in json.load(sys.stdin):
    if o.get("focused"):
        r = o["rect"]
        print(r["x"], r["y"], r["width"], r["height"])
        break
')
  ox=$1; oy=$2; ow=$3; oh=$4

  # thickness stages — percentages of the TRUE SAFE MAX for that axis (not
  # raw screen width/height), so "full" always means the actual biggest it
  # can go without clipping, and default/half scale proportionally to that.
  case "$pos" in
    left|right) safe_max=$((ow - GAP * 2)) ;;              # width axis
    top|bottom) safe_max=$((oh - OY - GAP)) ;;              # height axis (bar clearance eats into it)
  esac
  case "$stage" in
    default) thick=$((safe_max * 25 / 100)) ;;
    half)    thick=$((safe_max * 50 / 100)) ;;
    full)    thick=$safe_max ;;
  esac

  # desired on-screen rect (ax,ay = true top-left; then compensate for
  # sway's constant offset to get the request that produces it)
  case "$pos" in
    left)
      ax=$GAP;                    ay=$OY
      w=$thick;                   h=$((oh - OY - GAP))
      ;;
    right)
      ax=$((ow - thick - GAP));   ay=$OY
      w=$thick;                   h=$((oh - OY - GAP))
      ;;
    top)
      ax=$(((ow - CROSS_TB) / 2)); ay=$OY
      w=$CROSS_TB;                 h=$thick
      ;;
    bottom)
      ax=$(((ow - CROSS_TB) / 2)); ay=$((oh - thick - GAP))
      w=$CROSS_TB;                 h=$thick
      ;;
  esac

  rx=$((ox + ax - OX))
  ry=$((oy + ay - OY))

  swaymsg "[app_id=\"$name\"] resize set $w px $h px" >/dev/null
  swaymsg "[app_id=\"$name\"] move position $rx $ry" >/dev/null
}

case "$1" in
  apply)
    apply "$2"
    ;;
  position)
    name=$(last_sidebar)
    case "$name" in sidebar-*) ;; *) exit 0 ;; esac
    printf '%s' "$2" > "$STATE_DIR/${name}.pos"
    apply "$name"
    ;;
  resize)
    name=$(last_sidebar)
    case "$name" in sidebar-*) ;; *) exit 0 ;; esac
    pos=$(cat "$STATE_DIR/${name}.pos" 2>/dev/null || echo left)
    stage=$(cat "$STATE_DIR/${name}.stage" 2>/dev/null || echo default)
    # position-relative: the arrow pointing toward screen center grows it
    case "$pos:$2" in
      left:right|right:left|top:down|bottom:up)     dir=grow ;;
      left:left|right:right|top:up|bottom:down)     dir=shrink ;;
      *) exit 0 ;;   # irrelevant axis for this dock (e.g. up/down while left-docked)
    esac
    case "$dir:$stage" in
      grow:default)   stage=half ;;
      grow:half)      stage=full ;;
      shrink:full)    stage=half ;;
      shrink:half)    stage=default ;;
      *) ;;   # already capped, no-op
    esac
    printf '%s' "$stage" > "$STATE_DIR/${name}.stage"
    apply "$name"
    ;;
  *) exit 1 ;;
esac
