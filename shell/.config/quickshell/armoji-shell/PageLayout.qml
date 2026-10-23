// Spotlight page: the bar's layout (BarConfig) — mode, screen edge, and the
// button that turns on drag-to-arrange edit mode on the bar itself.
import QtQuick

Item {
  id: pg
  required property var host
  implicitWidth: 600
  implicitHeight: col.implicitHeight

  readonly property var modes: [["pills", "Floating pills"], ["pill", "One pill"], ["taskbar", "Taskbar"]]
  readonly property var edges: [["top", "Top"], ["bottom", "Bottom"], ["left", "Left"], ["right", "Right"]]

  Column {
    id: col
    width: parent.width
    spacing: 10
    Repeater {
      model: [["mode", "Style", "How the bar sits on screen", pg.modes],
              ["edge", "Position", "The screen edge it's on", pg.edges]]
      UiCard {
        required property var modelData
        width: col.width; height: 64
        Column {
          anchors { left: parent.left; leftMargin: 16; right: seg.left; rightMargin: 12; verticalCenter: parent.verticalCenter }
          spacing: 2
          UiLabel { width: parent.width; text: modelData[1]; font.pixelSize: 14 }
          UiLabel { width: parent.width; dim: true; text: modelData[2] }
        }
        UiSegment {
          id: seg
          anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
          options: modelData[3].map(o => o[1])
          current: Math.max(0, modelData[3].findIndex(o => o[0] === BarConfig[modelData[0]]))
          onPicked: i => BarConfig.set(modelData[0], modelData[3][i][0])
        }
      }
    }
    UiCard {
      width: col.width; height: 64
      Column {
        anchors { left: parent.left; leftMargin: 16; right: btns.left; rightMargin: 12; verticalCenter: parent.verticalCenter }
        spacing: 2
        UiLabel { width: parent.width; text: "Buttons"; font.pixelSize: 14 }
        UiLabel { width: parent.width; dim: true; wrapMode: Text.Wrap; maximumLineCount: 2; text: "Drag to rearrange, or into the tray to hide" }
      }
      Row {
        id: btns
        anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
        spacing: 8
        UiButton { text: "Reset"; onClicked: BarConfig.reset() }
        UiButton { text: "Edit layout"; accent: true; onClicked: { pg.host.close(); BarConfig.editing = true } }
      }
    }
  }
}
