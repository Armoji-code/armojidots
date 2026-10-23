#!/bin/sh
# Keyboard layout module: layouts set via input.conf / keyboard.conf +
# xkb_options "grp:alt_shift_toggle" (native Shift+Alt chord, most reliable
# way to catch that combo — sway bindsym doesn't handle bare modifier chords
# well). This script just reacts to the resulting sway IPC event:
#   watch  → the bar's persistent exec: streams JSON text + fires a
#            notify-send toast on every layout change, from any trigger
#            (Shift+Alt, or the bar button below)
#   toggle → bar on-click: switches layout, which fires the same IPC
#            event watch() reacts to (single source of truth for the toast)

case "$1" in
  toggle)
    swaymsg input type:keyboard xkb_switch_layout next >/dev/null
    ;;
  watch|"")
    # one python process does it all, exec'd so its parent is the shell (qs):
    # it polls that parent and exits (taking swaymsg with it) when qs goes
    # away — shell restarts used to leave a whole pipeline behind each time
    exec python3 -u - "$(command -v notify-send)" <<'PYEOF'
import ctypes, json, os, select, signal, subprocess, sys

# the shell stops us with SIGTERM: run the cleanup below instead of dying
signal.signal(signal.SIGTERM, lambda *_: sys.exit(0))
def die_with_us():   # swaymsg gets SIGTERM if we vanish anyway (prctl PDEATHSIG)
    ctypes.CDLL(None).prctl(1, signal.SIGTERM)

def label(name):
    if "US" in name or "us" in name: return "EN"
    if "Lithuania" in name or "lt" in name.lower(): return "LT"
    return name[:2].upper()

def emit(name):
    print(json.dumps({"text": "\U000f030c " + label(name), "tooltip": name}), flush=True)

# sway reports several "keyboard" devices (the real one plus virtual
# power/sleep/video-bus buttons) sharing one xkb config: follow the first
inputs = json.loads(subprocess.run(["swaymsg", "-t", "get_inputs"], capture_output=True, text=True).stdout or "[]")
kb = next((i for i in inputs if i.get("type") == "keyboard" and "xkb_active_layout_name" in i), None)
if kb is None: sys.exit(0)
target = kb["identifier"]
emit(kb.get("xkb_active_layout_name", ""))

parent = os.getppid()
sub = subprocess.Popen(["swaymsg", "-t", "subscribe", "-m", '["input"]'], stdout=subprocess.PIPE, text=True,
                       preexec_fn=die_with_us)
try:
    while True:
        r, _, _ = select.select([sub.stdout], [], [], 5)
        if os.getppid() != parent: break          # the shell is gone
        if not r: continue
        line = sub.stdout.readline()
        if not line: break                        # sway is gone
        try: e = json.loads(line)
        except ValueError: continue
        i = e.get("input", {})
        if e.get("change") != "xkb_layout" or i.get("identifier") != target: continue
        name = i.get("xkb_active_layout_name", "")
        if not name: continue
        emit(name)
        subprocess.Popen([sys.argv[1], "-t", "1500", "-h", "string:x-canonical-private-synchronous:lang",
                          "\U000f030c Keyboard layout", "Switched to " + name])
except BrokenPipeError:
    pass
finally:
    sub.kill()
PYEOF
    ;;
esac
