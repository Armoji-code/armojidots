// Segmented choice (one of a few options) for Spotlight's pages.
import QtQuick

Rectangle {
  id: s
  property var options: []          // labels
  property int current: 0
  signal picked(int index)
  implicitWidth: row.implicitWidth + 6
  implicitHeight: 30
  radius: Theme.ctl(height)
  color: Theme.chipBg
  border.width: Theme.line("spBorder")
  border.color: Theme.col("spBorder", "transparent")
  Rectangle {          // sliding highlight
    readonly property Item at: { rep.count; return rep.itemAt(s.current) }   // re-evaluate once the Repeater fills
    visible: at !== null
    x: 3 + (at?.x ?? 0); y: 3
    width: at?.width ?? 0; height: s.height - 6
    radius: Theme.inner(s.radius, 3)
    color: Theme.selBg
    border.width: 1
    border.color: Theme.selBorder
    Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
    Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
  }
  Row {
    id: row
    x: 3; y: 3
    Repeater {
      id: rep
      model: s.options
      Item {
        required property string modelData
        required property int index
        width: lbl.implicitWidth + 24; height: s.height - 6
        Text {
          id: lbl
          anchors.centerIn: parent
          text: parent.modelData
          color: s.current === parent.index ? Theme.fg : Theme.muted
          font.family: Theme.font
          font.pixelSize: 13
        }
        MouseArea { anchors.fill: parent; onClicked: s.picked(parent.index) }
      }
    }
  }
}
