// Live wallpaper: Pipes on the bottom layer (above swaybg, below windows) on
// every screen while ~/.local/state/armojidots/live-wallpaper says "pipes".
// wallpaper-pick.sh writes/clears that file.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
  FileView {
    id: live
    path: Quickshell.env("HOME") + "/.local/state/armojidots/live-wallpaper"
    watchChanges: true; printErrors: false
    onFileChanged: reload()
  }

  Variants {
    model: live.text().trim() === "pipes" ? Quickshell.screens : []
    PanelWindow {
      required property var modelData
      screen: modelData
      WlrLayershell.namespace: "armoji-wallpaper"
      WlrLayershell.layer: WlrLayer.Bottom
      exclusionMode: ExclusionMode.Ignore
      anchors { top: true; bottom: true; left: true; right: true }
      color: "transparent"
      Pipes { anchors.fill: parent }
    }
  }
}
