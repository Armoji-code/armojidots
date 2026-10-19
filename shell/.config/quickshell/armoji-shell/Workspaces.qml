// Sway workspaces of this bar's output. swaysome names them 11..110 (monitor 1),
// 21..210 (monitor 2): shown as 1..10.
//
// Own slot list instead of a ListView: a vanishing workspace shrinks and then
// removes itself; one that comes back mid-shrink just grows again, so rolling
// fingers over the number row can't leave stale or duplicate buttons. Three
// layers on plain Rows (no scrolling): backgrounds < sliding highlight < numbers.
import QtQuick
import Quickshell
import Quickshell.I3

Item {
  id: wsr
  required property string output
  implicitHeight: Theme.chipHeight
  // corner of the end buttons, so the bar group can follow it
  readonly property real edgeRadius: Theme.iconRound ? Theme.chipHeight / 2 : Math.min(Theme.chipRadius, Theme.chipHeight / 2)
  implicitWidth: Math.max(0, bgRow.implicitWidth - Theme.spacing)

  readonly property var wss: I3.workspaces.values
    .filter(w => w.monitor?.name === wsr.output)
    .sort((a, b) => a.number - b.number)
  readonly property string activeName: wss.find(w => w.active)?.name ?? ""
  function ws(name) { return wss.find(w => w.name === name) ?? null }
  function label(name) { return /^\d{2,3}$/.test(name) ? name.slice(1) : name }
  function num(name) { const n = parseInt(name); return isNaN(n) ? 1e9 : n }

  ListModel { id: slots }   // role: name, leaving

  function sync() {
    const want = wss.map(w => w.name)
    for (let i = 0; i < slots.count; i++) {
      const s = slots.get(i)
      slots.setProperty(i, "leaving", !want.includes(s.name))
    }
    for (const n of want) {
      let found = false
      for (let i = 0; i < slots.count; i++) if (slots.get(i).name === n) found = true
      if (found) continue
      let at = 0
      while (at < slots.count && num(slots.get(at).name) < num(n)) at++
      slots.insert(at, { name: n, leaving: false })
    }
  }
  onWssChanged: sync()
  Component.onCompleted: sync()

  function drop(name) {
    for (let i = 0; i < slots.count; i++)
      if (slots.get(i).name === name && slots.get(i).leaving) { slots.remove(i); return }
  }


  // ── layer 1: backgrounds (+ click/hover) ──
  Row {
    id: bgRow
    Repeater {
      id: bgRep
      model: slots
      Item {
        id: d
        required property string name
        required property bool leaving
        readonly property bool act: wsr.activeName === name && !leaving
        readonly property var w: wsr.ws(name)
        // 0..1 grow factor: starts at 0, follows `leaving`, removes itself at 0
        property real f: 0
        Component.onCompleted: f = Qt.binding(() => d.leaving ? 0 : 1)
        Behavior on f { NumberAnimation { duration: Theme.animMs; easing.type: Easing.OutCubic } }
        onFChanged: if (leaving && f === 0) Qt.callLater(wsr.drop, name)
        onActChanged: if (act) hl.target = d
        TextMetrics { id: tm; text: wsr.label(d.name); font.family: Theme.font; font.pixelSize: Theme.fontSize; font.letterSpacing: Theme.ls(Theme.fontSize) }
        readonly property real fullW: Math.max(Theme.iconRound ? Theme.chipHeight : 0,
                                               tm.advanceWidth + 2 * (Theme.iconRound ? 2 : 7))
        readonly property real btnWidth: fullW * f
        width: (fullW + Theme.spacing) * f
        height: Theme.chipHeight
        opacity: f

        Rectangle {
          width: d.btnWidth
          height: parent.height
          radius: Theme.iconRound ? height / 2 : Math.min(Theme.chipRadius, height / 2)
          color: mouse.containsMouse && !d.act ? Theme.chipHover
               : d.w?.urgent ? Theme.col("wsUrgentBg", "transparent") : Theme.col("wsBg", "transparent")
          Behavior on color { ColorAnimation { duration: Theme.animMs } }
          MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; onClicked: d.w?.activate() }
        }
      }
    }
  }

  // ── layer 2: highlight, glued to the active button ──
  Rectangle {
    id: hl
    property Item target: null
    visible: target !== null
    x: target ? target.x : 0
    width: target ? target.btnWidth : 0
    height: Theme.chipHeight
    radius: Theme.iconRound ? height / 2 : Math.min(Theme.chipRadius, height / 2)
    color: Qt.alpha(Theme.col("wsActiveBg", "accent"), Theme.n("wsActiveBgAlpha", 0.35))
    Behavior on x { NumberAnimation { duration: Theme.animMs; easing.type: Easing.OutCubic } }
    Behavior on width { NumberAnimation { duration: Theme.animMs; easing.type: Easing.OutCubic } }
  }

  // ── layer 3: numbers, same widths as layer 1 so they line up ──
  Row {
    Repeater {
      model: slots
      Item {
        id: l
        required property int index
        required property string name
        // mirror the matching background item's animated width
        readonly property Item bg: { bgRep.count; return bgRep.itemAt(index) }
        readonly property real f: bg ? bg.f : 0
        readonly property var w: wsr.ws(name)
        width: bg ? bg.width : 0
        height: Theme.chipHeight
        Text {
          x: ((l.bg ? l.bg.btnWidth : 0) - width) / 2
          anchors.verticalCenter: parent.verticalCenter
          opacity: l.f
          scale: l.f
          text: wsr.label(l.name)
          color: l.w?.urgent ? Theme.col("wsUrgentFg", "#e06c75")
               : l.bg?.act ? Theme.col("wsActiveFg", "#ffffff") : Theme.col("wsFg", "muted")
          font.family: Theme.font
          font.pixelSize: Theme.fontSize
          font.letterSpacing: Theme.ls(Theme.fontSize)
          Behavior on color { ColorAnimation { duration: Theme.animMs } }
        }
      }
    }
  }
}
