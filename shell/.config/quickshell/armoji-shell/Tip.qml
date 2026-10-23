// Hover tooltip beside a chip (`side`: below | above | left | right): fades
// and slides in. Rich text allowed.
import QtQuick
import Quickshell

PopupWindow {
  id: pw
  required property Item target
  required property string text
  property string side: "below"
  readonly property bool horiz: side === "left" || side === "right"
  anchor.item: target
  anchor.rect.x: side === "left" ? -implicitWidth - 6 : side === "right" ? target.width + 6 : (target.width - implicitWidth) / 2
  anchor.rect.y: side === "above" ? -implicitHeight - 6 : side === "below" ? target.height + 6 : (target.height - implicitHeight) / 2
  implicitWidth: box.implicitWidth + (horiz ? 6 : 0)
  implicitHeight: box.implicitHeight + (horiz ? 0 : 6)
  color: "transparent"
  visible: true

  property real t: 0
  NumberAnimation on t { from: 0; to: 1; duration: Theme.animMs; easing.type: Easing.OutCubic }

  Rectangle {
    id: box
    x: pw.side === "right" ? pw.t * 6 : pw.side === "left" ? (1 - pw.t) * 6 : 0
    y: pw.side === "below" ? pw.t * 6 : pw.side === "above" ? (1 - pw.t) * 6 : 0
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
