// Spotlight page: Wi-Fi. Networks on the left (scan runs while open), the
// selected one's details and actions in the sidebar.
import QtQuick
import Quickshell.Networking

Item {
  id: pg
  required property var host
  // fits the list (40 px rows) or the sidebar, whichever is taller; the list scrolls past 440
  implicitWidth: 820
  implicitHeight: Math.max(sideCol.implicitHeight + 32, Math.min(440, 40 + nets.length * 42))
  readonly property var dev: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
  Component.onCompleted: if (dev) dev.scannerEnabled = true
  Component.onDestruction: if (dev) dev.scannerEnabled = false

  function pct(n) { return Math.round(n.signalStrength <= 1 ? n.signalStrength * 100 : n.signalStrength) }
  function icon(n) {
    const p = pct(n)
    return "network-wireless-signal-" + (p > 75 ? "excellent" : p > 50 ? "good" : p > 25 ? "ok" : "weak")
  }
  function secured(n) { return n.security !== WifiSecurityType.Open && n.security !== WifiSecurityType.Owe }
  function status(n) {
    return n.stateChanging ? (n.connected ? "Disconnecting…" : "Connecting…")
         : n.connected ? "Connected" : n.known ? "Saved" : ""
  }

  readonly property var nets: !Networking.wifiEnabled || !dev ? []
    : dev.networks.values.filter(n => n.name)
        .sort((a, b) => (b.connected - a.connected) || (b.known - a.known) || (pct(b) - pct(a)))
  property var sel: null
  onNetsChanged: if (!sel || !nets.includes(sel)) sel = nets[0] ?? null
  onSelChanged: { err = ""; pw.text = "" }
  property string err: ""
  Connections {
    target: pg.sel
    ignoreUnknownSignals: true
    function onConnectionFailed(reason) { pg.err = ConnectionFailReason.toString(reason) }
  }

  // ── left: switch + list ──
  Item {
    id: left
    anchors { left: parent.left; top: parent.top; bottom: parent.bottom; right: side.left; rightMargin: 12 }
    Row {
      id: head
      spacing: 10
      height: 32
      UiLabel { anchors.verticalCenter: parent.verticalCenter; text: "Wi-Fi" }
      UiToggle { anchors.verticalCenter: parent.verticalCenter; checked: Networking.wifiEnabled; onToggled: on => Networking.wifiEnabled = on }
      UiLabel {
        anchors.verticalCenter: parent.verticalCenter; dim: true
        text: !Networking.wifiEnabled ? "off" : pg.nets.length + " networks · scanning"
      }
    }
    ListView {
      anchors { fill: parent; topMargin: head.height + 8 }
      clip: true
      spacing: 2
      boundsBehavior: Flickable.StopAtBounds
      model: pg.nets
      delegate: SpotRow {
        required property var modelData
        width: ListView.view.width
        ic: 24
        on: pg.sel === modelData
        icon: pg.icon(modelData)
        title: modelData.name
        sub: (pg.secured(modelData) ? "󰌾 " : "") + pg.pct(modelData) + "%"
        badge: pg.status(modelData)
        onClicked: pg.sel = modelData
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
      UiIcon { name: pg.sel ? pg.icon(pg.sel) : ""; size: 48 }
      UiLabel { width: parent.width; text: pg.sel?.name ?? ""; font.pixelSize: 18 }
      Grid {
        columns: 2; columnSpacing: 14; rowSpacing: 6
        UiLabel { head: true; text: "Signal" }
        UiLabel { text: pg.sel ? pg.pct(pg.sel) + "%" : "" }
        UiLabel { head: true; text: "Security" }
        UiLabel { text: pg.sel ? (pg.secured(pg.sel) ? WifiSecurityType.toString(pg.sel.security) : "Open") : "" }
        UiLabel { head: true; text: "Status" }
        UiLabel { text: pg.sel ? (pg.status(pg.sel) || "Not connected") : "" }
      }
      // password for a new secured network
      Rectangle {
        visible: pg.sel !== null && !pg.sel.known && !pg.sel.connected && pg.secured(pg.sel)
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
          onAccepted: connectBtn.clicked()
          Keys.onEscapePressed: pg.host.back()
          UiLabel { visible: !pw.text; anchors.verticalCenter: parent.verticalCenter; dim: true; text: "Password" }
        }
      }
      UiLabel { visible: pg.err !== ""; width: parent.width; wrapMode: Text.Wrap; color: "#e06c75"; text: "Failed: " + pg.err }
      Row {
        spacing: 8
        UiButton {
          id: connectBtn
          accent: !(pg.sel?.connected ?? false)
          text: pg.sel?.connected ? "Disconnect" : "Connect"
          enabled: pg.sel !== null && !pg.sel.stateChanging
          onClicked: {
            const n = pg.sel
            pg.err = ""
            if (n.connected) n.disconnect()
            else if (n.known || !pg.secured(n)) n.connect()
            else if (pw.text) n.connectWithPsk(pw.text)
            else pw.forceActiveFocus()
          }
        }
        UiButton { visible: pg.sel?.known ?? false; text: "Forget"; danger: true; onClicked: pg.sel.forget() }
      }
    }
    UiLabel { visible: pg.sel === null; anchors.centerIn: parent; dim: true; text: "No network selected" }
  }
}
