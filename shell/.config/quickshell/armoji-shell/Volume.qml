import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Chip {
  numeric: true
  readonly property var sink: Pipewire.defaultAudioSink
  readonly property real v: sink?.audio?.volume ?? 0
  PwObjectTracker { objects: [sink] }
  text: sink?.audio?.muted ? "󰝟 mute"
      : ["󰕿", "󰖀", "󰕾"][Math.min(2, Math.floor(v * 3))] + " " + Math.round(v * 100) + "%"
  onClicked: Quickshell.execDetached(["foot", "--app-id=float-tui", "-e", "pulsemixer"])
}
