#!/bin/sh
# ── armojidots theme engine ─────────────────────────
# One accent color drives the shell, terminals, sway borders, notifications,
# the lock screen and GTK apps.
#   theme.sh apply <palette>   palettes: wallpaper (extracted from current
#                              wallpaper), ruby, orange, dandelion, emerald,
#                              cobalt, bubblegum, purpur, b&w
#   theme.sh startup           re-apply saved palette + style (for autostart)
#   theme.sh style <pack>      switch style pack (shape/spacing/fonts) from
#                              ~/.config/armoji-styles/<pack>/ — independent of
#                              the palette; a pack.conf may restrict palettes
#   theme.sh font <ui|mono|display> <family|default>
#                              font override (a style switch resets them)
#   theme.sh cursor <theme> [size]   cursor theme everywhere
#   theme.sh icons <theme>     GTK icon theme
#   theme.sh folders <auto|#hex>     Slot folder color (auto = the accent)
#   theme.sh scan-themes       link ~/Themes/{Fonts,Cursors,Icons} into the
#                              places apps look (run by Spotlight's tabs)

STATE_DIR="$HOME/.local/state/armojidots"
WALL="$HOME/dotfiles/wallpapers/current"
STYLES_DIR="$HOME/.config/armoji-styles"
mkdir -p "$STATE_DIR"

PALETTES="wallpaper
ruby
orange
dandelion
emerald
cobalt
bubblegum
purpur
b&w"

extract_from_wallpaper() {
  python3 - "$WALL" <<'PYEOF'
import sys, colorsys
from PIL import Image

try:
    img = Image.open(sys.argv[1]).convert("RGB").resize((64, 64))
    colors = img.getcolors(64 * 64)
except Exception:          # no wallpaper set (live wallpaper / fresh install)
    colors = []
best, best_score = None, 0
for count, (r, g, b) in colors:
    h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
    score = count * (s ** 1.5) * v
    if v > 0.25 and score > best_score:
        best, best_score = (r, g, b), score
if best is None:
    best = (120, 140, 200)

h, s, v = colorsys.rgb_to_hsv(*[c / 255 for c in best])
s = min(1.0, s * 1.2 + 0.1)          # keep accents punchy and readable
v = min(1.0, max(v, 0.75))
# HSV value isn't perceived brightness (pure blue at v=1 is still dark):
# brighten, then desaturate, until the accent reads on the dark surfaces
def lum(rgb):
    lin = [c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4 for c in rgb]
    return 0.2126 * lin[0] + 0.7152 * lin[1] + 0.0722 * lin[2]
while lum(colorsys.hsv_to_rgb(h, s, v)) < 0.2 and (v < 1 or s > 0.35):
    if v < 1: v = min(1.0, v + 0.05)
    else: s -= 0.05
acc = colorsys.hsv_to_rgb(h, s, v)
dim = colorsys.hsv_to_rgb(h, s, v * 0.68)
print("#%02x%02x%02x" % tuple(int(c * 255) for c in acc),
      "#%02x%02x%02x" % tuple(int(c * 255) for c in dim))
PYEOF
}

derive_family() {
  # from one seed color, derive a full palette family:
  # ACC DIM BG BG2 FG MUTED (bg/fg/muted are hue-tinted toward the seed)
  python3 - "$1" "$2" <<'PYEOF'
import sys, colorsys

def hx(rgb): return "#%02x%02x%02x" % tuple(int(c * 255) for c in rgb)
r, g, b = (int(sys.argv[1][i:i+2], 16) / 255 for i in (1, 3, 5))
h, s, v = colorsys.rgb_to_hsv(r, g, b)

# tone: how heavy the palette sits on everything
tone = sys.argv[2] if len(sys.argv) > 2 else "heavy"
T = {
    "light": dict(bg_s=0.35, bg_v=0.11, bg2_s=0.28, bg2_v=0.22, fg_s=0.06, mut_s=0.18, ansi=0.75),
    "heavy": dict(bg_s=0.80, bg_v=0.13, bg2_s=0.65, bg2_v=0.25, fg_s=0.18, mut_s=0.40, ansi=1.00),
    "loud":  dict(bg_s=1.00, bg_v=0.17, bg2_s=0.90, bg2_v=0.30, fg_s=0.30, mut_s=0.55, ansi=1.15),
}.get(tone, None) or {
    "bg_s": 0.80, "bg_v": 0.13, "bg2_s": 0.65, "bg2_v": 0.25,
    "fg_s": 0.18, "mut_s": 0.40, "ansi": 1.00}

acc   = colorsys.hsv_to_rgb(h, s, v)
dim   = colorsys.hsv_to_rgb(h, s, v * 0.68)
bg    = colorsys.hsv_to_rgb(h, min(1.0, s * T["bg_s"]), T["bg_v"])
bg2   = colorsys.hsv_to_rgb(h, min(1.0, s * T["bg2_s"]), T["bg2_v"])
fg    = colorsys.hsv_to_rgb(h, min(1.0, s * T["fg_s"]), 0.94)
muted = colorsys.hsv_to_rgb(h, min(1.0, s * T["mut_s"]), 0.62)

# terminal ANSI family: 6 hue-shifted regulars + brights around the accent
spec = [(-0.09, 1.00, 0.80), (0.00, 1.00, 0.88), (0.05, 0.90, 0.85),
        (-0.04, 0.75, 0.90), (0.09, 0.95, 0.82), (-0.13, 0.90, 0.86)]
regs, brights = [], []
for dh, ds, dv in spec:
    regs.append(colorsys.hsv_to_rgb((h + dh) % 1.0, min(1.0, s * ds * T["ansi"]), dv))
    brights.append(colorsys.hsv_to_rgb((h + dh) % 1.0, min(1.0, s * ds * T["ansi"] * 0.9), min(1.0, dv + 0.12)))
out = [acc, dim, bg, bg2, fg, muted] + regs + brights
print(" ".join(hx(c) for c in out))
PYEOF
}

resolve() {
  case "$1" in
    ruby)      seed="#e35d6a" ;;
    orange)    seed="#f28744" ;;
    dandelion) seed="#f2c94c" ;;
    emerald)   seed="#3ecf82" ;;
    cobalt)    seed="#5480f2" ;;
    bubblegum) seed="#f06ec3" ;;
    purpur)    seed="#a06ef0" ;;
    bw|"b&w")  seed="#e8eaef" ;;
    red)       seed="#D71921" ;;   # nothingos RGBY signal accents
    green)     seed="#4A9E5C" ;;
    blue)      seed="#5B9BF6" ;;
    yellow)    seed="#D4A843" ;;
    wallpaper) seed=$(extract_from_wallpaper | cut -d' ' -f1) ;;
    \#[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]) seed="$1" ;;  # custom (spotlight color picker)
    *) return 1 ;;
  esac
  TONE=$(cat "$STATE_DIR/tone" 2>/dev/null || echo heavy)
  set -- $(derive_family "$seed" "$TONE")
  ACC="$1" DIM="$2" BG="$3" BG2="$4" FG="$5" MUTED="$6"
  R1="$7" R2="$8" R3="$9"
  shift 9
  R4="$1" R5="$2" R6="$3" B1="$4" B2="$5" B3="$6" B4="$7" B5="$8" B6="$9"
  ALPHA_BAR=0.55 ALPHA_POP=0.58 ALPHA_TERM=0.88 ALPHA_APP=1
  if [ "$(pack_flag "$(current_style)" neutral)" = 1 ]; then
    # monochrome surfaces + exact accent. Terminal: greys + the accent in the
    # "green" slot (prompt / fastfetch / success), fixed red for errors and
    # yellow for warnings; everything else grey.
    ACC="$seed"
    BG="#121212" BG2="#1C1C1C" FG="#D4D4D4" MUTED="#8C8C8C"
    R1="#D71921" R2="$ACC" R3="#D4A843" R4="#A8A8A8" R5="#7D7D7D" R6="#C4C4C4"
    B1="#F0464D" B2="$ACC" B3="#E8C468" B4="#C8C8C8" B5="#9C9C9C" B6="#E0E0E0"
    ALPHA_BAR=1 ALPHA_POP=1 ALPHA_TERM=1
    # lucent packs: same greys, but frosted glass (translucent over the blur)
    # everywhere — shell, notifications, terminals and GTK app windows
    if [ "$(pack_flag "$(current_style)" lucent)" = 1 ]; then
      ALPHA_BAR=0.5 ALPHA_POP=0.55 ALPHA_TERM=0.75 ALPHA_APP=0.78
    fi
  fi
  # per-pack surface alphas (pack.conf alpha_bar/pop/cc/term/app) win over
  # the above — how tinted packs get frosted glass
  for _k in bar pop cc term app; do
    _v=$(pack_flag "$(current_style)" "alpha_$_k")
    # (an if, not `&&`: a false test would end resolve() with status 1)
    if [ -n "$_v" ]; then eval "ALPHA_$(printf %s "$_k" | tr a-z A-Z)=\$_v"; fi
  done
  # user opacity (spotlight colors page slider) replaces every surface alpha;
  # no state file = the pack's own alphas
  _op=$(cat "$STATE_DIR/opacity" 2>/dev/null)
  if [ -n "$_op" ]; then ALPHA_BAR=$_op ALPHA_POP=$_op ALPHA_TERM=$_op ALPHA_APP=$_op; fi
}

# ── style packs ──────────────────────────────────────
# A pack is a dir of per-app structural CSS (no colors). Each app's style.css
# ends with `@import "style-tokens.css"`, so copying the pack file there is
# the whole switch.
current_style() { cat "$STATE_DIR/style" 2>/dev/null || echo material; }

list_styles() {
  for d in "$STYLES_DIR"/*/; do [ -d "$d" ] && basename "$d"; done
}

# palettes a pack allows (empty = all). pack.conf: allowed_palettes="ruby cobalt"
allowed_palettes() {
  allowed_palettes=""
  [ -f "$STYLES_DIR/$1/pack.conf" ] && . "$STYLES_DIR/$1/pack.conf"
  printf '%s' "$allowed_palettes"
}

pack_flag() {  # pack_flag <pack> <name> -> value from pack.conf ("" if unset)
  eval "$2=''"
  [ -f "$STYLES_DIR/$1/pack.conf" ] && . "$STYLES_DIR/$1/pack.conf"
  eval "printf '%s' \"\$$2\""
}

palette_allowed() {  # palette_allowed <pack> <palette>
  list=$(allowed_palettes "$1")
  [ -z "$list" ] && return 0
  for p in $list; do [ "$p" = "$2" ] && return 0; done
  return 1
}

copy_style() {
  pack="$1"
  [ -d "$STYLES_DIR/$pack" ] || { notify-send "theme" "unknown style: $pack"; return 1; }
  if [ -f "$STYLES_DIR/$pack/kitty.conf" ]; then
    mkdir -p "$HOME/.config/kitty"
    { echo "# generated by theme.sh — style: $pack"; cat "$STYLES_DIR/$pack/kitty.conf"; } \
      > "$HOME/.config/kitty/style.conf"
  fi
  if [ -f "$STYLES_DIR/$pack/shell.json" ]; then
    mkdir -p "$HOME/.config/armoji-shell"
    cp "$STYLES_DIR/$pack/shell.json" "$HOME/.config/armoji-shell/style.json"
  fi
  if [ -f "$STYLES_DIR/$pack/sway.conf" ]; then
    { echo "# generated by theme.sh — style: $pack"; cat "$STYLES_DIR/$pack/sway.conf"; } \
      > "$HOME/.config/sway/style-effects.conf"
  fi
  printf '%s\n' "$pack" > "$STATE_DIR/style"
  apply_fonts
}

# ── user overrides: fonts / cursor / icons / folder color ──
# fonts file: ui=… mono=… display=… (missing = the style pack's own)
font_of() { sed -n "s/^$1=//p" "$STATE_DIR/fonts" 2>/dev/null | head -n1; }
ui_font()   { f=$(font_of ui);   [ -n "$f" ] && echo "$f" || pack_flag "$(current_style)" ui_font; }
mono_font() { f=$(font_of mono); [ -n "$f" ] && echo "$f" || pack_flag "$(current_style)" mono_font; }

# the pack's files were just copied fresh; patch the overrides into them
apply_fonts() {
  ui=$(font_of ui) mono=$(font_of mono) disp=$(font_of display)
  [ -n "$ui$mono$disp" ] || return 0
  python3 - "$HOME/.config/armoji-shell/style.json" "$ui" "$mono" "$disp" <<'PYF'
import sys, json
path, ui, mono, disp = sys.argv[1:]
try: d = json.load(open(path))
except Exception: sys.exit()
for keys, f in ((("font", "spTitleFont", "spSubFont", "spEntryFont", "spLabelFont", "mediaFont", "osdPctFont"), ui),
                (("termFont",), mono), (("clockFont", "numFont"), disp)):
    if f:
        for k in keys: d[k] = f
json.dump(d, open(path, "w"), indent=2)
PYF
  if [ -n "$mono" ]; then
    [ -f "$HOME/.config/kitty/style.conf" ] && sed -i "s/^font_family .*/font_family $mono/" "$HOME/.config/kitty/style.conf"
  fi
}

# app fonts (gsettings): override, else the pack's ui_font/mono_font, else Adwaita
gtk_fonts() {
  _uf=$(ui_font); _mf=$(mono_font)
  gsettings set org.gnome.desktop.interface font-name "${_uf:-Adwaita Sans} 11" 2>/dev/null
  gsettings set org.gnome.desktop.interface monospace-font-name "${_mf:-Adwaita Mono} 11" 2>/dev/null
}

# cursor file: "<theme> <size>"; written to sway, environment.d and gsettings
apply_cursor() {
  set -- $(cat "$STATE_DIR/cursor" 2>/dev/null)
  t=${1:-Bibata-Modern-Classic} sz=${2:-24}
  printf '# generated by theme.sh\nseat seat0 xcursor_theme %s %s\n' "$t" "$sz" > "$HOME/.config/sway/cursor.conf"
  # sorts after the tracked default cursor.conf, so it wins
  mkdir -p "$HOME/.config/environment.d"
  printf '# generated by theme.sh\nXCURSOR_THEME=%s\nXCURSOR_SIZE=%s\n' "$t" "$sz" > "$HOME/.config/environment.d/user-cursor.conf"
  swaymsg -q "seat seat0 xcursor_theme $t $sz" 2>/dev/null
  gsettings set org.gnome.desktop.interface cursor-theme "$t" 2>/dev/null
  gsettings set org.gnome.desktop.interface cursor-size "$sz" 2>/dev/null
}

icon_theme() { cat "$STATE_DIR/icons" 2>/dev/null || echo Slot-Multicolor-Dark-Icons; }
# flip through a dummy value so apps that only react to a change refresh
apply_icons() {
  gsettings set org.gnome.desktop.interface icon-theme 'Adwaita' 2>/dev/null
  gsettings set org.gnome.desktop.interface icon-theme "$(icon_theme)" 2>/dev/null
}

# ~/Themes/{Fonts,Cursors,Icons}: user drop-in folders, linked where apps look
scan_themes() {
  T="$HOME/Themes" I="$HOME/.local/share/icons"
  mkdir -p "$T/Fonts" "$T/Cursors" "$T/Icons" "$I" "$HOME/.local/share/fonts"
  [ -e "$HOME/.local/share/fonts/Themes" ] || ln -s "$T/Fonts" "$HOME/.local/share/fonts/Themes"
  for d in "$T"/Cursors/*/ "$T"/Icons/*/; do
    [ -d "$d" ] || continue
    n=$(basename "$d")
    [ -e "$I/$n" ] || ln -s "${d%/}" "$I/$n"
  done
  # links to themes since removed from ~/Themes
  for l in "$I"/*; do
    [ -L "$l" ] && [ ! -e "$l" ] && case "$(readlink "$l")" in "$T"/*) rm -f "$l" ;; esac
  done

}

apply_style() {
  pack="$1"
  rm -f "$STATE_DIR/fonts"     # a new style brings its own fonts
  copy_style "$pack" || exit 1
  pal=$(cat "$STATE_DIR/theme" 2>/dev/null || echo wallpaper)
  if ! palette_allowed "$pack" "$pal"; then
    pal=$(allowed_palettes "$pack" | cut -d' ' -f1)
    notify-send "theme" "style $pack limits palettes — using $pal"
  fi
  # colors depend on the pack too (neutral mode), so always regenerate + reload
  apply "$pal"
  notify-send -t 3000 "󰏘 Style" "$pack"
}

# folder color: the accent, unless set (theme.sh folders #hex)
# ── login screen: SilentSDDM (if installed and set up by `theme.sh sddm-setup`)
# gets an armoji.conf in the palette + style font, and the current wallpaper.
# Both files are made user-owned once, so this runs without sudo; anywhere
# else (no SilentSDDM, or not set up) it does nothing.
SDDM_THEME=/usr/share/sddm/themes/silent
SDDM_FONTS=/usr/local/share/fonts/armojidots
sddm_theme() {
  [ -w "$SDDM_THEME/configs/armoji.conf" ] && [ -w "$SDDM_THEME/backgrounds/armoji.jpg" ] || return 0
  base="$SDDM_THEME/configs/default.conf.bak"; [ -f "$base" ] || base="$SDDM_THEME/configs/default.conf"
  # the style's clock font (the display role), visible to the greeter: copied
  # into the system font dir that sddm-setup made ours (fonts in ~ are private)
  clock=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("clockFont",""))' "$HOME/.config/armoji-shell/style.json" 2>/dev/null)
  if [ -n "$clock" ] && [ -w "$SDDM_FONTS" ]; then
    f=$(fc-match -f '%{file}' "$clock")
    case "$f" in "$HOME"/*) cp -u "$f" "$SDDM_FONTS/" ;; esac
  fi
  python3 - "$base" "$SDDM_THEME/configs/armoji.conf" "$ACC" "$FG" "$BG" "$(ui_font)" "$clock" <<'PYEOF'
import re, sys
base, out, acc, fg, bg, font, clock = sys.argv[1:]
# "Geist Medium" -> family "Geist" (weights are set per item by the theme)
strip = lambda f: re.sub(r"\s+(Thin|ExtraLight|Light|Regular|Medium|SemiBold|Bold|ExtraBold|Black)$", "", f)
family = strip(font) or "Inter"
clockfam = strip(clock) or family
want = {   # [section] key -> value; everything else keeps the stock look
    ("LockScreen", "background"): '"armoji.jpg"', ("LoginScreen", "background"): '"armoji.jpg"',
    ("LockScreen", "background-color"): f'"{bg}"', ("LoginScreen", "background-color"): f'"{bg}"',
    ("LockScreen", "blur"): "32", ("LockScreen", "brightness"): "-0.2",
    ("LoginScreen", "blur"): "24", ("LoginScreen", "brightness"): "-0.3",
    ("LockScreen.Clock", "color"): f'"{acc}"',
    ("LockScreen.Clock", "font-family"): f'"{clockfam}"',
    # dot-matrix numerals stay crisp at regular weight; text faces get the stock 900
    ("LockScreen.Clock", "font-weight"): "400" if clockfam != family else "900",
    ("LoginScreen.LoginArea.Avatar", "active-border-size"): "2",
    ("LoginScreen.LoginArea.Avatar", "active-border-color"): f'"{acc}"',
    ("LoginScreen.LoginArea.LoginButton", "background-color"): f'"{acc}"',
    ("LoginScreen.LoginArea.LoginButton", "background-opacity"): "0.45",
    ("LoginScreen.LoginArea.LoginButton", "active-background-color"): f'"{acc}"',
    ("LoginScreen.LoginArea.LoginButton", "active-background-opacity"): "0.85",
    ("LoginScreen.MenuArea.Popups", "active-option-background-color"): f'"{acc}"',
    ("LoginScreen.MenuArea.Popups", "active-option-background-opacity"): "0.5",
}
sec, lines = "", []
for line in open(base):
    m = re.match(r"\[(.+)\]", line.strip())
    if m: sec = m.group(1)
    k = line.split("=", 1)[0].strip() if "=" in line and not line.lstrip().startswith(";") else None
    if k and (sec, k) in want: line = f"{k} = {want[(sec, k)]}\n"
    elif k == "font-family": line = f'font-family = "{family}"\n'
    elif k and re.search(r'"#F{6}"|"#FFF"', line, re.I) and "color" in k: line = re.sub(r'"#F{3,6}"', f'"{fg}"', line, flags=re.I)
    lines.append(line)
open(out, "w").write("; generated by armojidots theme.sh — edit the palette, not this file\n" + "".join(lines))
PYEOF
  # wallpaper (or none: the theme's bg color); a small jpeg loads fast at boot
  if [ -e "$WALL" ]; then
    python3 -c 'import sys; from PIL import Image
im = Image.open(sys.argv[1]).convert("RGB"); im.thumbnail((2560, 2560)); im.save(sys.argv[2], "JPEG", quality=88)' \
      "$WALL" "$SDDM_THEME/backgrounds/armoji.jpg" 2>/dev/null
  else
    sed -i 's/^use-background-color = .*/use-background-color = true/' "$SDDM_THEME/configs/armoji.conf"
  fi
}

recolor_folders() {
  FOLDER=$(cat "$STATE_DIR/folders" 2>/dev/null)
  case "$FOLDER" in \#??????) ;; *) FOLDER=$ACC ;; esac
  # ── Slot-Multicolor-Dark-Icons: selective folder recolor ──
  # Only the "default" XDG folders (Documents, Downloads, Music, Pictures,
  # Videos, Desktop, Public, Templates, home/root, and the bare "folder"
  # icon) get tinted to the accent — every folder with its own branded icon
  # (git, docker, steam, blender, …) keeps the pack's original artwork, so
  # those stay visually distinct on purpose.
  #
  # This is hand-rolled (not papirus-folders): that tool hardcodes a
  # "<size>x<size>/places" layout, but this pack uses "places/<size>" —
  # a different (still spec-valid) convention it can't find files under.
  SLOT_DIR="$HOME/.local/share/icons/Slot-Multicolor-Dark-Icons"
  # The pack's own "red" folder is a pink-crimson (#d35f8d/#a02c5a), so
  # instead of picking the nearest of its 11 colors we regenerate the folder
  # in the exact accent: every folder-colored fill (pink/red hue band) is
  # remapped to the accent hue, keeping the icon's own light/dark shading
  # (its lightest folder color becomes the accent itself).
  if [ -d "$SLOT_DIR" ]; then
    python3 - "$FOLDER" "$SLOT_DIR" <<'PYEOF2'
import sys, re, colorsys, glob, os
acc, slot = sys.argv[1], sys.argv[2]
rgb = lambda h: tuple(int(h[i:i + 2], 16) / 255 for i in (1, 3, 5))
hexs = lambda t: "#%02x%02x%02x" % tuple(max(0, min(255, round(c * 255))) for c in t)
ah, al, as_ = colorsys.rgb_to_hls(*rgb(acc))
pat = re.compile(r"#[0-9a-fA-F]{6}\b")

def folder_col(c):
    h, l, s = colorsys.rgb_to_hls(*rgb(c))
    return s > 0.3 and 0.15 < l < 0.85 and (h >= 320 / 360 or h <= 20 / 360)

for d in glob.glob(slot + "/places/*/"):
    base = d + "folder-red.svg"
    if not os.path.isfile(base):
        continue
    svg = open(base).read()
    cols = {c.lower() for c in pat.findall(svg) if folder_col(c)}
    if not cols:
        continue
    ref = max(cols, key=lambda c: colorsys.rgb_to_hls(*rgb(c))[1])
    rh, rl, rs = colorsys.rgb_to_hls(*rgb(ref))
    m = {}
    for c in cols:
        h, l, s = colorsys.rgb_to_hls(*rgb(c))
        m[c] = hexs(colorsys.hls_to_rgb(ah, min(1.0, al * l / rl), min(1.0, as_ * s / rs)))
    open(d + "folder-accent.svg", "w").write(
        pat.sub(lambda mo: m.get(mo.group(0).lower(), mo.group(0)), svg))
PYEOF2
    # Documents/Downloads/Music/Pictures/Videos/Templates/Public/Desktop/
    # Home/Root all ship their OWN distinct built-in art in this pack (same
    # idea as git/docker/steam) — only the bare "folder" (used for any
    # custom-named folder with no special icon) gets the accent.
    for size_dir in "$SLOT_DIR"/places/*/; do
      [ -f "${size_dir}folder-accent.svg" ] || continue
      for fname in folder folder-open; do
        dest="${size_dir}${fname}.svg"
        # only relink names the pack actually ships at this size
        { [ -f "$dest" ] || [ -L "$dest" ]; } || continue
        ln -sf "folder-accent.svg" "$dest"
      done
    done
    gtk-update-icon-cache -qf "$SLOT_DIR" >/dev/null 2>&1
  fi
}

apply() {
  name="$1"
  palette_allowed "$(current_style)" "$name" || {
    notify-send "theme" "style $(current_style) doesn't allow palette: $name"; exit 1; }
  resolve "$name" || { notify-send "theme" "unknown palette: $name"; exit 1; }

  bg_r=$((0x${BG#\#} >> 16 & 255)); bg_g=$((0x${BG#\#} >> 8 & 255)); bg_b=$((0x${BG#\#} & 255))

  # ── quickshell shell (reloads itself when this file changes) ──
  mkdir -p "$HOME/.config/armoji-shell"
  printf '{"accent":"%s","accentDim":"%s","bg":"%s","bgAlpha":%s,"bgPopAlpha":%s,"termAlpha":%s,"fg":"%s","muted":"%s"}\n' \
    "$ACC" "$DIM" "$BG" "$ALPHA_BAR" "$ALPHA_POP" "$ALPHA_TERM" "$FG" "$MUTED" > "$HOME/.config/armoji-shell/colors.json"

  # ── shell sidebars (QMLTermWidget): Konsole-style scheme from the palette
  # (the same 16 colors as kitty), black background (made transparent by the
  # shell, glass shows through).
  # Symlinked once into /usr/lib/qt6/qml/QMLTermWidget/color-schemes/armoji.colorscheme
  python3 - "$HOME/.config/armoji-shell/terminal.colorscheme" "$FG" \
    "$BG2" "$R1" "$R2" "$R3" "$R4" "$R5" "$R6" "$FG" \
    "$MUTED" "$B1" "$B2" "$B3" "$B4" "$B5" "$B6" "#ffffff" <<'PYEOF'
import sys
out_path, fg, *pal = sys.argv[1:]          # pal: 8 regular + 8 bright
rgb = lambda h: ",".join(str(int(h.lstrip("#")[i:i + 2], 16)) for i in (0, 2, 4))
out = ["[General]", "Description=armoji", "Opacity=0", ""]
def sec(n, h): out.extend(["[%s]" % n, "Color=" + rgb(h), ""])
# pure black background: the shell's unblack shader turns it transparent
sec("Background", "#000000"); sec("BackgroundIntense", "#000000")
sec("Foreground", fg); sec("ForegroundIntense", pal[15])
for i in range(8):
    sec("Color%d" % i, pal[i]); sec("Color%dIntense" % i, pal[8 + i])
open(out_path, "w").write("\n".join(out))
PYEOF

  # ── live terminal colors: the sidebar terminals can't reload their scheme
  # until the shell restarts, so the prompt (starship re-reads its config every
  # prompt) and fish's syntax colors (universal vars, seen by every running
  # fish) carry the palette as exact hexes instead
  sed -e "/^\[palettes.armoji\]/,\$d" "$HOME/.config/starship.toml" > "$HOME/.config/armoji-shell/starship.toml"
  cat >> "$HOME/.config/armoji-shell/starship.toml" <<EOF
[palettes.armoji]
dir_bg = "$ACC"
git_bg = "$DIM"
pill_fg = "$BG"
git_fg = "$FG"
ok = "$R2"
err = "$R1"
dim = "$MUTED"
EOF
  # STARSHIP_CONFIG as an exported universal: running fish shells get it too
  fish -c "set -Ux STARSHIP_CONFIG $HOME/.config/armoji-shell/starship.toml
    set -U fish_color_command ${R4#\#}; set -U fish_color_keyword ${R5#\#}
    set -U fish_color_param ${R6#\#}; set -U fish_color_option ${R6#\#}
    set -U fish_color_quote ${R3#\#}; set -U fish_color_escape ${B6#\#}
    set -U fish_color_redirection ${R5#\#}; set -U fish_color_operator ${R5#\#}
    set -U fish_color_end ${R2#\#}; set -U fish_color_error ${R1#\#}
    set -U fish_color_comment ${MUTED#\#}; set -U fish_color_autosuggestion ${MUTED#\#}" 2>/dev/null

  # ── kitty (the terminal) ──
  mkdir -p "$HOME/.config/kitty"
  cat > "$HOME/.config/kitty/theme-colors.conf" <<EOF
# generated by theme.sh — palette: $name
# the pack's alpha_term, or the opacity slider (kitty applies it on SIGUSR1)
background_opacity $ALPHA_TERM
foreground $FG
background $BG
selection_foreground $BG
selection_background $ACC
cursor $ACC
url_color $ACC
color0  $BG2
color1  $R1
color2  $R2
color3  $R3
color4  $R4
color5  $R5
color6  $R6
color7  $FG
color8  $MUTED
color9  $B1
color10 $B2
color11 $B3
color12 $B4
color13 $B5
color14 $B6
color15 #ffffff
EOF

  # ── sway window borders ──
  cat > "$HOME/.config/sway/colors.conf" <<EOF
# generated by theme.sh — palette: $name
# class                 border  bg      text    indicator child_border
client.focused          $ACC $ACC #ffffff $ACC $ACC
client.focused_inactive $BG2 $BG $MUTED $BG2 $BG2
client.unfocused        $BG2 $BG $MUTED $BG2 $BG2
client.urgent           #e06c75 #e06c75 #ffffff #e06c75 #e06c75
EOF

  # ── GTK apps (adw-gtk3 + libadwaita accent overrides) ──
  # surfaces carry ALPHA_APP (1 = opaque; lucent packs: frosted glass)
  rgba() { h=${1#\#}; printf 'rgba(%d, %d, %d, %s)' "$((0x${h%????}))" "$((0x$(printf %s "$h" | cut -c3-4)))" "$((0x${h#????}))" "$ALPHA_APP"; }
  APP_BG=$(rgba "$BG") APP_BG2=$(rgba "$BG2")
  for gtkdir in gtk-3.0 gtk-4.0; do
    cat > "$HOME/.config/$gtkdir/gtk.css" <<EOF
/* generated by theme.sh — palette: $name */
@define-color accent_bg_color $ACC;
@define-color accent_fg_color #ffffff;
@define-color accent_color $ACC;
@define-color theme_selected_bg_color $ACC;
@define-color theme_selected_fg_color #ffffff;
/* adw-gtk3 keys list/sidebar selection + link highlights off success_color,
   which defaults to green — tie it to the accent so nothing stays green */
@define-color success_bg_color $ACC;
@define-color success_color $ACC;
@define-color success_fg_color #ffffff;
@define-color window_bg_color $APP_BG2;
/* GTK3's own background names, focused and unfocused (adw-gtk3 aliases
   them, but unfocused windows otherwise painted solid) */
@define-color theme_bg_color $APP_BG2;
@define-color theme_base_color $APP_BG;
@define-color theme_unfocused_bg_color $APP_BG2;
@define-color theme_unfocused_base_color $APP_BG;
@define-color window_fg_color $FG;
@define-color view_bg_color $APP_BG;
@define-color view_fg_color $FG;
@define-color headerbar_bg_color $APP_BG;
@define-color headerbar_backdrop_color $APP_BG;   /* unfocused: same glass */
@define-color headerbar_fg_color $FG;
@define-color sidebar_bg_color $APP_BG;
@define-color sidebar_backdrop_color $APP_BG;   /* unfocused: same glass */
@define-color sidebar_fg_color $FG;
@define-color secondary_sidebar_bg_color $APP_BG;
@define-color secondary_sidebar_backdrop_color $APP_BG;   /* unfocused: same glass */
@define-color secondary_sidebar_fg_color $FG;
@define-color card_bg_color $APP_BG2;
@define-color card_fg_color $FG;
@define-color dialog_bg_color $APP_BG2;
@define-color dialog_fg_color $FG;
@define-color popover_bg_color $APP_BG2;
@define-color popover_fg_color $FG;
/* bars that sit on the window's own background: no second fill (adw-gtk3
   paints them @window_bg_color when unfocused — two translucent layers
   read as solid) */
menubar, .menubar, menubar:backdrop, .menubar:backdrop,
.primary-toolbar, .primary-toolbar:backdrop, .toolbar, .toolbar:backdrop {
  background-color: transparent;
}
EOF
  done


  recolor_folders


  printf '%s\n' "$name" > "$STATE_DIR/theme"

  sddm_theme

  # ── Zen browser + the "Transparent Zen" mod: its custom background color
  # (pref mod.sameerasw.zen_transparency_color) = the theme bg at ALPHA_APP.
  # Zen owns prefs.js, so it goes in user.js, applied at Zen's next start.
  # Only profiles that have the mod installed are touched.
  _zen=$(printf '#%s%02x' "${BG#\#}" "$(awk -v a="$ALPHA_APP" 'BEGIN{printf "%d", a * 255 + 0.5}')")
  for _p in "$HOME"/.config/zen/*/prefs.js "$HOME"/.zen/*/prefs.js; do
    [ -f "$_p" ] && grep -q 'mod.sameerasw.zen_transparency_color' "$_p" || continue
    _u="${_p%/prefs.js}/user.js"
    { grep -v 'mod.sameerasw.zen_transparency_color' "$_u" 2>/dev/null
      printf 'user_pref("mod.sameerasw.zen_transparency_color", "%s");   // armojidots theme\n' "$_zen"; } > "$_u.new"
    mv "$_u.new" "$_u"
  done

  # ── reload the world ──
  swaymsg reload >/dev/null 2>&1
  # kitty re-reads its config (colors + style include) on SIGUSR1
  pkill -USR1 -x kitty 2>/dev/null
  # the sidebar terminals can't reload their color scheme until the shell
  # restarts, so push the new colors straight to every pty via OSC escapes
  # (the pywal trick)
  _seq=$(
    printf '\033]10;#%s\033\\' "${FG#\#}"
    printf '\033]11;#%s\033\\' "${BG#\#}"
    printf '\033]12;#%s\033\\' "${ACC#\#}"
    _i=0
    for _c in "$BG2" "$R1" "$R2" "$R3" "$R4" "$R5" "$R6" "$FG" \
              "$MUTED" "$B1" "$B2" "$B3" "$B4" "$B5" "$B6" ffffff; do
      printf '\033]4;%d;#%s\033\\' "$_i" "${_c#\#}"
      _i=$((_i + 1))
    done
  )
  for _pts in /dev/pts/[0-9]*; do
    [ -w "$_pts" ] && printf '%s' "$_seq" > "$_pts" 2>/dev/null
  done
  # theme flip-flop forces running GTK apps to re-read gtk.css; the sleep keeps
  # GTK from coalescing the two sets into a no-op when the end value is unchanged
  gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3' 2>/dev/null
  sleep 0.3
  gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' 2>/dev/null
  apply_icons
  gtk_fonts
  notify-send -t 3000 "󰏘 Theme" "palette: $name ($ACC)"
}

case "$1" in
  apply)   apply "$2" ;;
  startup)
    scan_themes
    apply_cursor
    copy_style "$(current_style)"
    apply "$(cat "$STATE_DIR/theme" 2>/dev/null || echo wallpaper)"
    ;;
  style) apply_style "$2" ;;
  tone)
    case "$2" in light|heavy|loud) ;; *) echo "tone: light|heavy|loud" >&2; exit 1 ;; esac
    printf '%s\n' "$2" > "$STATE_DIR/tone"
    apply "$(cat "$STATE_DIR/theme" 2>/dev/null || echo wallpaper)"
    ;;
  opacity)   # 0.3..1 sets every surface alpha; "default" = the pack's own
    if [ "$2" = default ]; then rm -f "$STATE_DIR/opacity"
    else
      awk -v o="$2" 'BEGIN{exit !(o>=0.3 && o<=1)}' || { echo "opacity: 0.3..1 | default" >&2; exit 1; }
      printf '%s\n' "$2" > "$STATE_DIR/opacity"
    fi
    apply "$(cat "$STATE_DIR/theme" 2>/dev/null || echo wallpaper)"
    ;;
  font)
    case "$2" in ui|mono|display) ;; *) echo "font: ui|mono|display <family|default>" >&2; exit 1 ;; esac
    { grep -v "^$2=" "$STATE_DIR/fonts" 2>/dev/null
      [ "$3" = default ] || [ -z "$3" ] || printf '%s=%s\n' "$2" "$3"; } > "$STATE_DIR/fonts.new"
    mv "$STATE_DIR/fonts.new" "$STATE_DIR/fonts"
    [ -s "$STATE_DIR/fonts" ] || rm -f "$STATE_DIR/fonts"
    copy_style "$(current_style)"
    gtk_fonts
    pkill -USR1 -x kitty 2>/dev/null
    ;;
  cursor) [ -n "$2" ] && printf '%s %s\n' "$2" "${3:-24}" > "$STATE_DIR/cursor"; apply_cursor ;;
  icons)  [ -n "$2" ] && printf '%s\n' "$2" > "$STATE_DIR/icons"; apply_icons ;;
  folders)
    case "$2" in auto) rm -f "$STATE_DIR/folders" ;; \#??????) printf '%s\n' "$2" > "$STATE_DIR/folders" ;;
      *) echo "folders: auto|#rrggbb" >&2; exit 1 ;; esac
    resolve "$(cat "$STATE_DIR/theme" 2>/dev/null || echo wallpaper)"   # → $ACC for auto
    recolor_folders
    apply_icons
    ;;
  scan-themes) scan_themes ;;
  sddm-setup)   # once, with sudo: let theme.sh keep the SilentSDDM login screen in sync
    [ -d "$SDDM_THEME" ] || { echo "SilentSDDM not installed ($SDDM_THEME)" >&2; exit 1; }
    sudo sh -c 'touch "$1/configs/armoji.conf" "$1/backgrounds/armoji.jpg" && chown "$2" "$1/configs/armoji.conf" "$1/backgrounds/armoji.jpg" &&
      mkdir -p "$3" && chown "$2" "$3" &&
      { [ -f "$1/metadata.desktop.bak" ] || cp "$1/metadata.desktop" "$1/metadata.desktop.bak"; } &&
      sed -i "s|^ConfigFile=.*|ConfigFile=configs/armoji.conf|" "$1/metadata.desktop"' sh "$SDDM_THEME" "$(id -un)" "$SDDM_FONTS"
    apply "$(cat "$STATE_DIR/theme" 2>/dev/null || echo wallpaper)"
    ;;
  *) echo "usage: theme.sh apply <palette> | tone <light|heavy|loud> | opacity <0.3..1|default> | style <pack> | font <role> <family|default> | cursor <theme> [size] | icons <theme> | folders <auto|#hex> | scan-themes | sddm-setup | startup" >&2; exit 1 ;;
esac
