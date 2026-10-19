// One pill/chip: background, hover, label, optional tooltip. Width eases
// when the text changes.
import QtQuick
import Quickshell

Rectangle {
  id: chip
  property string text
  property color fg: Theme.fg
  property color bg: Theme.chipBg
  property bool icon: false          // icon-only: a circle in round-icon packs
  property bool hoverable: true
  property real fontSize: Theme.fontSize
  property string fontFamily: Theme.font
  property string tip: ""            // tooltip (StyledText), empty = none
  readonly property bool round: icon && Theme.iconRound
  readonly property real pad: round ? 2 : Theme.chipPad
  readonly property alias hovered: mouse.containsMouse
  signal clicked(int button)
  signal scrolled(int delta)

  implicitHeight: Theme.chipHeight
  implicitWidth: Math.max(round ? implicitHeight : 0, label.implicitWidth + 2 * pad)
  radius: round ? height / 2 : Math.min(Theme.chipRadius, height / 2)
  color: hoverable && mouse.containsMouse ? Theme.chipHover : bg
  clip: true

  Behavior on implicitWidth { NumberAnimation { duration: Theme.animMs; easing.type: Easing.OutCubic } }
  Behavior on color { ColorAnimation { duration: Theme.animMs } }

  Text {
    id: label
    anchors.centerIn: parent
    text: chip.text
    color: chip.fg
    font.family: chip.fontFamily
    font.pixelSize: chip.fontSize
    font.letterSpacing: Theme.ls(chip.fontSize)
    Behavior on color { ColorAnimation { duration: Theme.animMs } }
  }

  TipHost { target: chip; text: chip.tip; hovered: chip.hovered }

  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    onClicked: e => chip.clicked(e.button)
    onWheel: w => chip.scrolled(w.angleDelta.y)
  }
}
