// Spotlight page: audio. Output / input device + volume, and a volume per
// app. Sliders (UiTrack) go to 150%; the part past 100% is drawn in fg.
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Item {
  id: pg
  required property var host
  implicitWidth: 680
  implicitHeight: Math.min(480, col.implicitHeight)

  readonly property var nodes: Pipewire.nodes.values.filter(n => n.audio)
  readonly property var sinks: nodes.filter(n => n.isSink && !n.isStream)
  readonly property var sources: nodes.filter(n => !n.isSink && !n.isStream)
  readonly property var apps: nodes.filter(n => n.isStream && n.properties["media.class"] === "Stream/Output/Audio")   // playback only (not cava)
  PwObjectTracker { objects: pg.nodes }

  function label(n) { return n?.description || n?.nickname || n?.name || "—" }
  // stream icon: its own, else the app's desktop entry, else a speaker
  function appIcon(n) {
    const p = n.properties
    return p["application.icon-name"]
      || DesktopEntries.heuristicLookup((p["application.name"] ?? "").toLowerCase())?.icon
      || DesktopEntries.heuristicLookup((p["application.process.binary"] ?? "").replace(/-bin$/, ""))?.icon
      || "audio-volume-high"
  }
  function appName(n) { return n.properties["application.name"] || n.properties["media.name"] || n.name }

  component VolumeRow: Item {
    id: r
    required property var node
    property string icon: "audio-volume-high"
    property string title: ""
    readonly property real v: node?.audio?.volume ?? 0
    readonly property bool muted: node?.audio?.muted ?? false
    width: parent.width
    height: 36
    function set(x) { if (node?.audio) node.audio.volume = Math.max(0, Math.min(1.5, Math.round(x * 100) / 100)) }

    // icon = mute toggle
    UiIcon {
      id: ic
      anchors { left: parent.left; verticalCenter: parent.verticalCenter }
      name: r.icon
      size: 22
      opacity: r.muted ? 0.35 : 1
      MouseArea { anchors.fill: parent; onClicked: r.node.audio.muted = !r.muted }
    }
    UiLabel {
      id: name
      visible: r.title !== ""
      anchors { left: ic.right; leftMargin: 10; verticalCenter: parent.verticalCenter }
      width: visible ? 150 : 0
      text: r.title
    }
    UiTrack {
      id: track
      anchors { left: name.right; leftMargin: 12; right: pct.left; rightMargin: 12; verticalCenter: parent.verticalCenter }
      opacity: r.muted ? 0.45 : 1
      frac: Math.min(r.v, 1.5) / 1.5
      boostAt: 1 / 1.5
      MouseArea {
        anchors.fill: parent
        anchors.margins: -6
        onPressed: m => r.set(1.5 * (m.x - 6) / track.width)
        onPositionChanged: m => r.set(1.5 * (m.x - 6) / track.width)
        onWheel: w => r.set(r.v + (w.angleDelta.y > 0 ? 0.05 : -0.05))
      }
    }
    UiLabel {
      id: pct
      anchors { right: parent.right; verticalCenter: parent.verticalCenter }
      width: 44
      horizontalAlignment: Text.AlignRight
      dim: r.muted
      text: r.muted ? "mute" : Math.round(r.v * 100) + "%"
    }
  }

  Flickable {
    anchors.fill: parent
    contentHeight: col.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    Column {
      id: col
      width: parent.width
      spacing: 10

      Repeater {   // output, input
        model: [["Output", pg.sinks, Pipewire.defaultAudioSink, "audio-volume-high"],
                ["Input", pg.sources, Pipewire.defaultAudioSource, "audio-input-microphone"]]
        UiCard {
          id: dev
          required property var modelData
          required property int index
          width: col.width
          height: devCol.implicitHeight + 24
          Column {
            id: devCol
            x: 16; y: 12
            width: parent.width - 32
            spacing: 6
            Item {
              width: parent.width; height: 32
              UiLabel { anchors.verticalCenter: parent.verticalCenter; head: true; text: dev.modelData[0] }
              UiDropdown {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                width: 340
                enabled: dev.modelData[1].length > 0
                options: dev.modelData[1].map(n => pg.label(n))
                current: dev.modelData[1].indexOf(dev.modelData[2])
                onPicked: i => {
                  if (dev.index === 0) Pipewire.preferredDefaultAudioSink = dev.modelData[1][i]
                  else Pipewire.preferredDefaultAudioSource = dev.modelData[1][i]
                }
              }
            }
            VolumeRow { node: dev.modelData[2]; icon: dev.modelData[3]; visible: node !== null }
          }
        }
      }

      UiCard {
        width: col.width
        height: appCol.implicitHeight + 24
        Column {
          id: appCol
          x: 16; y: 12
          width: parent.width - 32
          spacing: 2
          UiLabel { head: true; text: "Apps"; height: 28; verticalAlignment: Text.AlignVCenter }
          UiLabel { visible: pg.apps.length === 0; dim: true; text: "Nothing is playing"; height: 28 }
          Repeater {
            model: pg.apps
            VolumeRow {
              required property var modelData
              node: modelData
              title: pg.appName(modelData)
              icon: DesktopEntries.applications.values.length, pg.appIcon(modelData)   // re-run once entries load
            }
          }
        }
      }
    }
  }
}
