// Spotlight page: palette swatches the style pack allows, plus a color
// picker (saturation/value square, hue strip, hex) for a custom accent —
// hidden when the pack limits palettes.
import QtQuick
import Quickshell
import Quickshell.Io
import "Commands.js" as Cmd

Item {
  id: pg
  required property var host
  implicitWidth: 640
  implicitHeight: top.height + 18 + (custom ? 170 : 16)
  readonly property string theme: host.ctx.home + "/.config/sway/scripts/theme.sh"
  readonly property var names: Cmd.palettes(host.ctx)
  readonly property bool custom: !(host.ctx.packs[host.ctx.style]?.allowed_palettes)
  FileView { id: cur; path: pg.host.ctx.home + "/.local/state/armojidots/theme"; watchChanges: true; onFileChanged: reload() }
  readonly property string active: cur.text().trim()
  FileView { id: opf; path: pg.host.ctx.home + "/.local/state/armojidots/opacity"; watchChanges: true; printErrors: false; onFileChanged: reload() }
  // no file = pack default; show the bar's alpha then
  readonly property bool opSet: opf.text().trim() !== ""
  property real op: opSet ? Number(opf.text().trim()) : Theme.bg.a
  function setOp(v) { Quickshell.execDetached(["sh", "-c", '"$0" opacity "$1"', theme, v]) }

  function apply(name) { Quickshell.execDetached(["sh", "-c", '"$0" apply "$1"', theme, name]) }

  // picker state (hsv); starts from the current accent
  property real h: Theme.accent.hsvHue < 0 ? 0 : Theme.accent.hsvHue
  property real s: Theme.accent.hsvSaturation
  property real v: Theme.accent.hsvValue
  readonly property color picked: Qt.hsva(h, s, v, 1)
  function hex(c) { return "#" + [c.r, c.g, c.b].map(x => Math.round(x * 255).toString(16).padStart(2, "0")).join("") }

  Column {
    id: top
    width: parent.width
    spacing: 10
    UiLabel { head: true; text: "Palette" }
    Flow {
      width: parent.width
      spacing: 10
      Repeater {
        model: pg.names
        Column {
          id: sw
          required property string modelData
          readonly property bool on: pg.active === modelData
          spacing: 6
          width: 74
          Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 46; height: 46; radius: Theme.ctl(46)
            color: Cmd.SEEDS[sw.modelData] ?? Theme.chipHover
            border.width: sw.on ? 3 : swMa.containsMouse ? 2 : 0
            border.color: Theme.fg
            UiLabel { visible: sw.modelData === "wallpaper"; anchors.centerIn: parent; text: "󰸉"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 20 }
            MouseArea { id: swMa; anchors.fill: parent; hoverEnabled: true; onClicked: pg.apply(sw.modelData) }
          }
          UiLabel { anchors.horizontalCenter: parent.horizontalCenter; dim: !sw.on; text: sw.modelData }
        }
      }
    }
    // surface opacity: sets bar/popup/terminal/app alphas (applied on release)
    Row {
      spacing: 10
      UiLabel { anchors.verticalCenter: parent.verticalCenter; head: true; text: "Opacity  " + (pg.opSet ? Math.round(pg.op * 100) + "%" : "pack default") }
      UiButton { visible: pg.opSet; text: "Default"; onClicked: pg.setOp("default") }
    }
    UiTrack {
      id: track
      width: parent.width; height: 22
      frac: (pg.op - 0.3) / 0.7
      MouseArea {
        anchors.fill: parent
        function set(m) { pg.op = Math.round(Math.max(0.3, Math.min(1, 0.3 + 0.7 * (m.x - track.height / 2) / (width - track.height))) * 20) / 20 }
        onPressed: m => set(m)
        onPositionChanged: m => set(m)
        onReleased: pg.setOp(String(pg.op))
      }
    }
  }

  // ── custom color ──
  Row {
    visible: pg.custom
    anchors { top: top.bottom; topMargin: 18; left: parent.left }
    spacing: 16
    // saturation (x) / value (y) for the current hue
    Rectangle {
      id: sv
      width: 260; height: 170; radius: Theme.ctlRadius
      color: Qt.hsva(pg.h, 1, 1, 1)
      Rectangle {
        anchors.fill: parent; radius: Theme.ctlRadius
        gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: "white" } GradientStop { position: 1; color: "transparent" } }
      }
      Rectangle {
        anchors.fill: parent; radius: Theme.ctlRadius
        gradient: Gradient { GradientStop { position: 0; color: "transparent" } GradientStop { position: 1; color: "black" } }
      }
      Rectangle {   // handle
        x: pg.s * sv.width - 8; y: (1 - pg.v) * sv.height - 8
        width: 16; height: 16; radius: 8
        color: pg.picked; border.width: 2; border.color: "white"
      }
      MouseArea {
        anchors.fill: parent
        function set(m) { pg.s = Math.max(0, Math.min(1, m.x / width)); pg.v = Math.max(0, Math.min(1, 1 - m.y / height)) }
        onPressed: m => set(m)
        onPositionChanged: m => set(m)
      }
    }
    // hue strip
    Rectangle {
      id: hue
      width: 22; height: 170; radius: Theme.ctl(22)
      gradient: Gradient {
        GradientStop { position: 0.0; color: "#ff0000" } GradientStop { position: 0.17; color: "#ffff00" }
        GradientStop { position: 0.33; color: "#00ff00" } GradientStop { position: 0.5; color: "#00ffff" }
        GradientStop { position: 0.67; color: "#0000ff" } GradientStop { position: 0.83; color: "#ff00ff" }
        GradientStop { position: 1.0; color: "#ff0000" }
      }
      Rectangle {
        x: -3; y: pg.h * hue.height - 4
        width: hue.width + 6; height: 8; radius: 4
        color: "transparent"; border.width: 2; border.color: "white"
      }
      MouseArea {
        anchors.fill: parent
        function set(m) { pg.h = Math.max(0, Math.min(0.999, m.y / height)) }
        onPressed: m => set(m)
        onPositionChanged: m => set(m)
      }
    }
    Column {
      spacing: 12
      UiLabel { head: true; text: "Custom accent" }
      Rectangle { width: 120; height: 60; radius: Theme.ctlRadius; color: pg.picked }
      Rectangle {
        width: 120; height: 32; radius: Math.min(Theme.ctlRadius, height / 2)
        color: Theme.chipHover
        TextInput {
          id: hexIn
          anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
          verticalAlignment: TextInput.AlignVCenter
          text: pg.hex(pg.picked)
          color: Theme.fg
          font.family: Theme.font; font.pixelSize: 13
          maximumLength: 7
          validator: RegularExpressionValidator { regularExpression: /#[0-9a-fA-F]{0,6}/ }
          onAccepted: if (/^#[0-9a-fA-F]{6}$/.test(text)) { const c = Qt.color(text); pg.h = Math.max(0, c.hsvHue); pg.s = c.hsvSaturation; pg.v = c.hsvValue }
          Keys.onEscapePressed: pg.host.back()
        }
      }
      UiButton { accent: true; text: "Apply"; onClicked: pg.apply(pg.hex(pg.picked)) }
      UiLabel { visible: pg.active.startsWith("#"); dim: true; text: "now: " + pg.active }
    }
  }
  UiLabel {
    visible: !pg.custom
    anchors { top: top.bottom; topMargin: 18 }
    dim: true
    text: "This style pack uses its own palettes only — custom colors are off."
  }
}
