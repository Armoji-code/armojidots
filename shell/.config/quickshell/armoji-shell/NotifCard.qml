// One notification: image, summary, app · time, ×, body, action chips.
// Used by the popups (auto-hide timer, hover pauses it) and the center.
// Styled with the Spotlight tokens, so each style pack themes it.
import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets

Rectangle {
  id: card
  required property var n
  property bool popup: false
  readonly property bool critical: n.urgency === NotificationUrgency.Critical
  readonly property real pad: Theme.n("spContentPad", 10) + 4

  implicitHeight: body.implicitHeight + 2 * pad
  radius: Theme.n("spContentRadius", 16)
  color: popup ? Theme.col("spBg", "bgPop") : ma.containsMouse ? Theme.chipHover : Theme.chipBg
  border.width: critical ? 1 : popup ? Theme.line("spBorder") : 0
  border.color: critical ? Qt.alpha("#e06c75", 0.7) : Theme.col("spBorder", "transparent")
  Behavior on color { ColorAnimation { duration: 120 } }

  // popups: 6 s (low 3 s, critical stays; the app's own timeout wins)
  Timer {
    running: card.popup && !card.critical && !ma.containsMouse
    interval: card.n.expireTimeout > 0 ? card.n.expireTimeout   // ms, as sent
            : card.n.urgency === NotificationUrgency.Low ? 3000 : 6000
    onTriggered: card.n.transient ? card.n.expire() : Notifs.hidePopup(card.n)
  }

  MouseArea {
    id: ma
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
    onClicked: e => e.button === Qt.MiddleButton ? card.n.dismiss() : Notifs.activate(card.n)
  }

  // image left; text column: [summary · app · time  ×] / body / actions.
  // A short card centers the image on the text, a tall one keeps it at the top.
  Item {
    id: body
    x: card.pad; y: card.pad
    width: card.width - 2 * card.pad
    implicitHeight: Math.max(pic.visible ? pic.height : 0, col.implicitHeight)

    ClippingRectangle {
      id: pic
      readonly property string src: card.n.image || (card.n.appIcon.startsWith("/") ? "file://" + card.n.appIcon
                                     : Quickshell.iconPath(card.n.appIcon || card.n.desktopEntry, true))
      visible: src !== ""
      width: 40; height: 40
      y: col.implicitHeight > height + 8 ? 0 : (body.height - height) / 2
      // per style pack: terminal square, aqua/nothing rounded square, material circle
      radius: Math.min(Theme.n("notifImgRadius", 10), height / 2)
      color: "transparent"
      Image {
        anchors.fill: parent
        source: pic.src
        sourceSize: Qt.size(80, 80)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
      }
    }

    Column {
      id: col
      x: pic.visible ? pic.width + 12 : 0
      y: pic.visible && implicitHeight < pic.height ? (body.height - implicitHeight) / 2 : 0
      width: body.width - x
      spacing: 3

      Item {
        id: title
        // a leading icon apps put in the summary is drawn apart (see Notifs.splitIcon)
        readonly property var parts: Notifs.splitIcon(card.n.summary || card.n.appName)
        width: parent.width; height: Math.max(sumText.implicitHeight, close.height)
        Text {
          id: sumIcon
          visible: text !== ""
          anchors.verticalCenter: parent.verticalCenter
          text: title.parts[0]
          color: Theme.fg
          font.family: "JetBrainsMono Nerd Font Propo"
          font.pixelSize: Theme.n("spTitleSize", 14)
        }
        Text {
          id: sumText
          anchors { left: sumIcon.visible ? sumIcon.right : parent.left; leftMargin: sumIcon.visible ? 6 : 0
                    right: meta.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
          elide: Text.ElideRight
          text: title.parts[1]
          color: Theme.fg
          font.family: Theme.n("spTitleFont", Theme.font)
          font.pixelSize: Theme.n("spTitleSize", 14)
          font.weight: Font.Medium
        }
        // "Firefox · 2m" — scripts' generic sender name isn't worth showing
        Text {
          id: meta
          anchors { right: close.left; rightMargin: 4; verticalCenter: parent.verticalCenter }
          readonly property string app: /^(notify-send|)$/.test(card.n.appName) || !card.n.summary ? "" : card.n.appName
          text: (app ? app + " · " : "") + Notifs.ago(card.n)
          color: Theme.muted
          font.family: Theme.n("spLabelFont", Theme.font)
          font.pixelSize: Theme.n("spLabelSize", 11)
          font.letterSpacing: Theme.ls(Theme.n("spLabelSize", 11), "spLabelSpacing")
        }
        Rectangle {
          id: close
          anchors { right: parent.right; verticalCenter: parent.verticalCenter }
          width: 26; height: 26
          radius: Theme.ctl(height)
          color: closeMa.containsMouse ? Theme.chipHover : "transparent"
          Text {
            anchors.centerIn: parent
            text: "󰅖"
            color: closeMa.containsMouse ? Theme.fg : Theme.muted
            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16
          }
          MouseArea { id: closeMa; anchors.fill: parent; anchors.margins: -3; hoverEnabled: true; onClicked: card.n.dismiss() }
        }
      }
      Text {
        width: parent.width - close.width
        visible: text !== ""
        text: card.n.body
        textFormat: Text.StyledText
        wrapMode: Text.Wrap
        maximumLineCount: card.popup ? 3 : 6
        elide: Text.ElideRight
        color: Qt.alpha(Theme.fg, 0.8)
        font.family: Theme.n("spSubFont", Theme.font)
        font.pixelSize: Theme.n("spSubSize", 12)
        onLinkActivated: link => Qt.openUrlExternally(link)
      }
      Flow {
        width: parent.width
        visible: acts.count > 0
        spacing: 6
        topPadding: 6
        Repeater {
          id: acts
          model: card.n.actions.filter(a => a.identifier !== "default")
          UiButton {
            required property var modelData
            height: 28
            text: modelData.text
            onClicked: modelData.invoke()
          }
        }
      }
    }
  }
}
