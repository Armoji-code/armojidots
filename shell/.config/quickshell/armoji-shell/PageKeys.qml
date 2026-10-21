// Spotlight page: keybind cheat sheet (Commands.js KEYBINDS via keys()).
import QtQuick
import "Commands.js" as Cmd

Flickable {
  id: kp
  required property var host
  readonly property var binds: Cmd.keys("")
  implicitWidth: 860
  implicitHeight: Math.min(grid.height, 440)
  contentHeight: grid.height
  clip: true
  boundsBehavior: Flickable.StopAtBounds
  Grid {
    id: grid
    width: kp.width
    columns: 2
    columnSpacing: 10
    rowSpacing: 8
    Repeater {
      model: kp.binds
      UiCard {
        required property var modelData
        width: (kp.width - 10) / 2
        height: 40
        Rectangle {
          id: chip
          x: 8; anchors.verticalCenter: parent.verticalCenter
          width: keyText.implicitWidth + 16; height: 26; radius: Theme.inner(Theme.cardRadius, 7)
          color: Qt.alpha(Theme.accent, 0.22)
          UiLabel { id: keyText; anchors.centerIn: parent; text: modelData.text }
        }
        UiLabel {
          anchors { left: chip.right; leftMargin: 12; right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
          dim: true; font.pixelSize: 13
          text: modelData.subtext
        }
      }
    }
  }
}
