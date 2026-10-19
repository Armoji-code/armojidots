pragma Singleton
// Backlight level, shared by the bar chip and the OSD. sysfs brightness
// doesn't emit inotify events, but the kernel sends a backlight uevent on
// every change: re-read on each one.
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: b
  property string dev: ""
  property real cur: 0
  property real max: 1
  readonly property int percent: Math.round(cur / max * 100)

  Process {
    running: true
    command: ["sh", "-c", "ls /sys/class/backlight | head -n1"]
    stdout: SplitParser { onRead: data => b.dev = "/sys/class/backlight/" + data }
  }
  FileView { path: b.dev ? b.dev + "/max_brightness" : ""; onLoaded: b.max = parseInt(text()) || 1 }
  FileView { id: curf; path: b.dev ? b.dev + "/brightness" : ""; onLoaded: b.cur = parseInt(text()) || 0 }
  Process {
    running: b.dev !== ""
    command: ["setpriv", "--pdeathsig", "TERM", "udevadm", "monitor", "--kernel", "--subsystem-match=backlight"]
    stdout: SplitParser { onRead: data => { if (data.includes("change")) curf.reload() } }
  }
}
