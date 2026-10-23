// Notification bell: count / DND state from Notifs; click = the center.
import QtQuick

Chip {
  icon: true
  text: Notifs.dnd ? "󰂛" : Notifs.count > 0 ? "󱅫" : "󰂚"
  fg: Notifs.dnd ? Theme.col("dnd", "muted")
    : Notifs.count > 0 ? Theme.col("notif", "accent") : Theme.fg
  onClicked: Notifs.toggleCenter()
}
