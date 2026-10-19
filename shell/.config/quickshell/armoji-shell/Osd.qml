// ── armojidots · OSD ────────────────────────────────────────────────
// Volume/brightness pill near the bottom edge, above fullscreen apps.
// Reacts to the level itself changing (Pipewire sink, backlight uevents),
// so it shows for any change, keys or not. The window stays mapped but
// click-through; only its content slides/fades in and out.
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire

PanelWindow {
  id: osd
  WlrLayershell.namespace: "armoji-osd"
  WlrLayershell.layer: WlrLayer.Overlay
  exclusionMode: ExclusionMode.Ignore
  anchors.bottom: true
  margins.bottom: 110
  implicitWidth: pill.implicitWidth
  implicitHeight: 46 + 12
  color: "transparent"
  mask: Region {}                    // never takes input

  property string kind: "volume"
  property int value: 0
  property bool muted: false
  property bool shown: false
  property bool ready: false         // ignore the initial values at startup
  Timer { running: true; interval: 1500; onTriggered: osd.ready = true }
  Timer { id: hideT; interval: 1400; onTriggered: osd.shown = false }

  function show(k, v, m) {
    if (!ready) return
    kind = k; value = Math.max(0, Math.min(100, v)); muted = m
    shown = true
    hideT.restart()
  }

  readonly property var sink: Pipewire.defaultAudioSink
  PwObjectTracker { objects: [osd.sink] }
  Connections {
    target: osd.sink?.audio ?? null
    function onVolumeChanged() { osd.show("volume", Math.round(osd.sink.audio.volume * 100), osd.sink.audio.muted) }
    function onMutedChanged() { osd.show("volume", Math.round(osd.sink.audio.volume * 100), osd.sink.audio.muted) }
  }
  Connections {
    target: Brightness
    function onCurChanged() { osd.show("brightness", Brightness.percent, false) }
  }

  property real t: shown ? 1 : 0
  Behavior on t { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

  Rectangle {
    id: pill
    y: (1 - osd.t) * 12
    opacity: osd.t
    implicitWidth: row.implicitWidth + 2 * Theme.n("osdPad", 18)
    height: 46
    radius: Math.min(Theme.n("osdRadius", 999), height / 2)
    color: Theme.col("osdBg", "bg")
    border.width: Theme.line("osdBorder")
    border.color: Theme.col("osdBorder", "transparent")

    Row {
      id: row
      anchors.centerIn: parent
      spacing: 10

      Rectangle {
        readonly property real s: Theme.n("osdIconChipSize", 0)
        width: Math.max(s, icon.implicitWidth); height: Math.max(s, icon.implicitHeight)
        anchors.verticalCenter: parent.verticalCenter
        radius: Theme.n("osdIconChipRadius", 0)
        color: Theme.col("osdIconChip", "transparent")
        Text {
          id: icon
          anchors.centerIn: parent
          text: osd.kind === "brightness" ? "󰃞"
              : osd.muted ? "󰝟" : ["󰕿", "󰖀", "󰕾"][osd.value < 34 ? 0 : osd.value < 67 ? 1 : 2]
          color: Theme.accent
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: Theme.n("osdIconSize", 18)
        }
      }

      Rectangle {
        width: 160
        height: Theme.n("osdTrackH", 3)
        anchors.verticalCenter: parent.verticalCenter
        radius: Math.min(Theme.n("osdTrackRadius", 999), height / 2)
        color: Theme.col("osdTrack", "#26ffffff")
        Rectangle {
          height: parent.height
          width: parent.width * osd.value / 100
          radius: parent.radius
          color: osd.muted ? Qt.alpha(Theme.fg, 0.35) : Theme.accent
          Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
          Behavior on color { ColorAnimation { duration: 120 } }
        }
      }

      Text {
        width: 36
        anchors.verticalCenter: parent.verticalCenter
        text: osd.muted && osd.kind === "volume" ? "mute" : osd.value + "%"
        color: Theme.muted
        font.family: Theme.n("osdPctFont", Theme.font)
        font.pixelSize: Theme.n("osdPctSize", 12)
      }
    }
  }
}
