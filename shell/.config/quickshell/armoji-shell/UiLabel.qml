// Text in the shell's font for Spotlight's pages. `dim` = secondary.
import QtQuick

Text {
  property bool dim: false
  color: dim ? Theme.muted : Theme.fg
  font.family: Theme.font
  font.pixelSize: dim ? 12 : 13
  elide: Text.ElideRight
}
