// A list row (icon, title, subtitle) — Spotlight's results and the
// list pages share it. `on` = selected, `cursor` = keyboard cursor;
// `badge` = small text on the right.
import QtQuick

Rectangle {
  id: row
  property string icon                // icon name or file path (UiIcon)
  property string title
  property string sub
  property string badge
  property bool on: false
  property bool cursor: false
  property real ic: 30
  signal clicked()
  height: ic + 16
  radius: Theme.cardRadius
  readonly property bool sel: on
  color: sel ? Theme.selBg : cursor || ma.containsMouse ? Theme.chipHover : "transparent"
  border.width: 1
  border.color: sel || cursor ? Theme.selBorder : "transparent"
  Behavior on color { ColorAnimation { duration: 140 } }
  UiIcon {
    id: rowIcon
    x: 12
    anchors.verticalCenter: parent.verticalCenter
    name: row.icon
    size: row.ic
    color: row.sel ? Theme.selFg : Theme.fg
  }
  Column {
    anchors { left: rowIcon.right; leftMargin: 12; right: badgeText.left; rightMargin: 10; verticalCenter: parent.verticalCenter }
    Text {
      width: parent.width
      elide: Text.ElideRight
      text: row.title
      color: row.sel ? Theme.selFg : Theme.fg
      font.family: Theme.n("spTitleFont", Theme.font)
      font.pixelSize: Theme.n("spTitleSize", 15)
    }
    Text {
      visible: text !== ""
      width: parent.width
      elide: Text.ElideRight
      text: row.sub
      color: row.sel ? Qt.alpha(Theme.selFg, 0.7) : Theme.muted
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
    onClicked: row.clicked()
  }
}
