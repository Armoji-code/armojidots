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
  property bool numeric: false       // value part uses the pack's number font (numFont)
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

  // "<icon> <value>": icon and value drawn separately, a real gap between
  // them (nerd icons overhang their advance; Geist's space is narrow)
  readonly property var parts: {
    const m = text.match(/^([^\x00-\x7F]+) (.+)$/)
    return m ? [m[1], m[2]] : ["", text]
  }
  // Each piece is centred by its visible glyphs, not its font's line box:
  // Nerd icons, Geist and the dot-matrix font have very different
  // ascent/descent, so line-box centring left them at crooked heights.
  // (tightBoundingRect.y is relative to the baseline, negative = above it)
  function glyphY(t, r) { return Math.round(chip.height / 2 - (t.baselineOffset + r.y + r.height / 2)) }
  Row {
    id: label
    anchors.horizontalCenter: parent.horizontalCenter
    height: chip.height
    spacing: chip.parts[0] ? chip.fontSize * 0.55 : 0
    Text {
      id: iconT
      visible: text !== ""
      y: chip.glyphY(iconT, iconM.tightBoundingRect)
      text: chip.parts[0]
      color: chip.fg
      font.family: chip.fontFamily
      font.pixelSize: chip.fontSize
      Behavior on color { ColorAnimation { duration: Theme.animMs } }
      TextMetrics { id: iconM; font: iconT.font; text: iconT.text }
    }
    Text {
      id: valT
      y: chip.glyphY(valT, valM.tightBoundingRect)
      text: chip.parts[1]
      color: chip.fg
      font.family: chip.numeric ? Theme.n("numFont", chip.fontFamily) : chip.fontFamily
      font.pixelSize: chip.fontSize
      font.letterSpacing: Theme.ls(chip.fontSize)
      Behavior on color { ColorAnimation { duration: Theme.animMs } }
      TextMetrics { id: valM; font: valT.font; text: valT.text }
    }
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
