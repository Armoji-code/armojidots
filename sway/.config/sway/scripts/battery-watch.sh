#!/bin/sh
# Laptop battery watcher (exits on machines without a battery).
#  - Low battery notifications at 20/10/5%, only while discharging; each
#    fires once per discharge cycle. They close after 10 s, and right away
#    when you plug in.
#  - Power profile follows the power state, on transitions only (so a
#    profile picked by hand stays until the next plug/unplug/low):
#    charging → performance, on battery → balanced, ≤20% → power saver.

# one per login: a copy left over from an earlier sway session keeps the lock
# (and keeps working), so a new session's copy doesn't double every warning
exec 9> "${XDG_RUNTIME_DIR:-/tmp}/battery-watch.lock"
flock -n 9 || exit 0

BAT=${BAT:-$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -n1)}   # env overrides: testing
[ -n "$BAT" ] || exit 0
PP=${PP:-/sys/firmware/acpi/platform_profile}   # low-power / balanced / performance

n20=0; n10=0; n5=0
nid=""        # id of the battery notification on screen (replaced, not stacked)
state=""      # ac | bat | low  — last applied

profile() { [ -w "$PP" ] && grep -qw "$1" "${PP}_choices" 2>/dev/null && echo "$1" > "$PP"; }
close() {
  [ -n "$1" ] && gdbus call --session --dest org.freedesktop.Notifications \
    --object-path /org/freedesktop/Notifications \
    --method org.freedesktop.Notifications.CloseNotification "$1" >/dev/null 2>&1
}
warn() {  # warn <urgency> <cap> <body>
  nid=$(notify-send -p ${nid:+-r "$nid"} -u "$1" "󰂎 Battery: $2%" "$3")
  (sleep 10; close "$nid") &
}

while :; do
  cap=$(cat "$BAT/capacity" 2>/dev/null)
  status=$(cat "$BAT/status" 2>/dev/null)

  if [ "$status" = "Discharging" ] && [ -n "$cap" ]; then
    if [ "$cap" -le 20 ]; then new=low; else new=bat; fi
    if [ "$cap" -le 5 ] && [ "$n5" -eq 0 ]; then
      warn critical "$cap" "YO BRO PLUG IT IN!!!"
      n5=1; n10=1; n20=1
    elif [ "$cap" -le 10 ] && [ "$n10" -eq 0 ]; then
      warn critical "$cap" "Yo bro you heard me the first time right?"
      n10=1; n20=1
    elif [ "$cap" -le 20 ] && [ "$n20" -eq 0 ]; then
      warn normal "$cap" "Yo bro heads up its pretty low"
      n20=1
    fi
  else
    new=ac
    n20=0; n10=0; n5=0
    close "$nid"; nid=""
  fi

  if [ "$new" != "$state" ]; then
    case "$new" in
      ac)  profile performance ;;
      bat) profile balanced ;;
      low) profile low-power ;;
    esac
    state=$new
  fi

  sleep 5
done
