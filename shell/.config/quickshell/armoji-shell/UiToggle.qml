// On/off switch for Spotlight's pages.
import QtQuick

Rectangle {
  id: t
  property bool checked: false
  signal toggled(bool on)
  implicitWidth: 40
  implicitHeight: 22
  radius: Theme.ctl(height)
  opacity: enabled ? 1 : 0.4
  color: checked ? Qt.alpha(Theme.accent, 0.55) : Theme.chipHover
  Behavior on color { ColorAnimation { duration: 140 } }
  Rectangle {
    width: parent.height - 6; height: width; radius: Theme.inner(t.radius, 3)
    y: 3
    x: t.checked ? t.width - width - 3 : 3
    color: Theme.fg
    Behavior on x { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
  }
  MouseArea { anchors.fill: parent; onClicked: t.toggled(!t.checked) }
}
