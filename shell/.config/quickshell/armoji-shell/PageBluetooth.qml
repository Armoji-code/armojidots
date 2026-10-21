// Spotlight page: Bluetooth. Devices on the left (discovery runs while
// open), the selected one's details and actions in the sidebar.
import QtQuick
import Quickshell.Bluetooth

Item {
  id: pg
  required property var host
  implicitWidth: 820
  implicitHeight: Math.max(sideCol.implicitHeight + 32, Math.min(440, 40 + col.implicitHeight))
  readonly property var ad: Bluetooth.defaultAdapter
  Component.onCompleted: if (ad?.enabled) ad.discovering = true
  Component.onDestruction: if (ad) ad.discovering = false

  // device type from its freedesktop icon name
  readonly property var types: ({ "audio-headset": "Headset", "audio-headphones": "Headphones",
    "audio-card": "Speaker", "input-mouse": "Mouse", "input-keyboard": "Keyboard", "input-gaming": "Game controller",
    "input-tablet": "Tablet", "phone": "Phone", "computer": "Computer", "video-display": "Display",
    "camera-photo": "Camera", "printer": "Printer", "network-wireless": "Network" })
  function kind(d) { return types[d.icon] ?? "Device" }
  function status(d) {
    return d.pairing ? "Pairing…" : d.state === BluetoothDeviceState.Connecting ? "Connecting…"
         : d.state === BluetoothDeviceState.Disconnecting ? "Disconnecting…"
         : d.connected ? "Connected" : d.paired ? "Paired" : ""
  }
  function busy(d) { return d.pairing || d.state === BluetoothDeviceState.Connecting || d.state === BluetoothDeviceState.Disconnecting }

  // nameless nearby devices only show their MAC address: skip them
  readonly property var devs: !ad?.enabled ? []
    : ad.devices.values.filter(d => d.paired || !/^([0-9A-F]{2}[-:]){5}[0-9A-F]{2}$/i.test(d.name))
        .sort((a, b) => (b.paired - a.paired) || (b.connected - a.connected) || a.name.localeCompare(b.name))
  property var sel: null
  onDevsChanged: if (!sel || !devs.includes(sel)) sel = devs[0] ?? null

  // ── left: switches + list ──
  Item {
    anchors { left: parent.left; top: parent.top; bottom: parent.bottom; right: side.left; rightMargin: 12 }
    Row {
      id: head
      spacing: 10
      height: 32
      UiLabel { anchors.verticalCenter: parent.verticalCenter; text: "Bluetooth" }
      UiToggle {
        anchors.verticalCenter: parent.verticalCenter
        enabled: pg.ad !== null
        checked: pg.ad?.enabled ?? false
        onToggled: on => { pg.ad.enabled = on; if (on) pg.ad.discovering = true }
      }
      Item { width: 10; height: 1 }
      UiLabel { anchors.verticalCenter: parent.verticalCenter; text: "Visible" }
      UiToggle {
        anchors.verticalCenter: parent.verticalCenter
        enabled: pg.ad?.enabled ?? false
        checked: pg.ad?.discoverable ?? false
        onToggled: on => pg.ad.discoverable = on
      }
      UiLabel { anchors.verticalCenter: parent.verticalCenter; dim: true; text: pg.ad?.discovering ? "· scanning" : "" }
    }
    Flickable {
      anchors { fill: parent; topMargin: head.height + 8 }
      clip: true
      contentHeight: col.height
      boundsBehavior: Flickable.StopAtBounds
      Column {
        id: col
        width: parent.width
        spacing: 2
        Repeater {
          model: [["My devices", true], ["Nearby", false]]
          Column {
            id: sec
            required property var modelData
            readonly property var list: pg.devs.filter(d => d.paired === modelData[1])
            width: col.width
            spacing: 2
            visible: list.length > 0
            UiLabel { height: 26; verticalAlignment: Text.AlignVCenter; leftPadding: 4; dim: true; text: sec.modelData[0] }
            Repeater {
              model: sec.list
              SpotRow {
                required property var modelData
                width: sec.width
                ic: 24
                on: pg.sel === modelData
                icon: pg.host.iconSrc(modelData.icon || "bluetooth")
                title: modelData.name
                sub: pg.kind(modelData) + (modelData.batteryAvailable ? " · " + Math.round(modelData.battery * 100) + "%" : "")
                badge: pg.status(modelData)
                onClicked: pg.sel = modelData
              }
            }
          }
        }
      }
    }
  }

  // ── right: details + actions ──
  UiCard {
    id: side
    anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
    width: 290
    Column {
      id: sideCol
      visible: pg.sel !== null
      anchors { fill: parent; margins: 16 }
      spacing: 10
      Image {
        width: 48; height: 48
        sourceSize: Qt.size(96, 96)
        source: pg.sel ? pg.host.iconSrc(pg.sel.icon || "bluetooth") : ""
      }
      UiLabel { width: parent.width; text: pg.sel?.name ?? ""; font.pixelSize: 18 }
      Grid {
        columns: 2; columnSpacing: 14; rowSpacing: 6
        UiLabel { dim: true; text: "Type" }
        UiLabel { text: pg.sel ? pg.kind(pg.sel) : "" }
        UiLabel { dim: true; text: "Address" }
        UiLabel { text: pg.sel?.address ?? "" }
        UiLabel { dim: true; text: "Battery"; visible: pg.sel?.batteryAvailable ?? false }
        UiLabel { text: pg.sel ? Math.round(pg.sel.battery * 100) + "%" : ""; visible: pg.sel?.batteryAvailable ?? false }
        UiLabel { dim: true; text: "Status" }
        UiLabel { text: pg.sel ? (pg.status(pg.sel) || "Not paired") : "" }
      }
      Row {
        spacing: 10
        visible: pg.sel?.paired ?? false
        UiLabel { anchors.verticalCenter: parent.verticalCenter; text: "Trusted (auto-connect)" }
        UiToggle { anchors.verticalCenter: parent.verticalCenter; checked: pg.sel?.trusted ?? false; onToggled: on => pg.sel.trusted = on }
      }
      Flow {
        width: parent.width
        spacing: 8
        UiButton {
          visible: pg.sel?.paired ?? false
          accent: !(pg.sel?.connected ?? false)
          enabled: pg.sel !== null && !pg.busy(pg.sel)
          text: pg.sel?.connected ? "Disconnect" : "Connect"
          onClicked: pg.sel.connected ? pg.sel.disconnect() : pg.sel.connect()
        }
        UiButton {
          visible: pg.sel !== null && !pg.sel.paired
          accent: true
          enabled: pg.sel !== null && !pg.busy(pg.sel)
          text: "Pair"
          onClicked: { pg.sel.trusted = true; pg.sel.pair() }
        }
        UiButton { visible: pg.sel?.pairing ?? false; text: "Cancel"; onClicked: pg.sel.cancelPair() }
        UiButton { visible: pg.sel?.paired ?? false; danger: true; text: "Forget"; onClicked: pg.sel.forget() }
      }
    }
    UiLabel { visible: pg.sel === null; anchors.centerIn: parent; dim: true; text: pg.ad?.enabled ? "No device selected" : "Bluetooth is off" }
  }
}
