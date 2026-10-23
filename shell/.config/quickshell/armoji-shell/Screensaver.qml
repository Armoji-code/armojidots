// Screensaver: pipes.sh (Pipes.qml) over every screen after Idle.saverMin idle
// (while locked, LockSurface shows it instead).
// Any input ends it. On/off and delay: the Idle page.
import QtQuick
import Quickshell
import Quickshell.Wayland

Scope {
  id: ss
  property bool locked: false
  IdleMonitor { id: idle; enabled: Idle.saverOn; timeout: Idle.saverMin * 60 }
  readonly property bool on: idle.isIdle && !locked
  // windows outlive `on` by the fade-out
  property bool mapped: false
  onOnChanged: if (on) mapped = true; else unmapT.restart()
  Timer { id: unmapT; interval: 300; onTriggered: ss.mapped = ss.on }

  Variants {
    model: ss.mapped ? Quickshell.screens : []
    PanelWindow {
      required property var modelData
      screen: modelData
      WlrLayershell.namespace: "armoji-screensaver"
      WlrLayershell.layer: WlrLayer.Overlay
      exclusionMode: ExclusionMode.Ignore
      anchors { top: true; bottom: true; left: true; right: true }
      color: "transparent"
      Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Theme.bg, 1)
        opacity: 0
        Component.onCompleted: opacity = Qt.binding(() => ss.on ? 1 : 0)
        Behavior on opacity { NumberAnimation { duration: ss.on ? 800 : 250; easing.type: Easing.OutCubic } }
        Pipes { anchors.fill: parent; running: ss.on }
      }
    }
  }
}
