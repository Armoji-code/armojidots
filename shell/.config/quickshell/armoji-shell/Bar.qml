// ── armojidots · bar ────────────────────────────────────────────────
// clock+media | workspaces | status. One per screen.
import QtQuick
import Quickshell
import Quickshell.Services.UPower
import Quickshell.Wayland

Variants {
  model: Quickshell.screens

  PanelWindow {
    required property var modelData
    screen: modelData
    WlrLayershell.namespace: "armoji-bar"
    WlrLayershell.layer: WlrLayer.Top
    anchors { top: true; left: true; right: true }
    margins { top: 8; left: 12; right: 12 }
    implicitHeight: Theme.chipHeight + 2 * (Theme.groupGap + Theme.line("border")) + 6
    color: "transparent"

    Group {
      anchors { left: parent.left; verticalCenter: parent.verticalCenter }
      Clock {}
      Media {}
    }

    Group {
      anchors.centerIn: parent
      Workspaces { output: modelData.name }
    }

    Group {
      anchors { right: parent.right; verticalCenter: parent.verticalCenter }
      Tray {}
      Bluetooth {}
      Network {}
      ScriptChip { script: "lang.sh"; watch: true; icon: false }
      Volume {}
      Backlight {}
      Battery {}
      ScriptChip {   // laptops only
        visible: UPower.displayDevice.isLaptopBattery
        script: "power-profile.sh"
        colors: ({ "power-saver": Theme.col("powerSaver", "#98c379"),
                   "balanced": Theme.col("powerBalanced", "fg"),
                   "performance": Theme.col("powerPerformance", "#e5977b") })
      }
      IdleInhibit {}
      ScriptChip {
        script: "bluelight.sh"
        colors: ({ "on": Theme.col("bluelightOn", "#e5a05c"),
                   "auto": Theme.col("bluelightAuto", "accent"),
                   "off": Theme.col("bluelightOff", "fg") })
      }
      Notifications {}
    }
  }
}
