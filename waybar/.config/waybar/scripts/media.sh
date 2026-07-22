#!/bin/sh
# Waybar media modules driven by playerctl --follow (live updates, no polling).
#   cava       → block-char visualizer (waybar's native cava produces nothing)
#   playpause  → JSON: play/pause icon reflecting player status
#   info       → JSON: "Title\n<small>Artist</small>" (pango, escaped)

# waybar orphans an exec's pipeline children on reload/restart; kill our own
# children (cava/playerctl/python) when we're told to stop so nothing leaks
trap 'pkill -P $$ 2>/dev/null' EXIT INT TERM

emit_pp() {
  case "$1" in
    Playing) printf '{"text":"󰏤","alt":"playing"}\n' ;;
    Paused)  printf '{"text":"󰐊","alt":"paused"}\n' ;;
    *)       printf '{"text":"󰐊","alt":"stopped"}\n' ;;
  esac
}

case "$1" in
  cava)
    # waybar's native cava module produces nothing here (not built with cava
    # support), so run cava in raw-ascii mode and map levels 0-7 to block chars
    cfg=$(mktemp)
    printf '[general]\nframerate=30\nbars=10\nsensitivity=120\n[output]\nmethod=raw\nraw_target=/dev/stdout\ndata_format=ascii\nascii_max_range=7\n[input]\nmethod=pulse\nsource=auto\n' > "$cfg"
    cava -p "$cfg" | python3 -u -c '
import sys
bars = "▁▂▃▄▅▆▇█"
for line in sys.stdin:
    vals = [v for v in line.strip().strip(";").split(";") if v != ""]
    print("".join(bars[min(int(v), 7)] for v in vals), flush=True)
'
    rm -f "$cfg"
    ;;
  playpause)
    emit_pp "$(playerctl status 2>/dev/null)"
    playerctl --follow --format '{{status}}' status 2>/dev/null |
      while IFS= read -r s; do emit_pp "$s"; done
    ;;
  info)
    # print an initial value, then stream changes
    { playerctl metadata --format '{{title}}||{{artist}}' 2>/dev/null
      playerctl --follow --format '{{title}}||{{artist}}' metadata 2>/dev/null; } |
      python3 -u -c '
import sys, json, html
for line in sys.stdin:
    title, _, artist = line.rstrip("\n").partition("||")
    if not title:
        print(json.dumps({"text": ""}), flush=True); continue
    t, a = html.escape(title), html.escape(artist)
    text = f"{t}\n<small>{a}</small>" if artist else t
    tip = f"{title} — {artist}" if artist else title
    print(json.dumps({"text": text, "tooltip": tip}), flush=True)
'
    ;;
esac
