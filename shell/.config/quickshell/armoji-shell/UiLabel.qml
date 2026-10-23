// Text in the shell's font for Spotlight's pages. `dim` = secondary.
// `head` = a section / field label: mono ALL CAPS when the pack sets capsHeads.
import QtQuick

Text {
  property bool dim: false
  property bool head: false
  readonly property bool caps: head && Theme.n("capsHeads", false)
  color: dim || head ? Theme.muted : Theme.fg
  font.family: caps ? Theme.n("spSubFont", Theme.font) : Theme.font
  font.pixelSize: caps ? 10 : dim || head ? 12 : 13
  font.capitalization: caps ? Font.AllUppercase : Font.MixedCase
  font.letterSpacing: caps ? 1.4 : 0
  elide: Text.ElideRight
}
