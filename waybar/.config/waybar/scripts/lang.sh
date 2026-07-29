#!/bin/sh
# Keyboard layout module: EN/LT set via input.conf's xkb_layout "us,lt" +
# xkb_options "grp:alt_shift_toggle" (native Shift+Alt chord, most reliable
# way to catch that combo — sway bindsym doesn't handle bare modifier chords
# well). This script just reacts to the resulting sway IPC event:
#   watch  → waybar's persistent exec: streams JSON text + fires a
#            notify-send toast on every layout change, from any trigger
#            (Shift+Alt, or the waybar button below)
#   toggle → waybar on-click: switches layout, which fires the same IPC
#            event watch() reacts to (single source of truth for the toast)

label() {
  case "$1" in
    *US*|*us*) echo "EN" ;;
    *Lithuania*|*lt*|*LT*) echo "LT" ;;
    *) echo "$1" ;;
  esac
}

case "$1" in
  toggle)
    swaymsg input type:keyboard xkb_switch_layout next >/dev/null
    ;;
  watch|"")
    # sway reports several "keyboard"-type input devices on this laptop (the
    # real keyboard plus virtual power/sleep/video-bus buttons) and the same
    # xkb config applies to all of them — pin to just the first one so we
    # don't emit/notify once per device on every switch
    target=$(swaymsg -t get_inputs | python3 -c '
import sys, json
for i in json.load(sys.stdin):
    if i.get("type") == "keyboard" and "xkb_active_layout_name" in i:
        print(i["identifier"]); break
')

    swaymsg -t get_inputs | python3 -c "
import sys, json
target = '$target'
for i in json.load(sys.stdin):
    if i.get('identifier') == target:
        print(i.get('xkb_active_layout_name', '')); break
" | while IFS= read -r name; do
      l=$(label "$name")
      printf '{"text":"󰌌 %s","tooltip":"%s"}\n' "$l" "$name"
    done

    swaymsg -t subscribe -m '["input"]' | python3 -u -c "
import sys, json
target = '$target'
for line in sys.stdin:
    try:
        e = json.loads(line)
    except ValueError:
        continue
    if e.get('change') != 'xkb_layout':
        continue
    i = e.get('input', {})
    if i.get('identifier') != target:
        continue
    print(i.get('xkb_active_layout_name', ''), flush=True)
" | while IFS= read -r name; do
      [ -z "$name" ] && continue
      l=$(label "$name")
      printf '{"text":"󰌌 %s","tooltip":"%s"}\n' "$l" "$name"
      notify-send -t 1500 -h string:x-canonical-private-synchronous:lang "󰌌 Keyboard layout" "Switched to $name"
    done
    ;;
esac
