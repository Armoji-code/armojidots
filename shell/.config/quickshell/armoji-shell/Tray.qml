import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray

Rectangle {
  id: tray
  readonly property var items: SystemTray.items.values
  readonly property bool shown: items.length > 0
  visible: shown
  readonly property bool vert: BarConfig.vertical
  implicitHeight: vert ? row.implicitHeight + 2 * 8 : Theme.chipHeight
  implicitWidth: vert ? Theme.chipHeight : row.implicitWidth + 2 * Theme.chipPad
  radius: Math.min(Theme.chipRadius, Math.min(width, height) / 2)
  color: Theme.col("trayBg", "#12ffffff")

  Grid {
    id: row
    anchors.centerIn: parent
    columns: tray.vert ? 1 : Math.max(1, tray.items.length)
    spacing: 8
    Repeater {
      model: tray.items
      IconImage {
        id: ic
        required property var modelData
        implicitSize: 16
        source: modelData.icon
        TipHost {
          target: ic
          side: BarConfig.popSide
          hovered: ma.containsMouse && !menu.active
          text: [ic.modelData.tooltipTitle || ic.modelData.title, ic.modelData.tooltipDescription]
            .filter(s => s).join("<br>")
        }
        LazyLoader {
          id: menu
          TrayMenu { target: ic; menu: ic.modelData.menu; onDone: menu.active = false }
        }
        MouseArea {
          id: ma
          anchors.fill: parent
          hoverEnabled: true
          acceptedButtons: Qt.LeftButton | Qt.RightButton
          onClicked: e => {
            if (e.button === Qt.RightButton && modelData.hasMenu) menu.active = true
            else modelData.activate()
          }
        }
      }
    }
  }
}
