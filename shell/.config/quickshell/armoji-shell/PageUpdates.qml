// Spotlight page: the update commands. Each runs in SpotTerm inside the box,
// or — with "Run in background" on — headless via Updater (update-bg.sh),
// after asking for the sudo password inline; a notification says when done.
import QtQuick
import Quickshell
import "Commands.js" as Cmd

Item {
  id: up
  required property var host
  implicitWidth: 600
  implicitHeight: col.implicitHeight
  property var pending: null           // entry waiting for the password

  function start(o) {
    if (o.kind !== "page") { up.host.close(); Quickshell.execDetached(["sh", "-c", o.value]); return }
    if (!Updater.background || !o.bg) { up.host.openPage(o.value, o.text); return }
    if (o.bg === "dotfiles") { Updater.run("dotfiles", ""); up.host.close(); return }
    pending = o; pw.text = ""; Updater.authFailed = false
    pw.forceActiveFocus()
  }
  Connections {
    target: Updater
    function onAuthOk() { if (up.pending) { up.pending = null; up.host.close() } }
    function onRunningChanged() { if (!Updater.running && Updater.authFailed) pw.forceActiveFocus() }
  }

  Column {
    id: col
    width: parent.width
    spacing: 8

    Item {
      width: parent.width; height: 34
      UiLabel { anchors.verticalCenter: parent.verticalCenter; x: 12; text: "Run in background" }
      UiLabel {
        anchors { verticalCenter: parent.verticalCenter; right: bgToggle.left; rightMargin: 12 }
        dim: true
        text: Updater.running ? "updating " + Updater.target + "…" : "notifies when done"
      }
      UiToggle {
        id: bgToggle
        anchors { verticalCenter: parent.verticalCenter; right: parent.right; rightMargin: 12 }
        checked: Updater.background
        onToggled: on => Updater.setBackground(on)
      }
    }

    // sudo password for the background run
    Column {
      visible: up.pending !== null
      width: parent.width
      spacing: 6
      Rectangle {
        width: parent.width; height: 34; radius: Math.min(Theme.ctlRadius, height / 2)
        color: Theme.chipHover
        TextInput {
          id: pw
          anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
          verticalAlignment: TextInput.AlignVCenter
          echoMode: TextInput.Password
          color: Theme.fg
          font.family: Theme.font; font.pixelSize: 13
          clip: true
          enabled: !Updater.running
          onAccepted: if (text) { Updater.run(up.pending.bg, text); text = "" }
          Keys.onEscapePressed: up.pending = null
          UiLabel {
            visible: !pw.text; anchors.verticalCenter: parent.verticalCenter; dim: true
            text: Updater.running ? "checking…" : "sudo password for " + (up.pending?.text ?? "") + " · Enter to start"
          }
        }
      }
      UiLabel { visible: Updater.authFailed; color: "#e06c75"; text: "Wrong password" }
    }

    Repeater {
      model: Cmd.update(up.host.ctx, "")
      SpotRow {
        required property var modelData
        width: up.width
        icon: up.host.iconSrc(modelData.icon)
        title: modelData.text
        on: up.pending?.bg === modelData.bg && modelData.bg !== ""
        enabled: !Updater.running
        opacity: enabled ? 1 : 0.4
        sub: modelData.kind !== "page" ? "opens Kernel Manager"
           : Updater.background && modelData.bg ? "in the background" : modelData.value.slice(5)
        onClicked: up.start(modelData)
      }
    }
  }
}
