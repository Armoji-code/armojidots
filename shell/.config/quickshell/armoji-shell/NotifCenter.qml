// Notification center: Win+N / the bar bell. History newest first, DND,
// clear all. Esc or a click outside closes it.
import QtQuick
import Quickshell
import Quickshell.I3
import Quickshell.Wayland

LazyLoader {
  active: Notifs.centerOpen

  PanelWindow {
    id: win
    screen: Quickshell.screens.find(s => s.name === I3.focusedMonitor?.name) ?? Quickshell.screens[0]
    WlrLayershell.namespace: "armoji-notif-center"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    MouseArea { anchors.fill: parent; onClicked: Notifs.centerOpen = false }

    Rectangle {
      id: panel
      readonly property real pad: Theme.n("spContentPad", 10) + 4
      anchors { top: parent.top; right: parent.right; topMargin: 8; rightMargin: 12 }
      width: 400
      height: Math.min(parent.height - 20, head.height + Math.max(30, list.contentHeight) + 3 * pad)
      radius: Theme.n("spContentRadius", 16) + 4
      color: Theme.col("spBg", "bgPop")
      border.width: Theme.line("spBorder")
      border.color: Theme.col("spBorder", "transparent")
      focus: true
      Keys.onEscapePressed: Notifs.centerOpen = false
      MouseArea { anchors.fill: parent }   // swallow clicks

      opacity: 0
      NumberAnimation on opacity { to: 1; duration: 160; easing.type: Easing.OutCubic }
      NumberAnimation on anchors.rightMargin { from: -20; to: 12; duration: 180; easing.type: Easing.OutCubic }

      Item {
        id: head
        x: panel.pad; y: panel.pad
        width: panel.width - 2 * panel.pad; height: 32
        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: "Notifications"
          color: Theme.fg
          font.family: Theme.n("spTitleFont", Theme.font)
          font.pixelSize: 16
          font.weight: Font.Medium
        }
        Row {
          anchors { right: parent.right; verticalCenter: parent.verticalCenter }
          spacing: 10
          UiLabel { anchors.verticalCenter: parent.verticalCenter; dim: true; text: "Do not disturb" }
          UiToggle {
            anchors.verticalCenter: parent.verticalCenter
            checked: Notifs.dnd
            onToggled: on => Notifs.setDnd(on)
          }
          UiButton {
            anchors.verticalCenter: parent.verticalCenter
            height: 28
            text: "Clear"
            enabled: Notifs.count > 0
            onClicked: Notifs.clear()
          }
        }
      }

      ListView {
        id: list
        anchors { top: head.bottom; topMargin: panel.pad; left: parent.left; right: parent.right; bottom: parent.bottom
                  leftMargin: panel.pad; rightMargin: panel.pad; bottomMargin: panel.pad }
        clip: true
        spacing: 8
        model: Notifs.list
        boundsBehavior: Flickable.StopAtBounds
        delegate: NotifCard {
          required property var modelData
          n: modelData
          width: list.width
        }
        UiLabel {
          visible: Notifs.count === 0
          y: 4
          dim: true
          text: "No notifications"
        }
      }
    }
  }
}
