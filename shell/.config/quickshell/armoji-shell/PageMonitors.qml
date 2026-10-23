// Spotlight page: monitors. Mirror (sway/scripts/mirror.sh duplicates the
// laptop panel onto externals) or Extend (drag screens on the canvas; they
// snap to each other's edges). Sidebar: the selected screen's settings.
// Apply runs it live and asks to keep it — not confirmed in 10 s → reverted;
// kept → saved to ~/.config/sway/outputs (sway includes it at startup).
import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: pg
  required property var host
  implicitWidth: 820
  implicitHeight: sc.implicitHeight + 32
  readonly property string home: host.ctx.home
  property string internal: ""   // built-in panel (eDP/LVDS/DSI), found on load
  property var ed: []        // editable copy: {name, label, enabled, w, h, r, scale, transform, adaptive, x, y, modes}
  property var orig: []      // state before the last Apply (for revert)
  property int selIdx: 0
  property bool dirty: false
  property int keepLeft: 0   // >0: waiting for "Keep"
  readonly property var sel: ed[selIdx] ?? null

  FileView { id: modeFile; path: pg.home + "/.local/state/armojidots/display-mode"; printErrors: false; watchChanges: true; onFileChanged: reload() }
  readonly property bool extend: modeFile.text().trim() === "extend"

  // ── read sway's outputs ──
  Process {
    id: reader
    running: true
    command: ["swaymsg", "-t", "get_outputs", "-r"]
    stdout: StdioCollector {
      onStreamFinished: {
        let j; try { j = JSON.parse(text) } catch (e) { return }
        pg.internal = (j.find(o => /^(eDP|LVDS|DSI)/.test(o.name)) ?? {}).name ?? ""
        pg.ed = j.map(o => {
          const m = o.current_mode ?? o.modes[0] ?? { width: 1920, height: 1080, refresh: 60000 }
          return { name: o.name, label: (o.make + " " + o.model).trim(), enabled: o.active,
                   w: m.width, h: m.height, r: m.refresh, scale: o.scale > 0 ? o.scale : 1,
                   transform: o.transform || "normal", adaptive: o.adaptive_sync_status === "enabled",
                   x: o.rect.x, y: o.rect.y, modes: o.modes }
        }).sort((a, b) => (b.name === pg.internal) - (a.name === pg.internal))
        if (pg.keepLeft === 0) pg.orig = JSON.parse(JSON.stringify(pg.ed))
        pg.selIdx = Math.min(pg.selIdx, pg.ed.length - 1)
        pg.dirty = false
      }
    }
  }
  Timer { id: reread; interval: 1500; onTriggered: reader.running = true }

  function edit(fn) { const e = JSON.parse(JSON.stringify(ed)); fn(e[selIdx], e); ed = e; dirty = true }
  function lw(o) { return (o.transform === "90" || o.transform === "270" ? o.h : o.w) / o.scale }
  function lh(o) { return (o.transform === "90" || o.transform === "270" ? o.w : o.h) / o.scale }
  function modeStr(o) { return o.w + "x" + o.h + "@" + (o.r / 1000).toFixed(3) + "Hz" }
  // externals belong to mirror.sh in mirror mode
  function managed(o) { return extend || o.name === internal }

  function swayCmds(list) {
    return list.filter(managed).map(o => o.enabled
      ? 'output "' + o.name + '" enable mode ' + modeStr(o) + " pos " + Math.round(o.x) + " " + Math.round(o.y)
        + " scale " + o.scale + " transform " + o.transform + " adaptive_sync " + (o.adaptive ? "on" : "off")
      : 'output "' + o.name + '" disable')
  }
  function run(list) {
    const cmds = swayCmds(list).map(c => "swaymsg '" + c.replace(/'/g, "") + "' >/dev/null").join("; ")
    Quickshell.execDetached(["sh", "-c", cmds + "; " + pg.home + "/.config/sway/scripts/mirror.sh apply"])
    reread.restart()
  }
  function apply() { run(ed); keepLeft = 10; countdown.start() }
  function keep() {
    countdown.stop(); keepLeft = 0
    const conf = "# Written by armoji Spotlight (/monitors).\n" + ed.filter(managed).map(o =>
      '\noutput "' + o.name + '" {\n' + (o.enabled
        ? "    mode  " + modeStr(o) + "\n    pos " + Math.round(o.x) + " " + Math.round(o.y) + "\n    transform " + o.transform
          + "\n    scale " + o.scale + "\n    adaptive_sync " + (o.adaptive ? "on" : "off") + "\n"
        : "    disable\n") + "}\n").join("")
    Quickshell.execDetached(["sh", "-c", 'printf %s "$1" > "$0"', home + "/.config/sway/outputs", conf])
    orig = JSON.parse(JSON.stringify(ed))
  }
  function revert() { countdown.stop(); keepLeft = 0; ed = JSON.parse(JSON.stringify(orig)); run(orig) }
  Timer { id: countdown; interval: 1000; repeat: true; onTriggered: if (--pg.keepLeft <= 0) pg.revert() }

  function setMode(ext) {
    Quickshell.execDetached(["sh", "-c", 'mkdir -p "$(dirname "$0")"; echo "$1" > "$0"; "$2" apply',
                             home + "/.local/state/armojidots/display-mode", ext ? "extend" : "mirror",
                             home + "/.config/sway/scripts/mirror.sh"])
    reread.restart()
  }

  // dropped at logical (x, y): snap to the nearest side of another screen,
  // then shift everything so the layout starts at 0,0
  function drop(x, y) {   // moves the selected screen
    edit((o, all) => {
      let best = null
      for (const p of all) {
        if (p === o || !p.enabled) continue
        const W = lw(o), H = lh(o), PW = lw(p), PH = lh(p)
        const cy = Math.max(p.y - H, Math.min(p.y + PH, y)), cx = Math.max(p.x - W, Math.min(p.x + PW, x))
        for (const c of [[p.x + PW, cy], [p.x - W, cy], [cx, p.y + PH], [cx, p.y - H]]) {
          // align edges when close
          if (Math.abs(c[1] - p.y) < 80) c[1] = p.y
          if (Math.abs(c[0] - p.x) < 80) c[0] = p.x
          const d = Math.hypot(c[0] - x, c[1] - y)
          if (!best || d < best.d) best = { d: d, x: c[0], y: c[1] }
        }
      }
      if (best) { o.x = best.x; o.y = best.y }
      const on = all.filter(p => p.enabled)
      const mx = Math.min(...on.map(p => p.x)), my = Math.min(...on.map(p => p.y))
      for (const p of all) { p.x = Math.round(p.x - mx); p.y = Math.round(p.y - my) }
    })
  }

  // ── top: mirror / extend ──
  Row {
    id: head
    spacing: 12
    height: 32
    UiSegment { anchors.verticalCenter: parent.verticalCenter; options: ["Mirror", "Extend"]; current: pg.extend ? 1 : 0; onPicked: i => pg.setMode(i === 1) }
    UiLabel {
      anchors.verticalCenter: parent.verticalCenter; dim: true
      text: pg.extend ? "Drag screens to arrange them" : "External screens show the laptop panel"
    }
  }

  // ── canvas ──
  UiCard {
    id: canvas
    anchors { left: parent.left; right: side.left; rightMargin: 12; top: head.bottom; topMargin: 10; bottom: bar.top; bottomMargin: 10 }
    readonly property var shown: pg.ed.filter(o => o.enabled || o.name === pg.internal)
    // mirror mode draws externals beside the panel (they really sit far away)
    function vx(o, i) { return pg.extend ? o.x : i * (pg.lw(shown[0] ?? o) + 200) }
    function vy(o) { return pg.extend ? o.y : 0 }
    readonly property real minX: Math.min(...shown.map((o, i) => vx(o, i)))
    readonly property real minY: Math.min(...shown.map(o => vy(o)))
    readonly property real bw: Math.max(...shown.map((o, i) => vx(o, i) + pg.lw(o))) - minX
    readonly property real bh: Math.max(...shown.map(o => vy(o) + pg.lh(o))) - minY
    readonly property real k: shown.length ? Math.min((width - 60) / bw, (height - 60) / bh) : 1
    readonly property real ox: (width - bw * k) / 2
    readonly property real oy: (height - bh * k) / 2

    Repeater {
      model: canvas.shown
      Rectangle {
        id: scr
        required property var modelData
        required property int index
        readonly property int edIdx: pg.ed.findIndex(o => o.name === modelData.name)
        readonly property bool on: edIdx === pg.selIdx
        function place() {
          x = Qt.binding(() => canvas.ox + (canvas.vx(scr.modelData, scr.index) - canvas.minX) * canvas.k)
          y = Qt.binding(() => canvas.oy + (canvas.vy(scr.modelData) - canvas.minY) * canvas.k)
        }
        Component.onCompleted: place()
        width: pg.lw(modelData) * canvas.k
        height: pg.lh(modelData) * canvas.k
        radius: Theme.inner(Theme.cardRadius, 4)
        color: on ? Theme.selBg : Theme.chipHover
        border.width: 1
        border.color: on ? Theme.selBorder : Qt.alpha(Theme.fg, 0.25)
        opacity: modelData.enabled ? 1 : 0.4
        Column {
          anchors.centerIn: parent
          UiLabel { anchors.horizontalCenter: parent.horizontalCenter; text: scr.modelData.name; font.pixelSize: 14 }
          UiLabel {
            anchors.horizontalCenter: parent.horizontalCenter; dim: true
            text: !pg.extend && scr.modelData.name !== pg.internal ? "mirrors " + pg.internal
                : scr.modelData.w + "×" + scr.modelData.h
          }
        }
        MouseArea {
          anchors.fill: parent
          drag.target: pg.extend && canvas.shown.length > 1 && scr.modelData.enabled ? scr : null
          property bool moved: false
          onPressed: { pg.selIdx = scr.edIdx; moved = false }
          onPositionChanged: moved = true
          onReleased: if (moved && drag.target) {
            pg.drop(canvas.minX + (scr.x - canvas.ox) / canvas.k, canvas.minY + (scr.y - canvas.oy) / canvas.k)
            scr.place()
          }
        }
      }
    }
  }

  // ── bottom: apply / keep ──
  Row {
    id: bar
    anchors { left: parent.left; bottom: parent.bottom }
    spacing: 10
    height: 32
    UiButton { visible: pg.keepLeft === 0; accent: true; text: "Apply"; enabled: pg.dirty; onClicked: pg.apply() }
    UiButton { visible: pg.keepLeft === 0 && pg.dirty; text: "Reset"; onClicked: reader.running = true }
    UiLabel { visible: pg.keepLeft > 0; anchors.verticalCenter: parent.verticalCenter; text: "Keep these settings? Reverting in " + pg.keepLeft + " s" }
    UiButton { visible: pg.keepLeft > 0; accent: true; text: "Keep"; onClicked: pg.keep() }
    UiButton { visible: pg.keepLeft > 0; text: "Revert"; onClicked: pg.revert() }
    UiButton { visible: pg.keepLeft === 0; text: "Advanced…"; onClicked: { pg.host.close(); Quickshell.execDetached([pg.home + "/.config/sway/scripts/monitors.sh"]) } }
  }

  // ── sidebar: the selected screen ──
  UiCard {
    id: side
    anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
    width: 290
    Column {
      id: sc
      visible: pg.sel !== null
      anchors { fill: parent; margins: 16 }
      spacing: 10
      readonly property bool can: pg.sel !== null && pg.managed(pg.sel)
      UiLabel { width: parent.width; text: pg.sel?.name ?? ""; font.pixelSize: 18 }
      UiLabel { width: parent.width; dim: true; text: pg.sel?.label ?? "" }
      UiLabel { visible: !sc.can; width: parent.width; wrapMode: Text.Wrap; dim: true; text: "Mirrored — switch to Extend to set this screen up." }
      Row {
        spacing: 10
        UiLabel { anchors.verticalCenter: parent.verticalCenter; text: "Enabled"; width: 90 }
        UiToggle {
          checked: pg.sel?.enabled ?? false
          // never switch off the last screen
          enabled: sc.can && !(pg.sel?.enabled && pg.ed.filter(o => o.enabled).length < 2)
          onToggled: on => pg.edit(o => o.enabled = on)
        }
      }
      // resolutions (largest first), then the refresh rates of the chosen one
      readonly property var sizes: !pg.sel ? [] : pg.sel.modes.map(m => m.width + "×" + m.height)
        .filter((v, i, a) => a.indexOf(v) === i)
      readonly property var rates: !pg.sel ? [] : pg.sel.modes.filter(m => m.width === pg.sel.w && m.height === pg.sel.h)
        .map(m => m.refresh).filter((v, i, a) => a.indexOf(v) === i).sort((a, b) => b - a)
      readonly property var scaleOpts: [1, 1.25, 1.5, 1.75, 2]
      readonly property var rots: ["normal", "90", "180", "270"]
      UiLabel { head: true; text: "Resolution" }
      UiDropdown {
        width: parent.width; enabled: sc.can
        options: sc.sizes
        current: pg.sel ? sc.sizes.indexOf(pg.sel.w + "×" + pg.sel.h) : -1
        onPicked: i => pg.edit(o => {
          const [w, h] = options[i].split("×").map(Number)
          o.w = w; o.h = h
          o.r = Math.max(...o.modes.filter(m => m.width === w && m.height === h).map(m => m.refresh))
        })
      }
      UiLabel { head: true; text: "Refresh rate" }
      UiDropdown {
        width: parent.width; enabled: sc.can
        options: sc.rates.map(r => (r / 1000).toFixed(2) + " Hz")
        current: pg.sel ? sc.rates.indexOf(pg.sel.r) : -1
        onPicked: i => { const r = sc.rates[i]; pg.edit(o => o.r = r) }
      }
      Row {
        spacing: 10
        Column {
          spacing: 6
          UiLabel { head: true; text: "Scale" }
          UiDropdown {
            width: 124; enabled: sc.can
            readonly property var opts: sc.scaleOpts
            options: opts.map(s => s.toFixed(2))
            current: pg.sel ? opts.findIndex(s => Math.abs(s - pg.sel.scale) < 0.01) : -1
            onPicked: i => { const s = opts[i]; pg.edit(o => o.scale = s) }
          }
        }
        Column {
          spacing: 6
          UiLabel { head: true; text: "Rotation" }
          UiDropdown {
            width: 124; enabled: sc.can
            readonly property var opts: sc.rots
            options: ["None", "90°", "180°", "270°"]
            current: pg.sel ? opts.indexOf(pg.sel.transform) : -1
            onPicked: i => { const t = opts[i]; pg.edit(o => o.transform = t) }
          }
        }
      }
      Row {
        spacing: 10
        UiLabel { anchors.verticalCenter: parent.verticalCenter; text: "Adaptive sync"; width: 90 }
        UiToggle { enabled: sc.can; checked: pg.sel?.adaptive ?? false; onToggled: on => pg.edit(o => o.adaptive = on) }
      }
    }
  }
}
