// Spotlight page: the settings hub — a tile per page, with live status.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire

Item {
  id: hub
  required property var host
  implicitWidth: grid.implicitWidth
  implicitHeight: grid.implicitHeight
  readonly property var net: Networking.devices.values.find(d => d.type === DeviceType.Wifi)
    ?.networks.values.find(n => n.connected) ?? null
  readonly property var ad: Bluetooth.defaultAdapter
  readonly property var sink: Pipewire.defaultAudioSink
  PwObjectTracker { objects: [hub.sink] }
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
    ["audio", "audio-volume-high", !sink ? "No output" : sink.audio?.muted ? "Muted" : Math.round((sink.audio?.volume ?? 0) * 100) + "% · " + (sink.description || sink.name)],
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
          UiIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            name: tile.modelData[1]
            size: 40
            color: tileMa.containsMouse ? Theme.accent : Theme.fg
          }
          UiLabel { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: hub.host.titles[tile.modelData[0]]; font.pixelSize: 14 }
          UiLabel { width: parent.width; horizontalAlignment: Text.AlignHCenter; dim: true; text: tile.modelData[2] }
        }
        MouseArea { id: tileMa; anchors.fill: parent; hoverEnabled: true; onClicked: hub.host.openPage(tile.modelData[0]) }
      }
    }
  }
}
