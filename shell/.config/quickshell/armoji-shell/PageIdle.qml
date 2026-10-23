// Spotlight page: what happens when the computer sits idle (Idle.qml).
import QtQuick

Item {
  id: pg
  required property var host
  implicitWidth: 600
  implicitHeight: col.implicitHeight

  Column {
    id: col
    width: parent.width
    spacing: 10
    Repeater {
      model: [["saverOn", "saverMin", "Screensaver", "Pipes in your colors", [1, 2, 5, 10]],
              ["lockOn", "lockMin", "Auto-lock", "Also the bar's lock button", [5, 10, 15, 30]],
              ["offOn", "offMin", "Screen off", "Displays sleep until input", [5, 10, 15, 30]]]
      UiCard {
        required property var modelData
        width: col.width; height: 64
        Column {
          anchors { left: parent.left; leftMargin: 16; verticalCenter: parent.verticalCenter }
          spacing: 2
          UiLabel { text: modelData[2]; font.pixelSize: 14 }
          UiLabel { dim: true; text: modelData[3] }
        }
        Row {
          anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
          spacing: 14
          UiSegment {
            anchors.verticalCenter: parent.verticalCenter
            enabled: Idle[modelData[0]]
            opacity: enabled ? 1 : 0.4
            options: modelData[4].map(m => m + " min")
            current: Math.max(0, modelData[4].indexOf(Idle[modelData[1]]))
            onPicked: i => Idle.set(modelData[1], modelData[4][i])
          }
          UiToggle {
            anchors.verticalCenter: parent.verticalCenter
            checked: Idle[modelData[0]]
            onToggled: on => Idle.set(modelData[0], on)
          }
        }
      }
    }
    UiLabel { dim: true; text: "Fullscreen video holds all of these off. The screen always locks before sleep." }
  }
}
