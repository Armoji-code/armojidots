#!/bin/sh
# ── armojidots theme engine ─────────────────────────
# One accent color drives waybar, foot, sway borders, and walker.
#   theme.sh apply <palette>   palettes: wallpaper (extracted from current
#                              wallpaper), ruby, orange, dandelion, emerald,
#                              cobalt, bubblegum, purpur, b&w
#   theme.sh pick              walker picker (used by /set color)
#   theme.sh startup           re-apply saved palette + style (for autostart)
#   theme.sh style <pack>      switch style pack (shape/spacing/fonts) from
#                              ~/.config/armoji-styles/<pack>/ — independent of
#                              the palette; a pack.conf may restrict palettes
#   theme.sh style-pick        walker picker for style packs

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

img = Image.open(sys.argv[1]).convert("RGB").resize((64, 64))
best, best_score = None, 0
for count, (r, g, b) in img.getcolors(64 * 64):
    h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
    score = count * (s ** 1.5) * v
    if v > 0.25 and score > best_score:
        best, best_score = (r, g, b), score
if best is None:
    best = (120, 140, 200)

h, s, v = colorsys.rgb_to_hsv(*[c / 255 for c in best])
s = min(1.0, s * 1.2 + 0.1)          # keep accents punchy and readable
v = min(1.0, max(v, 0.75))
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
    *) return 1 ;;
  esac
  TONE=$(cat "$STATE_DIR/tone" 2>/dev/null || echo heavy)
  set -- $(derive_family "$seed" "$TONE")
  ACC="$1" DIM="$2" BG="$3" BG2="$4" FG="$5" MUTED="$6"
  R1="$7" R2="$8" R3="$9"
  shift 9
  R4="$1" R5="$2" R6="$3" B1="$4" B2="$5" B3="$6" B4="$7" B5="$8" B6="$9"
  ALPHA_BAR=0.55 ALPHA_POP=0.58 ALPHA_CC=0.72 ALPHA_TERM=0.88
  if [ "$(pack_flag "$(current_style)" neutral)" = 1 ]; then
    # monochrome surfaces + exact accent. Terminal: greys + the accent in the
    # "green" slot (prompt / fastfetch / success), fixed red for errors and
    # yellow for warnings; everything else grey.
    ACC="$seed"
    BG="#121212" BG2="#1C1C1C" FG="#D4D4D4" MUTED="#8C8C8C"
    R1="#D71921" R2="$ACC" R3="#D4A843" R4="#A8A8A8" R5="#7D7D7D" R6="#C4C4C4"
    B1="#F0464D" B2="$ACC" B3="#E8C468" B4="#C8C8C8" B5="#9C9C9C" B6="#E0E0E0"
    ALPHA_BAR=1 ALPHA_POP=1 ALPHA_CC=1 ALPHA_TERM=1
  fi
}

# ── style packs ──────────────────────────────────────
# A pack is a dir of per-app structural CSS (no colors). Each app's style.css
# ends with `@import "style-tokens.css"`, so copying the pack file there is
# the whole switch.
current_style() { cat "$STATE_DIR/style" 2>/dev/null || echo default; }

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
  for pair in waybar:waybar dock:armoji-dock osd:armoji-osd \
              spotlight:armoji-spotlight swaync:swaync walker:walker/themes/armoji; do
    src="$STYLES_DIR/$pack/${pair%%:*}.css"
    dst="$HOME/.config/${pair#*:}"
    [ -f "$src" ] || continue
    mkdir -p "$dst"
    { echo "/* generated by theme.sh — style: $pack */"; cat "$src"; } > "$dst/style-tokens.css"
  done
  if [ -f "$STYLES_DIR/$pack/kitty.conf" ]; then
    mkdir -p "$HOME/.config/kitty"
    { echo "# generated by theme.sh — style: $pack"; cat "$STYLES_DIR/$pack/kitty.conf"; } \
      > "$HOME/.config/kitty/style.conf"
  fi
  if [ -f "$STYLES_DIR/$pack/foot.ini" ]; then
    { echo "# generated by theme.sh — style: $pack"; cat "$STYLES_DIR/$pack/foot.ini"; } \
      > "$HOME/.config/foot/style.ini"
  fi
  if [ -f "$STYLES_DIR/$pack/sway.conf" ]; then
    { echo "# generated by theme.sh — style: $pack"; cat "$STYLES_DIR/$pack/sway.conf"; } \
      > "$HOME/.config/sway/style-effects.conf"
  fi
  printf '%s\n' "$pack" > "$STATE_DIR/style"
}

apply_style() {
  pack="$1"
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

apply() {
  name="$1"
  palette_allowed "$(current_style)" "$name" || {
    notify-send "theme" "style $(current_style) doesn't allow palette: $name"; exit 1; }
  resolve "$name" || { notify-send "theme" "unknown palette: $name"; exit 1; }

  # ── waybar ──
  bg_r=$((0x${BG#\#} >> 16 & 255)); bg_g=$((0x${BG#\#} >> 8 & 255)); bg_b=$((0x${BG#\#} & 255))
  cat > "$HOME/.config/waybar/colors.css" <<EOF
/* generated by theme.sh — palette: $name */
@define-color accent $ACC;
@define-color accent-dim $DIM;
@define-color bg rgba($bg_r, $bg_g, $bg_b, $ALPHA_BAR);
@define-color fg $FG;
@define-color muted $MUTED;
EOF

  # ── armoji-dock ──
  mkdir -p "$HOME/.config/armoji-dock"
  cat > "$HOME/.config/armoji-dock/colors.css" <<EOF
/* generated by theme.sh — palette: $name */
@define-color accent $ACC;
@define-color bg rgba($bg_r, $bg_g, $bg_b, $ALPHA_POP);
@define-color fg $FG;
@define-color muted $MUTED;
EOF

  # ── armoji-osd ──
  mkdir -p "$HOME/.config/armoji-osd"
  cat > "$HOME/.config/armoji-osd/colors.css" <<EOF
/* generated by theme.sh — palette: $name */
@define-color accent $ACC;
@define-color bg rgba($bg_r, $bg_g, $bg_b, $ALPHA_POP);
@define-color fg $FG;
@define-color muted $MUTED;
EOF

  # ── spotlight (custom launcher) ──
  mkdir -p "$HOME/.config/armoji-spotlight"
  cat > "$HOME/.config/armoji-spotlight/colors.css" <<EOF
/* generated by theme.sh — palette: $name */
@define-color accent $ACC;
@define-color bg rgba($bg_r, $bg_g, $bg_b, $ALPHA_POP);
@define-color fg $FG;
@define-color muted $MUTED;
EOF

  # ── foot (terminal) ──
  cat > "$HOME/.config/foot/colors.ini" <<EOF
# generated by theme.sh — palette: $name
[colors-dark]
alpha=$ALPHA_TERM
background=${BG#\#}
foreground=${FG#\#}
selection-foreground=${BG#\#}
selection-background=${ACC#\#}
regular0=${BG2#\#}
regular1=${R1#\#}
regular2=${R2#\#}
regular3=${R3#\#}
regular4=${R4#\#}
regular5=${R5#\#}
regular6=${R6#\#}
regular7=${FG#\#}
bright0=${MUTED#\#}
bright1=${B1#\#}
bright2=${B2#\#}
bright3=${B3#\#}
bright4=${B4#\#}
bright5=${B5#\#}
bright6=${B6#\#}
bright7=ffffff
EOF

  # ── kitty (sidebar terminals — cursor-trail animation foot doesn't have) ──
  mkdir -p "$HOME/.config/kitty"
  cat > "$HOME/.config/kitty/theme-colors.conf" <<EOF
# generated by theme.sh — palette: $name
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

  # ── walker ──
  cat > "$HOME/.config/walker/themes/armoji/colors.css" <<EOF
/* generated by theme.sh — palette: $name */
@define-color window_bg_color rgba($bg_r, $bg_g, $bg_b, $ALPHA_POP);
@define-color accent_bg_color $ACC;
@define-color theme_fg_color $FG;
@define-color error_bg_color #C34043;
@define-color error_fg_color #DCD7BA;
EOF

  # ── swaync ──
  cat > "$HOME/.config/swaync/colors.css" <<EOF
/* generated by theme.sh — palette: $name */
@define-color cc-bg rgba($bg_r, $bg_g, $bg_b, $ALPHA_CC);
@define-color accent $ACC;
@define-color fg $FG;
@define-color muted $MUTED;
EOF

  # ── GTK apps (adw-gtk3 + libadwaita accent overrides) ──
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
@define-color window_bg_color $BG2;
@define-color window_fg_color $FG;
@define-color view_bg_color $BG;
@define-color view_fg_color $FG;
@define-color headerbar_bg_color $BG;
@define-color headerbar_fg_color $FG;
@define-color sidebar_bg_color $BG;
@define-color sidebar_fg_color $FG;
@define-color secondary_sidebar_bg_color $BG;
@define-color secondary_sidebar_fg_color $FG;
@define-color card_bg_color $BG2;
@define-color card_fg_color $FG;
@define-color dialog_bg_color $BG2;
@define-color dialog_fg_color $FG;
@define-color popover_bg_color $BG2;
@define-color popover_fg_color $FG;
EOF
  done


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
    python3 - "$ACC" "$SLOT_DIR" <<'PYEOF2'
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

  # ── swaylock (whole config is generated; edit here, not there) ──
  # needs swaylock-effects for clock + blur/vignette
  cat > "$HOME/.config/swaylock/config" <<EOF
# generated by theme.sh — palette: $name
ignore-empty-password
show-failed-attempts
daemonize
image=$HOME/dotfiles/wallpapers/current
scaling=fill
# darkened, blurred background
effect-blur=8x5
effect-vignette=0.4:0.6
# big clock near the top, always visible (so the screen isn't blank)
clock
timestr=%H:%M
datestr=%A, %B %e
font-size=36
indicator
indicator-idle-visible
indicator-radius=115
indicator-y-position=260
indicator-thickness=8
font=JetBrainsMono Nerd Font
color=${BG#\#}
inside-color=${BG#\#}cc
inside-clear-color=${BG#\#}cc
inside-ver-color=${BG#\#}cc
inside-wrong-color=${BG#\#}cc
line-color=00000000
line-clear-color=00000000
line-ver-color=00000000
line-wrong-color=00000000
separator-color=00000000
ring-color=${BG2#\#}
ring-clear-color=${DIM#\#}
ring-ver-color=${ACC#\#}
ring-wrong-color=e06c75
key-hl-color=${ACC#\#}
bs-hl-color=e06c75
text-color=${FG#\#}
text-clear-color=${FG#\#}
text-ver-color=${FG#\#}
text-wrong-color=e06c75
EOF

  printf '%s\n' "$name" > "$STATE_DIR/theme"

  # ── reload the world ──
  swaymsg reload >/dev/null 2>&1
  # SIGUSR2 reloads waybar's config+style in place (restarting it would orphan
  # the media modules' cava/playerctl children)
  pkill -USR2 waybar 2>/dev/null
  killall walker 2>/dev/null; swaymsg exec 'walker --gapplication-service' >/dev/null 2>&1
  pkill -USR1 -f 'armoji-dock' >/dev/null 2>&1
  pkill -USR1 -f 'armoji-osd' >/dev/null 2>&1
  swaync-client --reload-css >/dev/null 2>&1
  # kitty re-reads its config (colors + style include) on SIGUSR1
  pkill -USR1 -x kitty 2>/dev/null
  # spotlight (resident daemon) re-reads its colors.css on SIGUSR1 — no restart
  pkill -USR1 -f 'armoji-spotlight --daemon' 2>/dev/null
  # already-open foot terminals: foot caches its palette at startup and has no
  # config-reload signal (SIGUSR1 only toggles the cached dark/light theme), so
  # push the new colors straight to every pty via OSC escapes — the pywal trick
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
  # toggle through a dummy value first so apps that only react to a change
  # event actually refresh, then land on Slot-Multicolor-Dark-Icons
  gsettings set org.gnome.desktop.interface icon-theme 'Adwaita' 2>/dev/null
  gsettings set org.gnome.desktop.interface icon-theme 'Slot-Multicolor-Dark-Icons' 2>/dev/null
  notify-send -t 3000 "󰏘 Theme" "palette: $name ($ACC)"
}

case "$1" in
  apply)   apply "$2" ;;
  startup)
    copy_style "$(current_style)"
    apply "$(cat "$STATE_DIR/theme" 2>/dev/null || echo wallpaper)"
    ;;
  style) apply_style "$2" ;;
  style-pick)
    choice=$(list_styles | walker --dmenu -p "style ❯")
    [ -n "$choice" ] && apply_style "$choice"
    ;;
  pick)
    allowed=$(allowed_palettes "$(current_style)")
    if [ -n "$allowed" ]; then choices=$(printf '%s\n' $allowed); else choices="$PALETTES"; fi
    choice=$(printf '%s\n' "$choices" | walker --dmenu -p "color ❯")
    [ -n "$choice" ] && apply "$choice"
    ;;
  tone)
    case "$2" in light|heavy|loud) ;; *) echo "tone: light|heavy|loud" >&2; exit 1 ;; esac
    printf '%s\n' "$2" > "$STATE_DIR/tone"
    apply "$(cat "$STATE_DIR/theme" 2>/dev/null || echo wallpaper)"
    ;;
  tone-pick)
    choice=$(printf 'light\nheavy\nloud\n' | walker --dmenu -p "tone ❯")
    [ -n "$choice" ] && "$0" tone "$choice"
    ;;
  *) echo "usage: theme.sh apply <palette> | pick | tone <light|heavy|loud> | tone-pick | style <pack> | style-pick | startup" >&2; exit 1 ;;
esac
