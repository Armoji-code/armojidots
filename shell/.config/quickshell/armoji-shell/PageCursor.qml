// Customize › Cursor: installed cursor themes (and ~/Themes/Cursors) + size.
import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: pg
  required property var host
  implicitWidth: 640
  implicitHeight: col.implicitHeight
  readonly property string theme: host.ctx.home + "/.config/sway/scripts/theme.sh"
  property var themes: []
  readonly property var sizes: [24, 32, 48]
  FileView { id: cur; path: pg.host.ctx.home + "/.local/state/armojidots/cursor"; watchChanges: true; printErrors: false; onFileChanged: reload() }
  readonly property var curParts: (cur.text().trim() || "Bibata-Modern-Classic 24").split(" ")
  readonly property string active: curParts[0]
  readonly property int size: Number(curParts[1] || 24)

  Process {
    running: true
    command: ["sh", "-c", '"$0" scan-themes; for d in ~/.local/share/icons/*/ /usr/share/icons/*/; do [ -d "$d/cursors" ] && basename "$d"; done | sort -u', pg.theme]
    stdout: StdioCollector { onStreamFinished: pg.themes = text.split("\n").filter(s => s && s !== "default") }
  }
  function set(t, sz) { Quickshell.execDetached(["sh", "-c", '"$0" cursor "$1" "$2"', theme, t, String(sz)]) }

  Column {
    id: col
    width: parent.width
    spacing: 14
    UiLabel { head: true; text: "Cursor theme" }
    Flow {
      width: parent.width
      spacing: 10
      Repeater {
        model: pg.themes
        UiCard {
          id: card
          required property string modelData
          width: (col.width - 20) / 3; height: 52
          sel: modelData === pg.active
          hover: cm.containsMouse
          UiLabel { anchors { fill: parent; margins: 14 } verticalAlignment: Text.AlignVCenter; text: card.modelData.replace(/[-_]/g, " ") }
          MouseArea { id: cm; anchors.fill: parent; hoverEnabled: true; onClicked: pg.set(card.modelData, pg.size) }
        }
      }
    }
    Row {
      spacing: 12
      UiLabel { anchors.verticalCenter: parent.verticalCenter; head: true; text: "Size" }
      UiSegment {
        options: pg.sizes.map(String)
        current: Math.max(0, pg.sizes.indexOf(pg.size))
        onPicked: i => pg.set(pg.active, pg.sizes[i])
      }
    }
    Row {
      spacing: 12
      UiButton { text: "Open cursors folder"; onClicked: Quickshell.execDetached(["xdg-open", pg.host.ctx.home + "/Themes/Cursors"]) }
      UiLabel { anchors.verticalCenter: parent.verticalCenter; dim: true; text: "Put a cursor theme's folder in ~/Themes/Cursors." }
    }
  }
}
