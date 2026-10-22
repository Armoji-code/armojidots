#!/bin/sh
# armojidots installer (Arch-based distros).
#
#   ./install.sh              install: packages, configs, theme
#   ./install.sh --name       change the name in the terminal greeting
#   ./install.sh --uninstall  unlink the configs, restore what was backed up,
#                             remove what the installer added (packages stay)
#
# Nothing is overwritten: any existing file a config would replace is moved
# to ~/.local/state/armojidots/backup-<date>/ first, and every change is
# recorded in ~/.local/state/armojidots/install.manifest for --uninstall.
#
# Test hook: ARMOJI_NO_SYSTEM=1 skips packages, sudo steps, services and the
# live theme apply (for dry runs with a throwaway $HOME).
set -eu

REPO=$(cd "$(dirname "$0")" && pwd -P)
DOTS="$HOME/dotfiles"                       # the scripts expect the repo here
STATE="$HOME/.local/state/armojidots"
MANIFEST="$STATE/install.manifest"
CONF="$HOME/.config/armojidots/user.conf"
NO_SYSTEM=${ARMOJI_NO_SYSTEM:-0}

STOW_PKGS="sway shell styles waybar walker kitty foot swaync swayidle fish fastfetch starship gtk cursor environment-d"
# linked file by file: a folded ~/.local/share/icons would put every app's
# icons (and the icon theme) inside the repo
FILE_PKGS="icons"

# Everything the desktop calls, nothing else. Sorted into official repo vs
# AUR at runtime (some are in CachyOS's repos but AUR-only on plain Arch).
PACKAGES="swayfx-git swaysome swaybg swayidle swaylock-effects swaync autotiling
quickshell qmltermwidget kitty foot fish starship fastfetch toilet stow
elephant elephant-desktopapplications elephant-calc elephant-runner
elephant-websearch elephant-menus walker-bin
grim slurp wl-clipboard wl-mirror wlsunset jq cava playerctl wireplumber
brightnessctl libnotify imagemagick python xdg-utils gtk3 curl
pavucontrol nemo bluetuith-bin nwg-displays
adw-gtk-theme bibata-cursor-theme inter-font ttf-roboto ttf-roboto-mono
ttf-geist ttf-geist-mono ttf-jetbrains-mono-nerd"

say()  { printf '\033[1;36m::\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31mxx\033[0m %s\n' "$*" >&2; exit 1; }
ask() {  # ask <prompt> <default> -> answer on stdout (default on empty / EOF)
  printf '%s [%s]: ' "$1" "$2" >&2
  read -r a || a=""
  printf '%s' "${a:-$2}"
}
yes_no() { case $(ask "$1" "${2:-Y}") in [Yy]*) return 0 ;; *) return 1 ;; esac; }
record() { mkdir -p "$STATE"; printf '%s\n' "$*" >> "$MANIFEST"; }

# ── greeting name ────────────────────────────────────────────────────
set_name() {
  name=$(ask "Your name for the terminal greeting" "${1:-$USER}")
  name=$(printf '%s' "$name" | tr -cd '[:alnum:] ._-' | cut -c1-16)
  [ -n "$name" ] || name=$USER
  mkdir -p "$(dirname "$CONF")"
  printf 'NAME=%s\n' "$name" > "$CONF"
  upper=$(printf '%s' "$name" | tr '[:lower:]' '[:upper:]')
  logo="$HOME/.config/fastfetch/logo.txt"
  mkdir -p "$(dirname "$logo")"
  # "$1" = fastfetch's first logo color (the palette accent)
  if command -v toilet >/dev/null; then
    toilet -f pagga "HI $upper" | sed 's/^/$1/' > "$logo"
  else
    printf '$1HI %s\n' "$upper" > "$logo"
  fi
  say "Greeting set to: HI $upper"
}

# ── uninstall ────────────────────────────────────────────────────────
uninstall() {
  [ -f "$MANIFEST" ] || die "nothing to uninstall (no $MANIFEST)"
  say "Unlinking configs"
  # shellcheck disable=SC2086
  stow -D -d "$REPO" -t "$HOME" $STOW_PKGS $FILE_PKGS 2>/dev/null || warn "stow -D reported problems"
  # newest entries first, so restores happen after their links are gone
  tac "$MANIFEST" | while read -r kind path; do
    case "$kind" in
      backup)  # backup <backup dir>|<relative path>
        src="${path%%|*}/${path#*|}"; dst="$HOME/${path#*|}"
        if [ -e "$src" ] || [ -L "$src" ]; then
          if [ -e "$dst" ] || [ -L "$dst" ]; then warn "kept $dst (exists; backup stays in $src)"
          else mkdir -p "$(dirname "$dst")"; mv "$src" "$dst"; fi
        fi ;;
      file) rm -f "$path" ;;
      dir)  rm -rf "$path" ;;
      link) [ -L "$path" ] && rm -f "$path" ;;
      sudo) [ "$NO_SYSTEM" = 1 ] || sudo rm -rf "$path" ;;
      gsettings) [ "$NO_SYSTEM" = 1 ] || gsettings reset org.gnome.desktop.interface "$path" 2>/dev/null || true ;;
    esac
  done
  rm -rf "$HOME/.config/armoji-shell" "$HOME/.config/armojidots"
  mv "$MANIFEST" "$MANIFEST.uninstalled-$(date +%Y%m%d-%H%M%S)"
  say "Done. Packages were left installed; remove any you don't need with pacman -Rns."
  echo "    $PACKAGES" | tr '\n' ' '; echo
}

# ── install ──────────────────────────────────────────────────────────
backup_conflicts() {
  stamp="backup-$(date +%Y%m%d-%H%M%S)"
  dir="$STATE/$stamp"
  for pkg in $STOW_PKGS $FILE_PKGS; do
    ( cd "$REPO/$pkg" && find . \( -type f -o -type l \) ) | sed 's|^\./||' | while read -r rel; do
      dst="$HOME/$rel"
      { [ -e "$dst" ] || [ -L "$dst" ]; } || continue
      case "$(readlink -f "$dst" 2>/dev/null)" in "$REPO"/*) continue ;; esac   # already ours
      mkdir -p "$dir/$(dirname "$rel")"
      mv "$dst" "$dir/$rel"
      record backup "$dir|$rel"
    done
  done
  [ -d "$dir" ] && say "Existing configs moved to $dir" || true
}

packages() {
  command -v pacman >/dev/null || die "pacman not found: armojidots needs an Arch-based distro"
  say "Installing base tools"
  sudo pacman -S --needed --noconfirm base-devel git
  repo="" aur=""
  for p in $PACKAGES; do
    if pacman -Si "$p" >/dev/null 2>&1; then repo="$repo $p"; else aur="$aur $p"; fi
  done
  say "Official packages:$repo"
  # shellcheck disable=SC2086
  sudo pacman -S --needed $repo
  [ -n "$aur" ] || return 0
  helper=$(command -v yay || command -v paru || true)
  if [ -z "$helper" ]; then
    yes_no "No AUR helper found. Build yay from the AUR?" || die "AUR packages needed:$aur"
    tmp=$(mktemp -d)
    git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
    (cd "$tmp/yay-bin" && makepkg -si --noconfirm)
    rm -rf "$tmp"
    helper=yay
  fi
  say "AUR packages:$aur"
  # shellcheck disable=SC2086
  "$helper" -S --needed $aur
}

user_setup() {
  set_name "$(sed -n 's/^NAME=//p' "$CONF" 2>/dev/null)"
  record file "$HOME/.config/fastfetch/logo.txt"

  layouts=$(ask "Keyboard layouts, comma-separated xkb codes (e.g. us,de)" "us")
  layouts=$(printf '%s' "$layouts" | tr -cd 'a-z0-9,()_-')
  printf '# generated by install.sh — your keyboard layouts\ninput type:keyboard xkb_layout "%s"\n' \
    "${layouts:-us}" > "$HOME/.config/sway/keyboard.conf"
  record file "$HOME/.config/sway/keyboard.conf"

  walls="$HOME/Pictures/Wallpapers"
  mkdir -p "$walls"
  for f in "$REPO"/wallpapers/*.png "$REPO"/wallpapers/*.jpg; do
    [ -f "$f" ] || continue
    [ -e "$walls/$(basename "$f")" ] && continue
    cp "$f" "$walls/"; record file "$walls/$(basename "$f")"
  done
  if [ ! -e "$REPO/wallpapers/current" ]; then
    ln -sf "$walls/nothing-11-mesh.png" "$REPO/wallpapers/current"
  fi

  if [ ! -d "$HOME/.local/share/icons/Slot-Multicolor-Dark-Icons" ]; then
    sh "$REPO/assets/install-icon-theme.sh" >/dev/null
    record dir "$HOME/.local/share/icons/Slot-Multicolor-Dark-Icons"
  fi

  font="$HOME/.local/share/fonts/armojidots/BitcountGridSingle.ttf"
  if ! fc-list 2>/dev/null | grep -q "Bitcount Grid Single" && [ "$NO_SYSTEM" != 1 ]; then
    mkdir -p "$(dirname "$font")"
    if curl -fsSL -o "$font" \
      "https://github.com/google/fonts/raw/main/ofl/bitcountgridsingle/BitcountGridSingle%5BCRSV,ELSH,ELXP,slnt,wght%5D.ttf"; then
      fc-cache -f >/dev/null 2>&1 || true
      record dir "$(dirname "$font")"
    else warn "couldn't download Bitcount Grid Single (Nothing OS clock font) — skipped"; fi
  fi
}

system_setup() {
  [ "$NO_SYSTEM" = 1 ] && return 0
  if command -v elephant >/dev/null; then elephant service enable >/dev/null 2>&1 || warn "elephant service enable failed"; fi
  for k in gtk-theme icon-theme font-name monospace-font-name; do record gsettings "$k"; done

  yes_no "Apply the two system tweaks (sidebar terminal colors, shell priority)? Needs sudo" || return 0
  # the sidebar's terminal widget only reads color schemes from its own dir
  schemes=/usr/lib/qt6/qml/QMLTermWidget/color-schemes
  if [ -d "$schemes" ]; then
    sudo ln -sf "$HOME/.config/armoji-shell/terminal.colorscheme" "$schemes/armoji.colorscheme"
    record sudo "$schemes/armoji.colorscheme"
  fi
  # CachyOS's ananicy-cpp runs every `qs` as a background service (nice 10)
  if command -v ananicy-cpp >/dev/null; then
    sudo mkdir -p /etc/ananicy.d/00-armoji
    echo '{ "name": "qs", "nice": -6 }' | sudo tee /etc/ananicy.d/00-armoji/armoji.rules >/dev/null
    record sudo /etc/ananicy.d/00-armoji
  fi
}

install() {
  [ "$(id -u)" != 0 ] || die "run as your normal user, not root (sudo is asked when needed)"
  if [ "$REPO" != "$(readlink -f "$DOTS" 2>/dev/null || echo "$DOTS")" ]; then
    [ -e "$DOTS" ] || [ -L "$DOTS" ] && die "$DOTS already exists and isn't this repo — move it, or clone armojidots there"
    ln -s "$REPO" "$DOTS"; record link "$DOTS"
  fi

  cat <<EOF

  armojidots will:
    • install the packages the desktop needs (pacman + AUR, --needed)
    • move configs it would replace to $STATE/backup-<date>/
    • link its configs into ~/.config with GNU Stow
    • ask your name (terminal greeting) and keyboard layouts
    • copy its wallpapers to ~/Pictures/Wallpapers, install its icon theme
  Undo any time with: ./install.sh --uninstall

EOF
  yes_no "Continue?" || exit 0

  [ "$NO_SYSTEM" = 1 ] || packages
  command -v stow >/dev/null || die "stow is missing"
  backup_conflicts
  say "Linking configs"
  mkdir -p "$HOME/.config" "$HOME/.local/share/icons" "$HOME/.local/state"
  # shellcheck disable=SC2086
  stow -d "$REPO" -t "$HOME" $STOW_PKGS
  # shellcheck disable=SC2086
  stow --no-folding -d "$REPO" -t "$HOME" $FILE_PKGS
  user_setup
  system_setup
  mkdir -p "$STATE"
  if [ "$NO_SYSTEM" != 1 ]; then
    say "Generating colors and the Material style"
    "$HOME/.config/sway/scripts/theme.sh" style material >/dev/null 2>&1 || warn "theme.sh reported errors (it retries at login)"
  fi
  say "Installed. Log out and pick \"SwayFX\" (sway) in your display manager."
}

case "${1:-}" in
  --uninstall) uninstall ;;
  --name)      set_name "$(sed -n 's/^NAME=//p' "$CONF" 2>/dev/null)" ;;
  ""|--install) install ;;
  *) die "usage: ./install.sh [--name | --uninstall]" ;;
esac
