// Customize › Icons: icon theme for apps (+ ~/Themes/Icons), and — for the
// bundled Slot theme — the folder color: the accent (auto) or a fixed one.
// The shell's own icons stay Slot (its IconTheme pragma is fixed at start).
import QtQuick
import Quickshell
import Quickshell.Io
import "Commands.js" as Cmd

Item {
  id: pg
  required property var host
  implicitWidth: 640
  implicitHeight: col.implicitHeight
  readonly property string theme: host.ctx.home + "/.config/sway/scripts/theme.sh"
  readonly property string slot: "Slot-Multicolor-Dark-Icons"
  property var themes: []
  property var previews: []
  FileView { id: cur; path: pg.host.ctx.home + "/.local/state/armojidots/icons"; watchChanges: true; printErrors: false; onFileChanged: reload() }
  FileView { id: fold; path: pg.host.ctx.home + "/.local/state/armojidots/folders"; watchChanges: true; printErrors: false; onFileChanged: reload() }
  readonly property string active: cur.text().trim() || slot
  readonly property string folder: fold.text().trim()          // "" = auto

  // icon themes: an index.theme listing icon Directories (cursor-only themes don't)
  Process {
    running: true
    command: ["sh", "-c", '"$0" scan-themes; for d in ~/.local/share/icons/*/ /usr/share/icons/*/; do grep -qs "^Directories=" "$d/index.theme" && basename "$d"; done | sort -u', pg.theme]
    stdout: StdioCollector { onStreamFinished: pg.themes = text.split("\n").filter(s => s && s !== "hicolor" && s !== "default") }
  }
  // a few sample icons from the selected theme's own files
  Process {
    id: prev
    running: pg.active !== ""
    command: ["sh", "-c", 'for b in ~/.local/share/icons /usr/share/icons; do [ -d "$b/$0" ] && d="$b/$0" && break; done
      for n in folder user-home folder-download utilities-terminal text-x-generic image-x-generic; do
        find -L "$d" \\( -name "$n.svg" -o -name "$n.png" \\) 2>/dev/null | sort -r | head -n1; done', pg.active]
    stdout: StdioCollector { onStreamFinished: pg.previews = text.split("\n").filter(s => s) }
  }
  onActiveChanged: prev.running = true
  function run(args) { Quickshell.execDetached(["sh", "-c", '"$0" "$@"', theme].concat(args)) }

  Column {
    id: col
    width: parent.width
    spacing: 14
    Row {
      spacing: 16
      UiLabel { anchors.verticalCenter: parent.verticalCenter; head: true; text: "Icon theme" }
      UiDropdown {
        width: 300
        options: pg.themes
        current: pg.themes.indexOf(pg.active)
        onPicked: i => pg.run(["icons", pg.themes[i]])
      }
    }
    Row {
      spacing: 14
      Repeater {
        model: pg.previews
        Image { required property string modelData; width: 40; height: 40; sourceSize: Qt.size(80, 80); source: "file://" + modelData; asynchronous: true }
      }
    }

    Column {
      visible: pg.active === pg.slot
      width: parent.width
      spacing: 10
      UiLabel { head: true; text: "Folder color" }
      UiSegment {
        options: ["Auto (accent)", "Custom"]
        current: pg.folder ? 1 : 0
        onPicked: i => pg.run(["folders", i === 0 ? "auto" : (pg.folder || "#5480f2")])
      }
      Flow {
        visible: pg.folder !== ""
        width: parent.width
        spacing: 8
        Repeater {
          model: Object.values(Cmd.SEEDS)
          Rectangle {
            required property string modelData
            width: 28; height: 28; radius: Theme.ctl(height)
            color: modelData
            border.width: pg.folder.toLowerCase() === modelData.toLowerCase() ? 2 : 0
            border.color: Theme.fg
            MouseArea { anchors.fill: parent; onClicked: pg.run(["folders", parent.modelData.toLowerCase()]) }
          }
        }
        Rectangle {
          width: 110; height: 28; radius: Math.min(Theme.ctlRadius, height / 2)
          color: Theme.chipHover
          TextInput {
            anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
            verticalAlignment: TextInput.AlignVCenter
            text: pg.folder
            color: Theme.fg; font.family: Theme.font; font.pixelSize: 13
            maximumLength: 7
            onAccepted: if (/^#[0-9a-fA-F]{6}$/.test(text)) pg.run(["folders", text.toLowerCase()])
          }
        }
      }
    }
    Row {
      spacing: 12
      UiButton { text: "Open icons folder"; onClicked: Quickshell.execDetached(["xdg-open", pg.host.ctx.home + "/Themes/Icons"]) }
      UiLabel { anchors.verticalCenter: parent.verticalCenter; dim: true; text: "Put an icon theme's folder in ~/Themes/Icons." }
    }
  }
}
