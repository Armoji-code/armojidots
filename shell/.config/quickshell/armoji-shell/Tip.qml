// Hover tooltip under a chip: fades and drops in. Rich text allowed.
import QtQuick
import Quickshell

PopupWindow {
  id: pw
  required property Item target
  required property string text
  property bool above: false
  anchor.item: target
  anchor.rect.x: (target.width - implicitWidth) / 2
  anchor.rect.y: above ? -implicitHeight - 6 : target.height + 6
  implicitWidth: box.implicitWidth
  implicitHeight: box.implicitHeight + 6
  color: "transparent"
  visible: true

  property real t: 0
  NumberAnimation on t { from: 0; to: 1; duration: Theme.animMs; easing.type: Easing.OutCubic }

  Rectangle {
    id: box
    y: pw.above ? (1 - pw.t) * 6 : (1 - pw.t) * -6 + 6
    opacity: pw.t
    implicitWidth: label.implicitWidth + 20
    implicitHeight: label.implicitHeight + 12
    radius: Math.min(Theme.n("tipRadius", Theme.chipRadius + 6), 14)
    color: Qt.alpha(Theme.bg, 0.94)
    border.width: Theme.border.a > 0 ? 1 : 0
    border.color: Theme.border
    Text {
      id: label
      anchors.centerIn: parent
      text: pw.text
      textFormat: Text.StyledText
      color: Theme.fg
      font.family: Theme.font
      font.pixelSize: Theme.fontSize
    }
  }
}
