#!/bin/sh
# Open walker only on a short TAP of the Win key.
# Held longer than 350ms (dragging, resizing, thinking) → ignored.

stamp="$XDG_RUNTIME_DIR/armoji-super-down"

case "$1" in
  down)
    date +%s%3N > "$stamp"
    ;;
  up)
    now=$(date +%s%3N)
    pressed=$(cat "$stamp" 2>/dev/null || echo 0)
    rm -f "$stamp"
    [ "$pressed" -gt 0 ] && [ $((now - pressed)) -lt 350 ] && exec walker
    ;;
esac
