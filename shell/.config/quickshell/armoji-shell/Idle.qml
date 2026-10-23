pragma Singleton
// Idle settings + actions, set from Spotlight's Idle page (and the bar's
// auto-lock button). Screensaver (Screensaver.qml, LockSurface.qml) after
// saverMin, lock after lockMin when armed, screens off after offMin until
// input. Apps' idle inhibitors (fullscreen video) hold all of them off.
// swayidle only does lock-before-sleep. Saved in ~/.local/state/armojidots/idle.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Singleton {
  id: idl
  readonly property string file: Quickshell.env("HOME") + "/.local/state/armojidots/idle"
  property bool saverOn: true
  property int saverMin: 2
  property bool lockOn: false
  property int lockMin: 5
  property bool offOn: true
  property int offMin: 10

  FileView {
    path: idl.file
    printErrors: false
    onLoaded: {
      const kv = {}
      for (const l of text().split("\n")) { const i = l.indexOf("="); if (i > 0) kv[l.slice(0, i)] = l.slice(i + 1) }
      if (kv.saver) idl.saverOn = kv.saver === "on"
      if (kv.saver_min) idl.saverMin = Number(kv.saver_min)
      if (kv.lock) idl.lockOn = kv.lock === "on"
      if (kv.lock_min) idl.lockMin = Number(kv.lock_min)
      if (kv.off) idl.offOn = kv.off === "on"
      if (kv.off_min) idl.offMin = Number(kv.off_min)
    }
  }
  function set(key, value) {
    idl[key] = value
    const t = ["saver=" + (saverOn ? "on" : "off"), "saver_min=" + saverMin,
               "lock=" + (lockOn ? "on" : "off"), "lock_min=" + lockMin,
               "off=" + (offOn ? "on" : "off"), "off_min=" + offMin].join("\n")
    Quickshell.execDetached(["sh", "-c", 'mkdir -p "${1%/*}" && printf "%s\\n" "$2" > "$1"', "sh", file, t])
  }

  IdleMonitor {
    enabled: idl.lockOn
    timeout: idl.lockMin * 60
    onIsIdleChanged: if (isIdle) Quickshell.execDetached(["sh", "-c", "~/.config/sway/scripts/lock.sh"])
  }
  IdleMonitor {
    enabled: idl.offOn
    timeout: idl.offMin * 60
    onIsIdleChanged: Quickshell.execDetached(["swaymsg", "output * power " + (isIdle ? "off" : "on")])
  }
}
