import QtQuick
import Quickshell
import Quickshell.Networking

Chip {
  readonly property var devs: Networking.devices.values
  readonly property var wifi: devs.find(d => d.type === DeviceType.Wifi && d.connected) ?? null
  readonly property var net: wifi?.networks.values.find(n => n.connected) ?? null
  readonly property bool wired: devs.some(d => d.type === DeviceType.Wired && d.connected)
  text: net ? "󰤨 " + net.name : wired ? "󰈀" : "󰤭 offline"
  readonly property real sig: net ? (net.signalStrength <= 1 ? net.signalStrength * 100 : net.signalStrength) : 0
  tip: net ? net.name + " (" + Math.round(sig) + "%)<br>" + wifi.name
     : wired ? devs.find(d => d.type === DeviceType.Wired && d.connected).name : ""
  fg: net ? Theme.col("wifi", "accent") : Theme.fg
  onClicked: Quickshell.execDetached(["foot", "--app-id=float-tui", "-e", "nmtui"])
}
