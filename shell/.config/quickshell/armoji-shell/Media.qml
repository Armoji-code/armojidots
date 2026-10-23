// Media pill: cava + transport + cover + title/artist. Expands in when a
// player appears, collapses when none. Cover click cycles between players.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Services.Mpris

Item {
  id: m
  property string selName: ""
  readonly property var players: Mpris.players.values
  readonly property var player: players.find(p => p.dbusName === selName)
    ?? players.find(p => p.isPlaying) ?? players[0] ?? null
  property var last: null            // keeps content while collapsing
  onPlayerChanged: if (player) last = player
  readonly property var cur: player ?? last

  // vertical bars: everything but the title stacks (cava lies on its side)
  readonly property bool vert: BarConfig.vertical
  implicitHeight: vert ? (player ? row.implicitHeight + 12 : 0) : Theme.chipHeight
  readonly property real edgeRadius: Math.min(Theme.n("mediaRadius", 999), Theme.chipHeight / 2)   // matches the pill
  implicitWidth: vert ? (player ? Theme.chipHeight : 0) : player ? pill.implicitWidth : 0
  readonly property bool shown: implicitWidth > 0.5 && implicitHeight > 0.5
  visible: shown
  opacity: player ? 1 : 0
  clip: true
  Behavior on implicitWidth { NumberAnimation { duration: Theme.animMs * 1.5; easing.type: Easing.OutCubic } }
  Behavior on implicitHeight { NumberAnimation { duration: Theme.animMs * 1.5; easing.type: Easing.OutCubic } }
  Behavior on opacity { NumberAnimation { duration: Theme.animMs } }

  component Glyph: Text {
    signal clicked
    color: Theme.fg
    font.family: Theme.font
    font.pixelSize: Theme.fontSize
    Behavior on color { ColorAnimation { duration: Theme.animMs } }
    MouseArea { anchors.fill: parent; onClicked: parent.clicked() }
  }

  Rectangle {
    id: pill
    height: parent.height
    implicitWidth: row.implicitWidth + 2 * Theme.n("mediaPad", 6)
    width: m.vert ? parent.width : implicitWidth
    radius: Math.min(Theme.n("mediaRadius", 999), Math.min(width, height) / 2)
    color: Theme.chipBg

    Grid {
      id: row
      anchors.centerIn: parent
      columns: m.vert ? 1 : 99
      rowSpacing: 6
      topPadding: m.vert ? 4 : 0   // cava's first bar off the pill's rounded top
      verticalItemAlignment: Grid.AlignVCenter
      horizontalItemAlignment: Grid.AlignHCenter

      // cava as rounded bars; media.sh prints levels 0-7 as block chars
      Item {
        id: cava
        property var levels: Array(10).fill(0)
        readonly property real barW: 3
        readonly property real maxH: Theme.chipHeight - 8
        width: m.vert ? maxH : 10 + levels.length * (barW + 2) - 2 + 6
        height: m.vert ? levels.length * (barW + 2) - 2 : maxH
        Row {
          visible: !m.vert
          x: 10
          anchors.bottom: parent.bottom
          spacing: 2
          Repeater {
            model: cava.levels.length
            Rectangle {
              required property int index
              anchors.bottom: parent?.bottom
              width: cava.barW
              height: cava.barW + (cava.maxH - cava.barW) * cava.levels[index] / 7
              radius: Math.min(pill.radius, width / 2)
              color: Theme.col("cava", "accent")
              Behavior on height { NumberAnimation { duration: 60 } }
            }
          }
        }
        Column {   // vertical bar: bars grow sideways from the centre
          visible: m.vert
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: 2
          Repeater {
            model: cava.levels.length
            Rectangle {
              required property int index
              anchors.horizontalCenter: parent?.horizontalCenter
              height: cava.barW
              width: cava.barW + (cava.maxH - cava.barW) * cava.levels[index] / 7
              radius: Math.min(pill.radius, height / 2)
              color: Theme.col("cava", "accent")
              Behavior on width { NumberAnimation { duration: 60 } }
            }
          }
        }
        Process {
          running: true
          command: ["setpriv", "--pdeathsig", "TERM", Quickshell.env("HOME") + "/.config/waybar/scripts/media.sh", "cava"]
          stdout: SplitParser {
            onRead: data => cava.levels = Array.from(data).map(ch => Math.max(0, "▁▂▃▄▅▆▇█".indexOf(ch)))
          }
        }
      }
      Glyph { text: "󰒮"; leftPadding: m.vert ? 0 : 4; rightPadding: m.vert ? 0 : 4; onClicked: m.cur?.previous() }
      Glyph {
        text: m.cur?.isPlaying ? "󰏤" : "󰐊"
        leftPadding: m.vert ? 0 : 4; rightPadding: m.vert ? 0 : 4
        color: Theme.col("playpause", "accent")
        onClicked: m.cur?.togglePlaying()
      }
      Glyph { text: "󰒭"; leftPadding: m.vert ? 0 : 4; rightPadding: m.vert ? 0 : 9; onClicked: m.cur?.next() }

      Item {
        width: 22; height: 22
        ClippingRectangle {
          width: 22; height: 22; radius: Math.min(pill.radius, 11)
          color: Theme.accentDim
          Text {
            anchors.centerIn: parent
            visible: art.status !== Image.Ready
            text: ""
            color: Theme.accent
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 11
          }
          Image {
            id: art
            anchors.fill: parent
            source: m.cur?.trackArtUrl ?? ""
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(66, 66)
            asynchronous: true
          }
        }
        MouseArea {
          anchors.fill: parent
          onClicked: {
            const ps = m.players
            if (ps.length < 2) return
            m.selName = ps[(ps.indexOf(m.cur) + 1) % ps.length].dbusName
          }
        }
      }

      Item {
        id: infoBox
        visible: !m.vert
        width: info.width; height: info.height
        MouseArea { id: infoMa; anchors.fill: parent; hoverEnabled: true; onClicked: m.cur?.togglePlaying() }
        TipHost {
          target: infoBox
          side: BarConfig.popSide
          hovered: infoMa.containsMouse
          text: (m.cur?.trackTitle ?? "") + (m.cur?.trackArtist ? " — " + m.cur.trackArtist : "")
        }
      Column {
        id: info
        leftPadding: 6; rightPadding: 4
        readonly property string title: m.cur?.trackTitle ?? ""
        onTitleChanged: fadeIn.restart()
        NumberAnimation { id: fadeIn; target: info; property: "opacity"; from: 0; to: 1; duration: Theme.animMs * 2 }
        Text {
          text: info.title
          width: Math.min(implicitWidth, 260)
          elide: Text.ElideRight
          color: Theme.fg
          font.family: Theme.n("mediaFont", Theme.font)
          font.pixelSize: Theme.n("mediaSize", 11)
        }
        Text {
          visible: text !== ""
          text: m.cur?.trackArtist ?? ""
          width: Math.min(implicitWidth, 260)
          elide: Text.ElideRight
          color: Theme.muted
          font.family: Theme.n("mediaFont", Theme.font)
          font.pixelSize: Theme.n("mediaSize", 11) - 2
        }
      }
      }
    }
  }
}
