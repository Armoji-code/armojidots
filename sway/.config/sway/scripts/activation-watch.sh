#!/bin/sh
# Reimplements focus_on_window_activation's "focus" behavior (jump straight
# to a window that requests attention) via IPC, with a per-app exception
# list — sway's own directive is global-only and can't express "except this
# app" (rules.conf sets it to "urgent": flash the border, don't auto-focus).
#
# Viber pings urgent on every incoming message; auto-teleporting to it each
# time would be constantly disruptive, so it's excluded here. It still gets
# the normal urgent-border flash, and its own popup toast is separately
# killed in favor of the shell's notification (see rules.conf) — this script only concerns
# the "jump to it" behavior.

is_excepted() {
  case "$1" in
    viber) return 0 ;;
    *) return 1 ;;
  esac
}

# one instance (exec_always re-runs this on every reload); if the IPC
# subscription ever drops, subscribe again instead of silently dying
exec 9> "${XDG_RUNTIME_DIR:-/tmp}/activation-watch.lock"
flock -n 9 || exit 0

while :; do
swaymsg -t subscribe -m '["window"]' 9>&- | python3 -u -c '
import sys, json
for line in sys.stdin:
    try:
        e = json.loads(line)
    except ValueError:
        continue
    if e.get("change") != "urgent":
        continue
    c = e.get("container", {})
    if not c.get("urgent"):
        continue
    print(str(c.get("id")) + "\t" + (c.get("app_id") or ""), flush=True)
' | while IFS="$(printf '\t')" read -r id app_id; do
  [ -z "$id" ] && continue
  is_excepted "$app_id" && continue
  swaymsg "[con_id=$id] focus" >/dev/null
done
sleep 1
done
