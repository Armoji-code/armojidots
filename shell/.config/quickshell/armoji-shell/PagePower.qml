// Spotlight page: power actions as big buttons. Logout, reboot and shutdown
// arm on the first click and run on the second (within 3 s).
import QtQuick
import Quickshell

Item {
  id: pw
  required property var host
  implicitWidth: row.implicitWidth
  implicitHeight: row.implicitHeight
  property string armed: ""
  Timer { id: disarm; interval: 3000; onTriggered: pw.armed = "" }

  readonly property var acts: [
    ["Lock", "system-lock-screen", "~/.config/sway/scripts/lock.sh", false],
    ["Suspend", "system-suspend", "systemctl suspend", false],
    ["Logout", "system-log-out", "swaymsg exit", true],
    ["Reboot", "system-reboot", "systemctl reboot", true],
    ["Shutdown", "system-shutdown", "systemctl poweroff", true],
  ]

  Row {
    id: row
    spacing: 12
    Repeater {
      model: pw.acts
      UiCard {
        id: b
        required property var modelData
        readonly property bool isArmed: pw.armed === modelData[0]
        width: 136
        height: 140
        hover: bMa.containsMouse
        color: isArmed ? Qt.alpha("#e06c75", 0.3) : hover ? Theme.chipHover : Theme.chipBg
        Column {
          anchors.centerIn: parent
          spacing: 10
          UiIcon { anchors.horizontalCenter: parent.horizontalCenter; name: b.modelData[1]; size: 56 }
          UiLabel { anchors.horizontalCenter: parent.horizontalCenter; text: b.isArmed ? "Click again" : b.modelData[0]; font.pixelSize: 15 }
        }
        MouseArea {
          id: bMa
          anchors.fill: parent
          hoverEnabled: true
          onClicked: {
            if (b.modelData[3] && !b.isArmed) { pw.armed = b.modelData[0]; disarm.restart(); return }
            pw.host.close()
            Quickshell.execDetached(["sh", "-c", b.modelData[2]])
          }
        }
      }
    }
  }
}
