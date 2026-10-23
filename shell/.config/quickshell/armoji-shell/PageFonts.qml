// Customize › Fonts: three roles, each the style's default or any installed
// family. A style switch resets them (theme.sh). ~/Themes/Fonts is scanned.
import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: pg
  required property var host
  implicitWidth: 640
  implicitHeight: col.implicitHeight
  readonly property string theme: host.ctx.home + "/.config/sway/scripts/theme.sh"
  property var all: []
  property var mono: []
  property var over: ({})            // role → family (overrides only)

  FileView {
    path: pg.host.ctx.home + "/.local/state/armojidots/fonts"
    watchChanges: true; printErrors: false
    onFileChanged: reload()
    onLoaded: { const o = {}; for (const l of text().split("\n")) { const i = l.indexOf("="); if (i > 0) o[l.slice(0, i)] = l.slice(i + 1) } pg.over = o }
    onLoadFailed: pg.over = ({})
  }
  // ~/Themes linked + fc-cache first, so dropped-in fonts show up
  Process {
    running: true
    command: ["sh", "-c", '"$0" scan-themes; fc-cache ~/Themes/Fonts; fc-list : family | cut -d, -f1 | sort -u; echo @@; fc-list :spacing=100 family | cut -d, -f1 | sort -u', pg.theme]
    stdout: StdioCollector {
      onStreamFinished: { const [a, m] = text.split("@@\n"); pg.all = a.split("\n").filter(s => s); pg.mono = (m || "").split("\n").filter(s => s) }
    }
  }
  function set(role, family) { Quickshell.execDetached(["sh", "-c", '"$0" font "$1" "$2"', theme, role, family]) }

  Column {
    id: col
    width: parent.width
    spacing: 14
    Repeater {
      model: [["ui", "Interface", "Shell, menus and apps", pg.all, Theme.font],
              ["mono", "Monospace", "Terminals and code", pg.mono, Theme.n("termFont", "JetBrainsMono Nerd Font")],
              ["display", "Display", "Bar and lock-screen clock", pg.all, Theme.n("clockFont", Theme.font)]]
      Row {
        required property var modelData
        width: col.width
        spacing: 16
        Column {
          width: 200
          spacing: 2
          anchors.verticalCenter: parent.verticalCenter
          UiLabel { text: modelData[1]; font.pixelSize: 14 }
          UiLabel { dim: true; text: modelData[2] }
        }
        Column {
          width: parent.width - 216
          spacing: 6
          UiDropdown {
            width: parent.width
            fontPreview: true
            options: ["Style default"].concat(modelData[3])
            current: pg.over[modelData[0]] ? Math.max(0, options.indexOf(pg.over[modelData[0]])) : 0
            onPicked: i => pg.set(modelData[0], i === 0 ? "default" : options[i])
          }
          Text {
            text: modelData[0] === "display" ? "12:34  0123456789" : "The quick brown fox jumps over the lazy dog"
            color: Theme.muted
            font.family: pg.over[modelData[0]] || modelData[4]
            font.pixelSize: 15
            elide: Text.ElideRight
            width: parent.width
          }
        }
      }
    }
    Row {
      spacing: 8
      UiButton { text: "Open fonts folder"; onClicked: Quickshell.execDetached(["xdg-open", pg.host.ctx.home + "/Themes/Fonts"]) }
      UiButton { text: "Reset to style"; enabled: Object.keys(pg.over).length > 0
        onClicked: Quickshell.execDetached(["sh", "-c", 'for r in ui mono display; do "$0" font $r default; done', pg.theme]) }
    }
    UiLabel { dim: true; text: "Drop .ttf / .otf files in ~/Themes/Fonts — they're available to every app." }
  }
}
