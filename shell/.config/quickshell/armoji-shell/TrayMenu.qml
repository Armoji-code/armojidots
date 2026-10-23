// A tray applet's menu drawn in the shell's style (instead of the app's
// plain Qt menu). Submenus open in place with a back row. Click outside closes.
import QtQuick
import Quickshell
import Quickshell.Widgets

PopupWindow {
  id: pw
  required property Item target
  required property var menu         // the item's QsMenuHandle
  signal done()
  property var stack: [menu]         // submenu path; last = shown
  readonly property var shown: stack[stack.length - 1]

  anchor.item: target
  anchor.rect.x: (target.width - implicitWidth) / 2
  anchor.rect.y: target.height + 8
  implicitWidth: 230
  // fixed size + mask: a popup that resizes after the menu loads stops repainting
  implicitHeight: 640
  mask: Region { item: box }
  grabFocus: true
  color: "transparent"
  visible: true
  onVisibleChanged: if (!visible) done()

  QsMenuOpener { id: op; menu: pw.shown }

  property real t: 0
  NumberAnimation on t { from: 0; to: 1; duration: Theme.animMs; easing.type: Easing.OutCubic }

  Rectangle {
    id: box
    readonly property real rowR: Math.min(Theme.chipRadius, 15)   // same corners as the bar chips
    width: parent.width
    y: (1 - pw.t) * -6
    opacity: pw.t
    height: Math.min(col.implicitHeight + 12, pw.height - 8)
    radius: rowR > 0 ? rowR + 6 : 0
    color: Qt.alpha(Theme.c.bg ?? "#121212", 0.96)
    border.width: 1
    border.color: Theme.line("spBorder") ? Theme.col("spBorder", "transparent") : Theme.chipHover

    Flickable {   // long menus scroll
      anchors { fill: parent; margins: 6 }
      contentHeight: col.implicitHeight
      clip: true
      boundsBehavior: Flickable.StopAtBounds
      Column {
        id: col
        width: parent.width

        Repeater {   // a back row first while inside a submenu
          model: (pw.stack.length > 1 ? [{ back: true }] : []).concat(Array.from(op.children.values))
          Item {
            id: e
            required property var modelData
            readonly property bool back: modelData.back === true
            readonly property bool sep: !back && modelData.isSeparator
            readonly property bool on: back || modelData.enabled
            width: col.width
            height: sep ? 9 : 30

            Rectangle {
              visible: e.sep
              anchors.centerIn: parent
              width: parent.width - 16; height: 1
              color: Theme.chipHover
            }
            Rectangle {
              visible: !e.sep
              anchors.fill: parent
              radius: box.rowR
              color: ma.containsMouse && e.on ? Theme.chipHover : "transparent"
            }
            Row {
              visible: !e.sep
              anchors { left: parent.left; leftMargin: 10; right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
              spacing: 8
              opacity: e.on ? 1 : 0.4
              // check / radio mark, app icon, or back arrow
              Text {
                readonly property int bt: e.back ? 0 : e.modelData.buttonType
                visible: e.back || bt !== QsMenuButtonType.None
                width: 16
                anchors.verticalCenter: parent.verticalCenter
                horizontalAlignment: Text.AlignHCenter
                text: e.back ? "󰅁"
                    : e.modelData.checkState === Qt.Checked ? (bt === QsMenuButtonType.RadioButton ? "󰐾" : "󰄵")
                    : (bt === QsMenuButtonType.RadioButton ? "󰄯" : "󰄱")
                color: e.back || e.modelData.checkState !== Qt.Checked ? Theme.muted : Theme.accent
                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: 15
              }
              IconImage {
                visible: !e.back && e.modelData.icon !== ""
                implicitSize: 16
                anchors.verticalCenter: parent.verticalCenter
                source: e.back ? "" : e.modelData.icon
              }
              Text {
                width: parent.width - x - (sub.visible ? sub.width + 8 : 0)
                anchors.verticalCenter: parent.verticalCenter
                text: e.back ? "Back" : e.modelData.text.replace(/_(?!_)/g, "").replace(/__/g, "_")
                elide: Text.ElideRight
                color: e.back ? Theme.muted : Theme.fg
                font.family: Theme.font
                font.pixelSize: 13
              }
            }
            Text {
              id: sub
              visible: !e.sep && !e.back && e.modelData.hasChildren
              anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
              text: "󰅂"
              color: Theme.muted
              font.family: "JetBrainsMono Nerd Font Propo"
              font.pixelSize: 14
            }
            MouseArea {
              id: ma
              anchors.fill: parent
              enabled: !e.sep && e.on
              hoverEnabled: true
              onClicked: {
                if (e.back) pw.stack = pw.stack.slice(0, -1)
                else if (e.modelData.hasChildren) pw.stack = pw.stack.concat([e.modelData])
                else { e.modelData.triggered(); pw.visible = false }
              }
            }
          }
        }
      }
    }
  }
}
