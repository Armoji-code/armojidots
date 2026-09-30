#!/bin/sh
# Sidebar terminal geometry: position (which edge) + size (3 stages).
# All keybinds are vim-style toggles (Win+Arrow / Win+Shift+Arrow are
# confirmed to never reach sway on this hardware — pinned, unfixed):
#   sidebar-control.sh apply <name>            re-apply saved geometry
#   sidebar-control.sh position <l|r|top|bottom>  set an exact position directly
#   sidebar-control.sh toggle-sides   left<->right, or top<->bottom — whichever
#                                      axis it's currently docked on
#   sidebar-control.sh toggle-mode    sides (left/right) <-> middle (top/bottom)
#   sidebar-control.sh toggle-size    cycle default -> half -> full -> default
#
# Position: which edge it docks to — left/right keep it vertical (full
# height); top/bottom flip it horizontal (a slim, centered 90-cell-wide
# strip, not full width).
# Size: 3 stages on the "thickness" axis (width for left/right, height for
# top/bottom) — default (25%) -> half (50%) -> full (100% of the true safe
# max for that axis, so "full" always means the actual biggest it can go).
#
# State is kept per-sidebar (term vs claude). Which sidebar these keybinds
# act on is the LAST ONE SHOWN (scripts/sidebar.sh records this on every
# show) — NOT "currently focused window", which is unreliable here (the
# sidebar doesn't always hold keyboard focus after being summoned).
#
# Placement uses `move absolute position` (layout coordinates: output origin
# + inset), so it lands correctly on any output — including one that is not
# at 0,0 (a plain `move position` is workspace-relative, and adding the
# output offset to it threw the sidebar a whole screen off to the right).

STATE_DIR="$HOME/.local/state/armojidots"
mkdir -p "$STATE_DIR"

OY=61    # top inset that clears the bar
GAP=12   # visual inset from a true screen edge, no bar involved
CROSS_TB=920   # ~90 terminal cells at font_size 13 (JetBrainsMono Nerd Font)

last_sidebar() {
  cat "$STATE_DIR/last-sidebar" 2>/dev/null
}

# exits (no-op) if there's no last-shown sidebar; otherwise prints its name
require_sidebar() {
  name=$(last_sidebar)
  case "$name" in
    sidebar-*) printf '%s' "$name" ;;
    *) exit 0 ;;
  esac
}

current_pos() {
  cat "$STATE_DIR/${1}.pos" 2>/dev/null || echo left
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
  case "$pos:$stage" in
    left:default|right:default) thick=$((safe_max * 25 / 100)) ;;
    top:default|bottom:default) thick=$((safe_max * 32 / 100)) ;;  # a bit roomier than the side default
    *:half)                     thick=$((safe_max * 50 / 100)) ;;
    *:full)                     thick=$safe_max ;;
  esac

  # desired on-screen rect: ax,ay = top-left relative to the output
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
      # default stays a slim, centered strip; half/full widen to match a
      # real tiled window's full width (only the height differs between
      # them at that point) — the same "half a tiled window" feel as the
      # side modes' half stage, just on the other axis
      if [ "$stage" = default ]; then
        ax=$(((ow - CROSS_TB) / 2)); w=$CROSS_TB
      else
        ax=$GAP;                     w=$((ow - GAP * 2))
      fi
      ay=$OY; h=$thick
      ;;
    bottom)
      if [ "$stage" = default ]; then
        ax=$(((ow - CROSS_TB) / 2)); w=$CROSS_TB
      else
        ax=$GAP;                     w=$((ow - GAP * 2))
      fi
      ay=$((oh - thick - GAP)); h=$thick
      ;;
  esac

  swaymsg "[app_id=\"$name\"] resize set $w px $h px" >/dev/null
  swaymsg "[app_id=\"$name\"] move absolute position $((ox + ax)) $((oy + ay))" >/dev/null
}

case "$1" in
  apply)
    apply "$2"
    ;;
  position)
    name=$(require_sidebar)
    printf '%s' "$2" > "$STATE_DIR/${name}.pos"
    apply "$name"
    ;;
  toggle-sides)
    # context-aware within the current axis: left <-> right while docked to
    # a side, top <-> bottom while in middle mode (toggle-mode picks the axis)
    name=$(require_sidebar)
    pos=$(current_pos "$name")
    case "$pos" in
      left)   new=right ;;
      right)  new=left ;;
      top)    new=bottom ;;
      bottom) new=top ;;
    esac
    printf '%s' "$new" > "$STATE_DIR/${name}.pos"
    apply "$name"
    ;;
  toggle-mode)
    # sides (left/right) <-> middle (top/bottom), each side landing on a
    # fixed default (left / top) rather than remembering the last value
    name=$(require_sidebar)
    pos=$(current_pos "$name")
    case "$pos" in
      left|right) new=top ;;
      top|bottom) new=left ;;
    esac
    printf '%s' "$new" > "$STATE_DIR/${name}.pos"
    apply "$name"
    ;;
  toggle-size)
    # cycle the 3 thickness stages: default -> half -> full -> default
    name=$(require_sidebar)
    stage=$(cat "$STATE_DIR/${name}.stage" 2>/dev/null || echo default)
    case "$stage" in
      default) stage=half ;;
      half)    stage=full ;;
      full)    stage=default ;;
    esac
    printf '%s' "$stage" > "$STATE_DIR/${name}.stage"
    apply "$name"
    ;;
  *) exit 1 ;;
esac
