// Dropdown for Spotlight's pages: a button showing the value; the option
// list pops over the page (Popup closes on a click outside).
import QtQuick
import QtQuick.Controls

Rectangle {
  id: d
  property var options: []          // labels
  property int current: -1
  signal picked(int index)
  implicitWidth: 180
  implicitHeight: 32
  radius: Math.min(Theme.ctlRadius, height / 2)
  opacity: enabled ? 1 : 0.4
  color: ma.containsMouse || pop.visible ? Theme.chipHover : Theme.chipBg
  border.width: Theme.line("spBorder")
  border.color: Theme.col("spBorder", "transparent")
  Text {
    anchors { left: parent.left; leftMargin: 12; right: arrow.left; rightMargin: 6; verticalCenter: parent.verticalCenter }
    text: d.options[d.current] ?? "—"
    elide: Text.ElideRight
    color: Theme.fg
    font.family: Theme.font
    font.pixelSize: 13
  }
  Text {
    id: arrow
    anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
    text: "󰅀"
    color: Theme.muted
    font.family: "JetBrainsMono Nerd Font"
    font.pixelSize: 14
  }
  MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: pop.open() }

  Popup {
    id: pop
    y: d.height + 4
    width: d.width
    height: Math.min(list.contentHeight + 8, 240)
    padding: 4
    background: Rectangle {
      radius: Theme.ctlRadius + 4
      color: Qt.alpha(Theme.c.bg ?? "#121212", 0.96)
      border.width: 1
      border.color: Theme.chipHover
    }
    contentItem: ListView {
      id: list
      clip: true
      boundsBehavior: Flickable.StopAtBounds
      model: d.options
      Component.onCompleted: positionViewAtIndex(Math.max(0, d.current), ListView.Center)
      delegate: Rectangle {
        required property string modelData
        required property int index
        width: ListView.view.width
        height: 28
        radius: Theme.ctlRadius
        readonly property bool sel: index === d.current
        color: sel ? Theme.selBg : rowMa.containsMouse ? Theme.chipHover : "transparent"
        border.width: sel ? 1 : 0
        border.color: Theme.selBorder
        Text {
          anchors { left: parent.left; leftMargin: 9; verticalCenter: parent.verticalCenter }
          text: parent.modelData
          color: Theme.fg
          font.family: Theme.font
          font.pixelSize: 13
        }
        MouseArea {
          id: rowMa
          anchors.fill: parent
          hoverEnabled: true
          onClicked: { pop.close(); if (parent.index !== d.current) d.picked(parent.index) }
        }
      }
    }
  }
}
