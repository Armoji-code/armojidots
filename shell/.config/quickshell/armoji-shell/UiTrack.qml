// Slider track for Spotlight's pages: `frac` filled (0..1) in the accent; past
// `boostAt` the fill turns fg (volume boost). Packs with sliderSeg draw it
// as Nothing-style segments instead of a solid bar.
import QtQuick

Item {
  id: tr
  property real frac: 0
  property real boostAt: 1           // < 1: mark here and draw what's past it in fg
  implicitHeight: 14
  readonly property bool seg: Theme.n("sliderSeg", false)

  // solid
  Rectangle {
    visible: !tr.seg
    anchors.fill: parent
    radius: Theme.ctl(height)
    color: Theme.chipHover
    Rectangle {
      visible: tr.frac > tr.boostAt
      x: tr.width * tr.boostAt - radius; width: tr.width * tr.frac - x
      height: parent.height; radius: parent.radius
      color: Theme.fg
    }
    Rectangle {
      width: Math.max(tr.height, tr.width * Math.min(tr.frac, tr.boostAt))
      height: parent.height; radius: parent.radius
      color: Theme.accent
    }
  }
  // segments: 4px bars, 3px gaps
  Row {
    visible: tr.seg
    anchors.verticalCenter: parent.verticalCenter
    spacing: 3
    readonly property int n: Math.max(1, Math.floor((tr.width + 3) / 7))
    Repeater {
      model: tr.seg ? parent.n : 0
      Rectangle {
        required property int index
        readonly property real at: (index + 0.5) / parent.n
        width: 4; height: tr.height; radius: 1
        color: at > tr.frac ? Theme.chipHover : at > tr.boostAt ? Theme.fg : Theme.accent
      }
    }
  }
  // 100% mark
  Rectangle {
    visible: tr.boostAt < 1
    x: tr.width * tr.boostAt; y: -3
    width: 1; height: tr.height + 6
    color: Theme.muted; opacity: 0.6
  }
}
