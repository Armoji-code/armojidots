import QtQuick
import Quickshell

Chip {
  numeric: true
  readonly property bool shown: Brightness.dev !== ""   // BarWidget collapses the slot
  visible: shown
  text: "󰃞 " + Brightness.percent + "%"
  readonly property string osd: Quickshell.env("HOME") + "/.config/sway/scripts/osd.sh"
  onScrolled: d => Quickshell.execDetached([osd, d > 0 ? "brightness-up" : "brightness-down"])
}
