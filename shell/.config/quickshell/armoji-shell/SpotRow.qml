// A list row (icon, title, subtitle) — Spotlight's results and the
// list pages share it. `on` = selected; `badge` = small text on the right.
import QtQuick

Rectangle {
  id: row
  property string icon                // resolved image source
  property string title
  property string sub
  property string badge
  property bool on: false
  property real ic: 30
  signal hovered()
  signal clicked()
  height: ic + 16
  radius: Theme.cardRadius
  color: on ? Theme.col("spSel", "accent@" + Theme.n("spSelAlpha", 0.22)) : ma.containsMouse ? Qt.alpha(Theme.fg, 0.05) : "transparent"
  border.width: 1
  border.color: on ? Qt.alpha(Theme.accent, Theme.n("spSelBorderAlpha", 0.35)) : "transparent"
  Behavior on color { ColorAnimation { duration: 140 } }
  Image {
    id: rowIcon
    x: 12
    anchors.verticalCenter: parent.verticalCenter
    width: row.ic; height: row.ic
    sourceSize: Qt.size(row.ic * 2, row.ic * 2)
    fillMode: Image.PreserveAspectCrop
    source: row.icon
    asynchronous: true
  }
  Column {
    anchors { left: rowIcon.right; leftMargin: 12; right: badgeText.left; rightMargin: 10; verticalCenter: parent.verticalCenter }
    Text {
      width: parent.width
      elide: Text.ElideRight
      text: row.title
      color: row.on ? Theme.col("spSelFg", "fg") : Theme.fg
      font.family: Theme.n("spTitleFont", Theme.font)
      font.pixelSize: Theme.n("spTitleSize", 15)
    }
    Text {
      visible: text !== ""
      width: parent.width
      elide: Text.ElideRight
      text: row.sub
      color: row.on ? Qt.alpha(Theme.col("spSelFg", "fg"), 0.7) : Theme.muted
      font.family: Theme.n("spSubFont", Theme.font)
      font.pixelSize: Theme.n("spSubSize", 12)
      font.letterSpacing: Theme.ls(Theme.n("spSubSize", 12), "spSubSpacing")
    }
  }
  Text {
    id: badgeText
    anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
    text: row.badge
    color: Theme.accent
    font.family: Theme.font
    font.pixelSize: 12
  }
  MouseArea {
    id: ma
    anchors.fill: parent
    hoverEnabled: true
    onEntered: row.hovered()
    onClicked: row.clicked()
  }
}
