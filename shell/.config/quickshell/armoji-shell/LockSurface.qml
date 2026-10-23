// Lock screen, one per screen. Blurred wallpaper behind an
// editorial layout: date + huge two-line clock on the left, greeting and
// password pill under it, battery and the playing track on the right.
// The password UI rests after a few seconds; any key brings it back.
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.UPower
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire

WlSessionLockSurface {
  id: s
  required property var lock
  color: Qt.alpha(Theme.bg, 1)

  readonly property real u: Math.min(width, height) / 1080      // layout unit
  readonly property string home: Quickshell.env("HOME")
  property bool awake: true
  readonly property bool leaving: lock.state === "unlocking"
  function poke() { awake = true; restT.restart() }
  Timer { id: restT; interval: 8000; running: true; onTriggered: s.awake = s.lock.buffer !== "" }

  SystemClock { id: clk; precision: SystemClock.Minutes }
  FileView { id: user; path: s.home + "/.config/armojidots/user.conf"; printErrors: false }
  readonly property string name: (user.text().match(/^NAME=(.*)$/m) ?? [])[1] ?? Quickshell.env("USER")

  // ── background: wallpaper, blurred, slowly settling in ──
  Item {
    id: bgSrc
    anchors.fill: parent
    visible: false
    Image {
      anchors.fill: parent
      source: "file://" + s.home + "/dotfiles/wallpapers/current"
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
    }
  }
  MultiEffect {
    anchors.fill: parent
    source: bgSrc
    blurEnabled: true
    blurMax: 64
    blur: 1
    saturation: 0.1
    // settles in on lock, pushes back out on unlock
    scale: s.leaving ? 1.16 : 1.08
    NumberAnimation on scale { from: 1.16; to: 1.08; duration: 420; easing.type: Easing.OutCubic }
    Behavior on scale { NumberAnimation { duration: 420; easing.type: Easing.InCubic } }
  }
  Rectangle { anchors.fill: parent; color: Qt.alpha(Theme.bg, 0.55) }
  // soft accent glow behind the clock
  Canvas {
    anchors.fill: parent
    readonly property color c: Theme.accent
    onCChanged: requestPaint()
    onPaint: {
      const g = getContext("2d"), r = Math.max(width, height) * 0.6
      const grad = g.createRadialGradient(0, height, 0, 0, height, r)
      grad.addColorStop(0, Qt.alpha(c, 0.22)); grad.addColorStop(1, Qt.alpha(c, 0))
      g.clearRect(0, 0, width, height); g.fillStyle = grad; g.fillRect(0, 0, width, height)
    }
  }

  // whole UI fades/rises in on lock
  Item {
    id: ui
    anchors.fill: parent
    opacity: 0
    NumberAnimation on opacity { to: 1; duration: 380; easing.type: Easing.OutCubic }
    NumberAnimation on scale { from: 0.96; to: 1; duration: 380; easing.type: Easing.OutCubic }
    // unlock: fade + sink back, mirroring the way in
    states: State { when: s.leaving; PropertyChanges { target: ui; opacity: 0; scale: 0.96 } }
    transitions: Transition { NumberAnimation { properties: "opacity,scale"; duration: 380; easing.type: Easing.InCubic } }

    // ── left column: date, clock, greeting, password ──
    Column {
      id: left
      x: Math.round(s.width * 0.07)
      anchors.bottom: parent.bottom
      anchors.bottomMargin: Math.round(s.height * 0.1)
      spacing: 0

      Text {
        text: Qt.formatDate(clk.date, "dddd d MMMM").toUpperCase()
        color: Theme.muted
        font.family: Theme.n("spLabelFont", Theme.font)
        font.pixelSize: Math.round(20 * s.u)
        font.letterSpacing: 4 * s.u
        bottomPadding: 6 * s.u
      }
      Text {
        text: Qt.formatTime(clk.date, "HH")
        height: font.pixelSize * 0.86      // stacked tight; font line gaps vary a lot
        color: Theme.fg
        font.family: Theme.n("numFont", Theme.font)
        font.pixelSize: Math.round(230 * s.u)
        verticalAlignment: Text.AlignVCenter
      }
      Text {
        text: Qt.formatTime(clk.date, "mm")
        height: font.pixelSize * 0.86      // stacked tight; font line gaps vary a lot
        color: Theme.accent
        font.family: Theme.n("numFont", Theme.font)
        font.pixelSize: Math.round(230 * s.u)
        verticalAlignment: Text.AlignVCenter
      }

      Item { width: 1; height: 44 * s.u }

      // greeting + password, rests after 8 s
      Column {
        id: auth
        spacing: 12 * s.u
        opacity: s.awake ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 300 } }

        Text {
          text: s.lock.state === "wrong" ? "Wrong password"
              : s.lock.state === "checking" ? "Checking…" : "Welcome back, " + s.name
          color: s.lock.state === "wrong" ? "#e06c75" : Theme.fg
          font.family: Theme.n("spTitleFont", Theme.font)
          font.pixelSize: Math.round(22 * s.u)
        }

        Rectangle {
          id: pill
          width: 420 * s.u; height: 58 * s.u
          radius: Math.min(Theme.n("spSearchRadius", 20), height / 2)
          color: Theme.col("spBg", "bgPop")
          border.width: 1
          border.color: s.lock.state === "wrong" ? Qt.alpha("#e06c75", 0.8)
                      : input.activeFocus && s.lock.buffer ? Qt.alpha(Theme.accent, 0.6) : Theme.col("spBorder", "#22ffffff")
          Behavior on border.color { ColorAnimation { duration: 150 } }

          // shake on a wrong password
          property real dx: 0
          transform: Translate { x: pill.dx }
          SequentialAnimation {
            id: shake
            NumberAnimation { target: pill; property: "dx"; to: -14; duration: 50 }
            NumberAnimation { target: pill; property: "dx"; to: 12; duration: 70 }
            NumberAnimation { target: pill; property: "dx"; to: -8; duration: 60 }
            NumberAnimation { target: pill; property: "dx"; to: 0; duration: 60 }
          }
          Connections { target: s.lock; function onFailsChanged() { shake.restart() } }

          Text {
            id: lockIcon
            x: 20 * s.u
            anchors.verticalCenter: parent.verticalCenter
            text: s.lock.state === "checking" ? "󰔟" : "󰌾"
            color: Theme.muted
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: Math.round(20 * s.u)
          }
          // one dot per character, popping in
          Row {
            anchors { left: lockIcon.right; leftMargin: 16 * s.u; verticalCenter: parent.verticalCenter }
            spacing: 8 * s.u
            Repeater {
              model: Math.min(s.lock.buffer.length, 18)
              Rectangle {
                width: 11 * s.u; height: width
                radius: Theme.ctl(height)
                color: Theme.accent
                scale: 0
                NumberAnimation on scale { to: 1; duration: 140; easing.type: Easing.OutBack }
              }
            }
          }
          Text {
            visible: s.lock.buffer === ""
            anchors { left: lockIcon.right; leftMargin: 16 * s.u; verticalCenter: parent.verticalCenter }
            text: "Type your password"
            color: Theme.muted
            font.family: Theme.n("spEntryFont", Theme.font)
            font.pixelSize: Math.round(17 * s.u)
          }
          // enter
          Rectangle {
            anchors { right: parent.right; rightMargin: 9 * s.u; verticalCenter: parent.verticalCenter }
            width: parent.height - 18 * s.u; height: width
            radius: Theme.ctl(height)
            color: s.lock.buffer ? Theme.accent : Theme.chipBg
            Behavior on color { ColorAnimation { duration: 150 } }
            Text {
              anchors.centerIn: parent
              text: "󰁔"
              color: s.lock.buffer ? Theme.onAccent : Theme.muted
              font.family: "JetBrainsMono Nerd Font"
              font.pixelSize: Math.round(18 * s.u)
            }
            MouseArea { anchors.fill: parent; onClicked: s.lock.submit() }
          }
        }
      }
    }

    // ── right column: battery, now playing ──
    Column {
      anchors { right: parent.right; rightMargin: Math.round(s.width * 0.06); bottom: parent.bottom; bottomMargin: Math.round(s.height * 0.1) }
      spacing: 14 * s.u

      Row {
        id: bat
        readonly property var dev: UPower.displayDevice
        readonly property real p: dev.percentage <= 1 ? dev.percentage * 100 : dev.percentage
        readonly property bool charging: dev.state === UPowerDeviceState.Charging || dev.state === UPowerDeviceState.FullyCharged
        visible: dev.isLaptopBattery
        anchors.right: parent.right
        spacing: 8 * s.u
        Text {
          text: bat.charging ? "󰂄" : ["󰁺", "󰁼", "󰁾", "󰂀", "󰁹"][Math.min(4, Math.floor(bat.p / 20))]
          color: bat.p <= 15 && !bat.charging ? "#e06c75" : Theme.fg
          font.family: "JetBrainsMono Nerd Font"; font.pixelSize: Math.round(20 * s.u)
          anchors.verticalCenter: parent.verticalCenter
        }
        Text {
          text: Math.round(bat.p) + "%"
          color: Theme.fg
          font.family: Theme.n("numFont", Theme.font); font.pixelSize: Math.round(20 * s.u)
          anchors.verticalCenter: parent.verticalCenter
        }
      }

      // now playing
      Rectangle {
        id: media
        readonly property var pl: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null
        visible: pl !== null
        anchors.right: parent.right
        width: 360 * s.u; height: 92 * s.u
        radius: Theme.n("spContentRadius", 16)
        color: Theme.col("spBg", "bgPop")
        border.width: Theme.line("spBorder")
        border.color: Theme.col("spBorder", "transparent")

        ClippingRectangle {
          id: art
          x: 14 * s.u; anchors.verticalCenter: parent.verticalCenter
          width: parent.height - 28 * s.u; height: width
          radius: Math.min(Theme.n("notifImgRadius", 10), width / 2)
          color: Theme.chipBg
          Image { anchors.fill: parent; source: media.pl?.trackArtUrl ?? ""; fillMode: Image.PreserveAspectCrop; asynchronous: true }
        }
        Column {
          anchors { left: art.right; leftMargin: 14 * s.u; right: ctl.left; rightMargin: 10 * s.u; verticalCenter: parent.verticalCenter }
          spacing: 3 * s.u
          Text {
            width: parent.width; elide: Text.ElideRight
            text: media.pl?.trackTitle || "Nothing playing"
            color: Theme.fg
            font.family: Theme.n("spTitleFont", Theme.font); font.pixelSize: Math.round(16 * s.u); font.weight: Font.Medium
          }
          Text {
            width: parent.width; elide: Text.ElideRight
            text: media.pl?.trackArtist ?? ""
            color: Theme.muted
            font.family: Theme.n("spSubFont", Theme.font); font.pixelSize: Math.round(13 * s.u)
          }
        }
        Row {
          id: ctl
          anchors { right: parent.right; rightMargin: 12 * s.u; verticalCenter: parent.verticalCenter }
          spacing: 2 * s.u
          Repeater {
            model: [["󰒮", () => media.pl.previous()], [media.pl?.isPlaying ? "󰏤" : "󰐊", () => media.pl.togglePlaying()], ["󰒭", () => media.pl.next()]]
            Rectangle {
              required property var modelData
              required property int index
              width: 36 * s.u; height: width
              radius: Theme.ctl(height)
              color: index === 1 ? Qt.alpha(Theme.accent, bm.containsMouse ? 0.4 : 0.28) : bm.containsMouse ? Theme.chipHover : "transparent"
              Text {
                anchors.centerIn: parent
                text: modelData[0]
                color: Theme.fg
                font.family: "JetBrainsMono Nerd Font"; font.pixelSize: Math.round(18 * s.u)
              }
              MouseArea { id: bm; anchors.fill: parent; hoverEnabled: true; onClicked: { s.poke(); parent.modelData[1]() } }
            }
          }
        }
      }
    }

    // ── volume / brightness (the OSD layer is hidden while locked) ──
    Rectangle {
      id: osd
      property string kind: "volume"
      property int value: 0
      property bool ready: false
      Timer { running: true; interval: 1000; onTriggered: osd.ready = true }
      Timer { id: osdT; interval: 1400; onTriggered: osd.opacity = 0 }
      function show(k, v) { if (!ready) return; kind = k; value = v; opacity = 1; osdT.restart() }
      readonly property var sink: Pipewire.defaultAudioSink
      PwObjectTracker { objects: [osd.sink] }
      Connections {
        target: osd.sink?.audio ?? null
        function onVolumeChanged() { osd.show("volume", Math.round(osd.sink.audio.volume * 100)) }
      }
      Connections { target: Brightness; function onCurChanged() { osd.show("brightness", Brightness.percent) } }

      anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 40 * s.u }
      width: 240 * s.u; height: 44 * s.u
      radius: Math.min(Theme.n("osdRadius", 999), height / 2)
      color: Theme.col("spBg", "bgPop")
      opacity: 0
      Behavior on opacity { NumberAnimation { duration: 160 } }
      Text {
        id: osdIcon
        x: 16 * s.u; anchors.verticalCenter: parent.verticalCenter
        text: osd.kind === "brightness" ? "󰃞" : "󰕾"
        color: Theme.accent
        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: Math.round(18 * s.u)
      }
      Rectangle {
        anchors { left: osdIcon.right; leftMargin: 12 * s.u; right: parent.right; rightMargin: 20 * s.u; verticalCenter: parent.verticalCenter }
        height: 4 * s.u; radius: height / 2
        color: Theme.chipHover
        Rectangle { height: parent.height; radius: parent.radius; width: parent.width * osd.value / 100; color: Theme.accent }
      }
    }
  }

  // screensaver on the lock too (other shell windows are hidden while
  // locked): pipes after Idle.saverMin, any input fades back to the lock
  IdleMonitor { id: idle; enabled: Idle.saverOn; timeout: Idle.saverMin * 60 }
  Rectangle {
    anchors.fill: parent
    z: 10
    color: Qt.alpha(Theme.bg, 1)
    opacity: idle.isIdle && !s.leaving ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: idle.isIdle ? 800 : 250; easing.type: Easing.OutCubic } }
    Pipes { anchors.fill: parent; running: idle.isIdle }
  }

  // keyboard: everything typed goes to the shared buffer
  Item {
    id: input
    focus: true
    Keys.onPressed: e => {
      s.poke()
      if (s.lock.state === "checking" || s.leaving) { e.accepted = true; return }
      if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) s.lock.submit()
      else if (e.key === Qt.Key_Escape) s.lock.buffer = ""
      else if (e.key === Qt.Key_Backspace) s.lock.buffer = (e.modifiers & Qt.ControlModifier) ? "" : s.lock.buffer.slice(0, -1)
      else if (e.text && e.text.charCodeAt(0) >= 32) { s.lock.buffer += e.text; s.lock.state = "" }
      else return
      e.accepted = true
    }
  }
  MouseArea { anchors.fill: parent; z: -1; hoverEnabled: true; onPositionChanged: s.poke(); onClicked: { s.poke(); input.forceActiveFocus() } }
}
