// Spotlight page: wallpaper thumbnails (live "pipes" first); a click sets it.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets

GridView {
  id: g
  required property var host
  readonly property string dir: host.ctx.home + "/Pictures/Wallpapers"
  property string current: ""
  FileView {
    id: live
    path: g.host.ctx.home + "/.local/state/armojidots/live-wallpaper"
    watchChanges: true; printErrors: false
    onFileChanged: reload()
  }
  readonly property bool pipesOn: live.text().trim() === "pipes"
  Process {
    running: true
    command: ["readlink", "-f", g.host.ctx.home + "/dotfiles/wallpapers/current"]
    stdout: StdioCollector { onStreamFinished: g.current = text.trim() }
  }
  implicitWidth: 820
  implicitHeight: Math.min(Math.ceil(count / 4) * cellHeight, 440)
  model: ["@pipes"].concat(host.ctx.wallpapers.filter(f => /\.(jpe?g|png|webp)$/i.test(f)))
  clip: true
  boundsBehavior: Flickable.StopAtBounds
  cellWidth: width / 4
  cellHeight: cellWidth * 0.62 + 26
  delegate: Item {
    id: cell
    required property string modelData
    readonly property bool isPipes: modelData === "@pipes"
    readonly property string path: isPipes ? "pipes" : g.dir + "/" + modelData
    readonly property bool active: isPipes ? g.pipesOn : !g.pipesOn && path === g.current
    width: g.cellWidth; height: g.cellHeight
    ClippingRectangle {
      id: frame
      anchors { fill: parent; margins: 5; bottomMargin: 26 }
      radius: Theme.cardRadius
      color: Theme.chipBg
      Pipes { visible: cell.isPipes; anchors.fill: parent; cell: 8; count: 3 }
      Image {
        visible: !cell.isPipes
        anchors.fill: parent
        source: cell.isPipes ? "" : "file://" + cell.path
        sourceSize: Qt.size(320, 200)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
      }
    }
    Rectangle {   // outline above the clipped image
      anchors.fill: frame
      radius: Theme.cardRadius
      // hover: white tint over the image; current: accent tint + outline
      color: cell.active ? Theme.selBg : hov.containsMouse ? Theme.chipHover : "transparent"
      border.width: cell.active ? 2 : 0
      border.color: Theme.accent
    }
    UiLabel {
      anchors { top: frame.bottom; topMargin: 4; horizontalCenter: parent.horizontalCenter }
      width: parent.width - 10; horizontalAlignment: Text.AlignHCenter
      dim: !cell.active; text: cell.isPipes ? "pipes (live)" : cell.modelData.replace(/\.[^.]+$/, "")
    }
    MouseArea {
      id: hov
      anchors.fill: parent
      hoverEnabled: true
      onClicked: {
        g.current = cell.path
        Quickshell.execDetached([g.host.ctx.home + "/.config/sway/scripts/wallpaper-pick.sh", cell.path])
      }
    }
  }
}
