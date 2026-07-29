#!/bin/sh
# Waybar power-profile pill: shows current profile, click cycles
# power-saver → balanced → performance → …
#
# Writes /sys/firmware/acpi/platform_profile directly (thinkpad_acpi's DYTC
# interface) — no more power-profiles-daemon. ppd used to silently downgrade
# this on every ThinkPad "lapmode" EC ping, real or false-positive, fighting
# whatever you'd actually picked; TLP (replaced it) never touches this file
# unless you explicitly configure PLATFORM_PROFILE_ON_* in tlp.conf, which
# we don't, so this script is the sole owner. Group-wheel write access is
# set up by /etc/tmpfiles.d/platform-profile.conf.

PP=/sys/firmware/acpi/platform_profile
cur=$(cat "$PP" 2>/dev/null)

# platform_profile's own vocabulary is low-power/balanced/performance;
# map to the power-saver/balanced/performance names used everywhere else
# in this config (waybar classes, tooltip)
name() {
  case "$1" in
    low-power) echo "power-saver" ;;
    *) echo "$1" ;;
  esac
}
raw() {
  case "$1" in
    power-saver) echo "low-power" ;;
    *) echo "$1" ;;
  esac
}

case "$1" in
  status)
    n=$(name "$cur")
    case "$n" in
      performance) icon="󰓅" ;;
      balanced)    icon="󰾅" ;;
      power-saver) icon="󰾆" ;;
      *)           icon="󰾅" ;;
    esac
    printf '{"text":"%s","tooltip":"profile: %s","class":"%s"}\n' "$icon" "$n" "$n"
    ;;
  toggle)
    n=$(name "$cur")
    case "$n" in
      power-saver) next=balanced ;;
      balanced)    next=performance ;;
      performance) next=power-saver ;;
      *)           next=balanced ;;
    esac
    raw "$next" > "$PP"
    pkill -SIGRTMIN+8 waybar
    ;;
esac
