// Pill button for Spotlight's pages. `accent` = the main action.
import QtQuick

Rectangle {
  id: b
  property string text
  property bool accent: false
  property bool danger: false
  signal clicked()
  implicitWidth: label.implicitWidth + 28
  implicitHeight: 32
  radius: Theme.n("btnPill", Theme.ctlPill) ? height / 2 : Theme.ctl(height)
  opacity: enabled ? 1 : 0.4
  readonly property color tint: danger ? "#e06c75" : Theme.accent
  color: accent || danger ? Qt.alpha(tint, ma.containsMouse ? 0.42 : 0.3)
       : ma.containsMouse ? Theme.chipHover : Theme.chipBg
  // plain buttons take the pack's outline (fill-less packs would lose them)
  border.width: accent || danger ? 1 : Theme.line("spBorder")
  border.color: accent || danger ? Qt.alpha(tint, 0.5) : Theme.col("spBorder", "transparent")
  Behavior on color { ColorAnimation { duration: 120 } }
  Text {
    id: label
    anchors.centerIn: parent
    text: b.text
    color: Theme.fg
    font.family: Theme.font
    font.pixelSize: 13
  }
  MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: b.clicked() }
}
