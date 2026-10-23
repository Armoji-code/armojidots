// Spotlight page: the settings hub — a tile per page, with live status.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Bluetooth

Item {
  id: hub
  required property var host
  implicitWidth: grid.implicitWidth
  implicitHeight: grid.implicitHeight
  readonly property var net: Networking.devices.values.find(d => d.type === DeviceType.Wifi)
    ?.networks.values.find(n => n.connected) ?? null
  readonly property var ad: Bluetooth.defaultAdapter
  readonly property int btN: ad ? ad.devices.values.filter(d => d.connected).length : 0
  FileView { id: dispMode; path: Quickshell.env("HOME") + "/.local/state/armojidots/display-mode"; printErrors: false }
  FileView { id: palette; path: Quickshell.env("HOME") + "/.local/state/armojidots/theme" }

  readonly property var tiles: [
    ["wifi", "network-wireless-signal-excellent", !Networking.wifiEnabled ? "Off" : net ? net.name : "Not connected"],
    ["bluetooth", "bluetooth", !ad?.enabled ? "Off" : btN ? btN + " connected" : "On"],
    ["monitors", "video-display", dispMode.text().trim() === "extend" ? "Extend" : "Mirror"],
    ["customize", "preferences-desktop-theme", (host.ctx.packs[host.ctx.style]?.title ?? host.ctx.style) + " · " + (palette.text().trim() || "wallpaper")],
    ["idle", "preferences-desktop-screensaver", (Idle.saverOn ? "Saver " + Idle.saverMin + "m" : "Saver off") + " · " + (Idle.lockOn ? "Lock " + Idle.lockMin + "m" : "Lock off")],
    ["layout", "preferences-system-windows", "Coming soon"],
    ["power", "system-shutdown", "Lock, suspend, reboot…"],
    ["keys", "input-keyboard", "Cheat sheet"],
    ["updates", "system-software-update", "System, AUR, dotfiles"],
    ["web", "web-browser", "Search Google"],
  ]

  Grid {
    id: grid
    columns: 5
    spacing: 10
    Repeater {
      model: hub.tiles
      UiCard {
        id: tile
        required property var modelData
        width: 150
        height: 132
        hover: tileMa.containsMouse
        Column {
          anchors.centerIn: parent
          width: parent.width - 20
          spacing: 6
          Image {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 40; height: 40
            sourceSize: Qt.size(80, 80)
            source: hub.host.iconSrc(tile.modelData[1])
          }
          UiLabel { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: hub.host.titles[tile.modelData[0]] ?? "Web search"; font.pixelSize: 14 }
          UiLabel { width: parent.width; horizontalAlignment: Text.AlignHCenter; dim: true; text: tile.modelData[2] }
        }
        MouseArea { id: tileMa; anchors.fill: parent; hoverEnabled: true; onClicked: tile.modelData[0] === "web" ? hub.host.typeQuery("/web ") : hub.host.openPage(tile.modelData[0]) }
      }
    }
  }
}
