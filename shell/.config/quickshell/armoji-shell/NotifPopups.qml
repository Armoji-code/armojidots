// Notification toasts, top-right under the bar on the focused screen.
// The window only takes input where the cards are.
import QtQuick
import Quickshell
import Quickshell.I3
import Quickshell.Wayland

PanelWindow {
  id: win
  screen: Quickshell.screens.find(s => s.name === I3.focusedMonitor?.name) ?? Quickshell.screens[0]
  visible: Notifs.popups.length > 0
  WlrLayershell.namespace: "armoji-notif"
  WlrLayershell.layer: WlrLayer.Overlay
  anchors { top: true; right: true }
  margins { top: 8; right: 12 }
  implicitWidth: 380
  implicitHeight: Math.max(1, stack.implicitHeight)
  color: "transparent"
  mask: Region { item: stack }

  Column {
    id: stack
    width: parent.width
    spacing: 8
    Repeater {
      model: Notifs.popups
      NotifCard {
        required property var modelData
        n: modelData
        popup: true
        width: stack.width
        // slide in from the right
        x: 0
        NumberAnimation on x { from: 40; to: 0; duration: 180; easing.type: Easing.OutCubic }
        NumberAnimation on opacity { from: 0; to: 1; duration: 180 }
      }
    }
  }
}
