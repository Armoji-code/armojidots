import QtQuick
import Quickshell
import Quickshell.Bluetooth

Chip {
  readonly property var ad: Bluetooth.defaultAdapter
  readonly property int n: ad ? ad.devices.values.filter(d => d.connected).length : 0
  text: !ad?.enabled ? "󰂲" : n ? "󰂱 " + n : "󰂯"
  icon: n === 0
  tip: !ad ? "" : [ad.name].concat(ad.devices.values.filter(d => d.connected).map(d => d.name)).join("<br>")
  onClicked: Quickshell.execDetached(["qs", "-c", "armoji-shell", "ipc", "call", "spotlight", "page", "bluetooth"])
}
