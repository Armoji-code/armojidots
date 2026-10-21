// Spotlight page: the update commands; each runs in SpotTerm inside the box.
import QtQuick
import Quickshell
import "Commands.js" as Cmd

Item {
  id: up
  required property var host
  implicitWidth: 600
  implicitHeight: col.implicitHeight
  Column {
  id: col
  width: parent.width
  spacing: 8
  Repeater {
    model: Cmd.update("")
    SpotRow {
      required property var modelData
      width: up.width
      icon: up.host.iconSrc(modelData.icon)
      title: modelData.text
      sub: modelData.kind === "page" ? modelData.value.slice(5) : "opens Kernel Manager"
      onClicked: {
        if (modelData.kind === "page") up.host.openPage(modelData.value, modelData.text)
        else { up.host.close(); Quickshell.execDetached(["sh", "-c", modelData.value]) }
      }
    }
  }
}
}
