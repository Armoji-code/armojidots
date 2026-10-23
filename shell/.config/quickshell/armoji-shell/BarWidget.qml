// One bar widget by id (BarConfig.widgets): the registry Bar's zones load from.
import QtQuick
import Quickshell.Services.UPower

Loader {
  id: w
  required property string wid
  required property string output
  property var editor: null          // the bar's drag handler (Bar.qml) while editing
  // collapse the slot of a widget that hides itself (`shown`: empty tray, no
  // player, no battery); not `item.visible`, which reads false once we hide
  visible: item ? (item.shown ?? true) : false
  sourceComponent: ({ clock: clockC, media: mediaC, workspaces: wsC, tray: trayC, bluetooth: btC,
    network: netC, lang: langC, volume: volC, backlight: blC, battery: batC, power: powerC,
    idle: idleC, bluelight: bluelightC, notifs: notifsC })[wid] ?? null

  // edit mode: outline, and the whole widget is a drag handle (its own
  // clicks are blocked)
  Rectangle {
    visible: BarConfig.editing && w.width > 0
    anchors.fill: parent
    anchors.margins: -2
    z: 10
    radius: Math.min(Theme.chipRadius + 2, Math.min(width, height) / 2)
    color: editMa.containsMouse ? Qt.alpha(Theme.accent, 0.18) : "transparent"
    border.width: 1
    border.color: Qt.alpha(Theme.accent, 0.7)
    opacity: BarConfig.dragging === w.wid ? 0.3 : 1
    MouseArea {
      id: editMa
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
      onPressed: m => w.editor?.begin(w.wid, w, m.x, m.y)
      onPositionChanged: m => { if (pressed) w.editor?.moveTo(w, m.x, m.y) }
      onReleased: m => w.editor?.end(w, m.x, m.y)
      onCanceled: w.editor?.cancel()   // grab stolen (a popup, focus change)
    }
  }

  Component { id: clockC; Clock {} }
  Component { id: mediaC; Media {} }
  Component { id: wsC; Workspaces { output: w.output } }
  Component { id: trayC; Tray {} }
  Component { id: btC; Bluetooth {} }
  Component { id: netC; Network {} }
  Component { id: langC; ScriptChip { script: "lang.sh"; watch: true; icon: false } }
  Component { id: volC; Volume {} }
  Component { id: blC; Backlight {} }
  Component { id: batC; Battery {} }
  Component {
    id: powerC
    ScriptChip {   // laptops only
      readonly property bool shown: UPower.displayDevice.isLaptopBattery
      visible: shown
      script: "power-profile.sh"
      colors: ({ "power-saver": Theme.col("powerSaver", "#98c379"),
                 "balanced": Theme.col("powerBalanced", "fg"),
                 "performance": Theme.col("powerPerformance", "#e5977b") })
    }
  }
  Component { id: idleC; IdleInhibit {} }
  Component {
    id: bluelightC
    ScriptChip {
      script: "bluelight.sh"
      colors: ({ "on": Theme.col("bluelightOn", "#e5a05c"),
                 "auto": Theme.col("bluelightAuto", "accent"),
                 "off": Theme.col("bluelightOff", "fg") })
    }
  }
  Component { id: notifsC; Notifications {} }
}
