import QtQuick
import Quickshell

Chip {
  visible: Brightness.dev !== ""
  text: "󰃞 " + Brightness.percent + "%"
  readonly property string osd: Quickshell.env("HOME") + "/.config/sway/scripts/osd.sh"
  onScrolled: d => Quickshell.execDetached([osd, d > 0 ? "brightness-up" : "brightness-down"])
}
