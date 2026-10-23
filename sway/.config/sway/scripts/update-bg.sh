#!/bin/sh
# Background updates for Spotlight's /update page ("Run in background").
#   update-bg.sh <full|pacman|aur|flatpak|dotfiles>   password on stdin
# The password is checked first (exit 3 if wrong, "AUTH_OK" on stdout if
# right), then handed to sudo through askpass (this script again, reading it
# from the environment) — it is never written to disk. Output goes to
# ~/.local/state/armojidots/update.log; a notification reports the result.

if [ -n "$ARMOJI_ASKPASS" ]; then printf '%s\n' "$ARMOJI_ASKPASS"; exit 0; fi

what=${1:-full}
LOG="$HOME/.local/state/armojidots/update.log"
mkdir -p "${LOG%/*}"
AUR=$(command -v yay || command -v paru)
AUR=${AUR##*/}
has() { command -v "$1" >/dev/null 2>&1; }

if [ "$what" != dotfiles ]; then
  IFS= read -r ARMOJI_PW
  printf '%s\n' "$ARMOJI_PW" | sudo -k -S -p '' -v 2>/dev/null || exit 3
  export SUDO_ASKPASS="$(realpath "$0")" ARMOJI_ASKPASS="$ARMOJI_PW"
fi
echo AUTH_OK

pacman_up()  { sudo -A pacman -Syu --noconfirm; }
aur_up()     { "$AUR" "$@" --noconfirm --sudoflags -A --answerdiff None --answerclean None; }
flatpak_up() {
  sudo -A flatpak update --system -y --noninteractive &&
  flatpak update --user -y --noninteractive
}

{
  echo "── $what · $(date '+%F %T') ──"
  case "$what" in
    # flatpak runs even if one AUR package fails; the result reports both
    full)     if [ -n "$AUR" ]; then aur_up -Syu; else pacman_up; fi; r=$?
              if has flatpak; then flatpak_up || r=1; fi
              [ $r -eq 0 ] ;;
    pacman)   pacman_up ;;
    aur)      aur_up -Sua ;;
    flatpak)  flatpak_up ;;
    dotfiles) git -C "$HOME/dotfiles" pull --ff-only ;;
    *)        echo "unknown target: $what"; false ;;
  esac
} > "$LOG" 2>&1 </dev/null
rc=$?
sudo -k

if [ $rc -eq 0 ]; then title="Update finished"; urg=normal
else title="Update failed"; urg=critical; fi
# wait for the click in the background; this script's job (and the shell's
# "updating…" state) ends now
( act=$(notify-send -u "$urg" -i system-software-update -A open="Open log" \
          "$title" "$what · $(tail -n1 "$LOG" | cut -c1-120)")
  [ "$act" = open ] && kitty less +G "$LOG" ) >/dev/null 2>&1 &
exit $rc
