// An icon for Spotlight's pages and lists: a monochrome Nerd glyph when
// Glyphs.js knows the name, else the icon theme's image (apps, files).
// `fallback`: a name whose glyph to use when `name` has none (device types).
import QtQuick
import Quickshell
import "Glyphs.js" as Glyphs

Item {
  id: ui
  property string name
  property string fallback: ""
  property real size: 30
  property color color: Theme.fg
  implicitWidth: size
  implicitHeight: size
  readonly property string glyph: Glyphs.of(name) || Glyphs.of(fallback)

  Text {
    visible: ui.glyph !== ""
    anchors.centerIn: parent
    text: ui.glyph
    color: ui.color
    font.family: "JetBrainsMono Nerd Font Propo"
    font.pixelSize: Math.round(ui.size * 0.8)
  }
  Image {
    visible: ui.glyph === ""
    anchors.fill: parent
    sourceSize: Qt.size(ui.size * 2, ui.size * 2)
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
    // iconPath(name, true) is "" when the theme lacks it (the string-fallback
    // form renders Qt's magenta "missing" pattern)
    source: ui.glyph !== "" ? "" : ui.name.startsWith("/") ? "file://" + ui.name
          : Quickshell.iconPath(ui.name, true) || Quickshell.iconPath("application-x-executable", true)
  }
}
