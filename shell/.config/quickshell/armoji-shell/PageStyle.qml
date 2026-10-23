// Spotlight page: style packs as cards, plus the palette tone.
import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: pg
  required property var host
  implicitWidth: Math.min(names.length, 3) * 242 - 12   // up to 3 cards a row
  implicitHeight: col.implicitHeight
  readonly property string theme: host.ctx.home + "/.config/sway/scripts/theme.sh"
  readonly property var names: Object.keys(host.ctx.packs).sort()
  readonly property var cur: host.ctx.packs[host.ctx.style] ?? {}
  FileView { id: tone; path: pg.host.ctx.home + "/.local/state/armojidots/tone"; watchChanges: true; onFileChanged: reload() }
  readonly property var tones: ["light", "heavy", "loud"]

  function run(args) {
    Quickshell.execDetached(["sh", "-c", '"$0" "$@"', theme].concat(args))
    refresh.restart()
  }
  Timer { id: refresh; interval: 1200; onTriggered: pg.host.refreshCtx() }

  Column {
    id: col
    width: parent.width
    spacing: 18
    UiLabel { head: true; text: "Style pack" }
    Flow {
      width: parent.width
      spacing: 12
      Repeater {
        model: pg.names
        UiCard {
          id: card
          required property string modelData
          readonly property bool active: modelData === pg.host.ctx.style
          readonly property var info: pg.host.ctx.packs[modelData]
          width: 230
          height: 96
          sel: active
          hover: cardMa.containsMouse
          Column {
            anchors { fill: parent; margins: 14 }
            spacing: 6
            UiLabel { width: parent.width; text: (card.info.title || card.modelData) + (card.active ? "  ✓" : ""); font.pixelSize: 16 }
            UiLabel { width: parent.width; dim: true; wrapMode: Text.Wrap; maximumLineCount: 2; text: card.info.description || "" }
          }
          MouseArea { id: cardMa; anchors.fill: parent; hoverEnabled: true; onClicked: if (!card.active) pg.run(["style", card.modelData]) }
        }
      }
    }
    Column {
      visible: pg.cur.neutral !== "1"     // monochrome packs ignore tone
      spacing: 8
      UiLabel { head: true; text: "Tone — how strongly the palette tints everything" }
      UiSegment {
        options: ["Light", "Heavy", "Loud"]
        current: Math.max(0, pg.tones.indexOf(tone.text().trim() || "heavy"))
        onPicked: i => pg.run(["tone", pg.tones[i]])
      }
    }
  }
}
