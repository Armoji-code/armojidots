// ── armojidots · bar ────────────────────────────────────────────────
// Three zones (start | middle | end) of widgets, laid out by BarConfig:
//   pills    one floating pill per zone (default)
//   pill     one floating pill holding all three
//   taskbar  a flat bar attached to the screen edge
// on any edge. One per screen. Edit mode (Spotlight › Layout): widgets are
// dragged between zones and a "hidden" tray that opens beside the bar.
import QtQuick
import Quickshell
import Quickshell.Wayland

Variants {
  // a fresh window per mode/edge: a mapped layer surface keeps its first margins
  model: Quickshell.screens.map(s => ({ screen: s, key: BarConfig.mode + BarConfig.edge }))

  PanelWindow {
    id: bar
    required property var modelData
    readonly property var scr: modelData.screen
    screen: scr
    WlrLayershell.namespace: "armoji-bar"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: BarConfig.editing ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    color: "transparent"

    readonly property string edge: BarConfig.edge
    readonly property bool vert: BarConfig.vertical
    readonly property string mode: BarConfig.mode
    readonly property bool flat: mode === "taskbar"
    readonly property real groupT: Theme.chipHeight + 2 * (Theme.groupGap + Theme.line("border"))
    // bar thickness (pills keep 6px of slack around the pill, as before)
    readonly property real thick: flat ? groupT + 8 : groupT + 6
    readonly property real edgeGap: flat ? 0 : 8      // from the screen edge
    readonly property real endGap: flat ? 0 : 12      // from the two ends
    // edit mode: the window grows by the tray strip; windows don't move
    readonly property real strip: !BarConfig.editing ? 0 : vert ? 190 : 64

    anchors { top: edge !== "bottom"; bottom: edge !== "top"; left: edge !== "right"; right: edge !== "left" }
    margins {
      top: edge === "top" ? edgeGap : vert ? endGap : 0
      bottom: edge === "bottom" ? edgeGap : vert ? endGap : 0
      left: edge === "left" ? edgeGap : vert ? 0 : endGap
      right: edge === "right" ? edgeGap : vert ? 0 : endGap
    }
    exclusiveZone: thick
    implicitHeight: vert ? 0 : thick + strip
    implicitWidth: vert ? thick + strip : 0
    mask: Region {
      item: body
      Region { item: stripBox; intersection: Intersection.Combine }
    }

    Item {
      id: frame
      anchors.fill: parent
      focus: BarConfig.editing
      Keys.onEscapePressed: BarConfig.editing = false

      Item {
        id: body
        x: bar.edge === "right" ? frame.width - width : 0
        y: bar.edge === "bottom" ? frame.height - height : 0
        width: bar.vert ? bar.thick : frame.width
        height: bar.vert ? frame.height : bar.thick

        // one-pill / taskbar background
        Rectangle {
          visible: bar.mode !== "pills"
          anchors.centerIn: parent
          width: bar.flat || bar.vert ? parent.width - (bar.flat ? 0 : 6) : parent.width
          height: bar.flat || !bar.vert ? parent.height - (bar.flat ? 0 : 6) : parent.height
          // ends follow the end widgets' corners, like each pill does (Group.qml)
          function endR(g, last) {
            const c = g.ends[last ? 1 : 0], it = c?.item ?? c
            const r = it ? (it.edgeRadius ?? it.radius ?? 0) : Theme.chipHeight / 2
            return Math.min(Math.min(width, height) / 2, Math.min(r, Theme.chipHeight / 2) + Theme.groupGap + body.inset)
          }
          readonly property real startR: bar.flat ? 0 : endR(gLeft.empty ? gCenter : gLeft, false)
          readonly property real endR2: bar.flat ? 0 : endR(gRight.empty ? gCenter : gRight, true)
          topLeftRadius: startR
          topRightRadius: bar.vert ? startR : endR2
          bottomLeftRadius: bar.vert ? endR2 : startR
          bottomRightRadius: endR2
          color: bar.flat ? Qt.alpha(Theme.c.bg ?? "#121212", Math.max(0.85, Theme.c.bgAlpha ?? 0.55)) : Theme.bg
          border.width: bar.flat ? 0 : Theme.line("border")
          border.color: Theme.border
          // taskbar: one hairline on the side facing the windows
          Rectangle {
            visible: bar.flat
            color: Theme.chipHover
            width: bar.vert ? 1 : parent.width
            height: bar.vert ? parent.height : 1
            x: bar.edge === "left" ? parent.width - 1 : 0
            y: bar.edge === "top" ? parent.height - 1 : 0
          }
        }

        // zones: start / middle / end along the bar
        // one pill: zones sit inside its outline, so the gap to the outline
        // is the same at the ends as above and below the chips
        readonly property real inset: bar.mode === "pills" ? 0 : bar.flat ? 8 : Theme.line("border")
        Group {
          id: gLeft
          zone: "left"; output: bar.scr.name; plain: bar.mode !== "pills"; editor: editor
          visible: !empty || BarConfig.editing
          x: bar.vert ? (body.width - width) / 2 : body.inset
          y: bar.vert ? body.inset : (body.height - height) / 2
        }
        Group {
          id: gCenter
          zone: "center"; output: bar.scr.name; plain: bar.mode !== "pills"; editor: editor
          visible: !empty || BarConfig.editing
          // centred, unless that overlaps an end zone: then pushed away from
          // it (a gap off the end zone); with no room either side, start wins
          readonly property real pos: {
            const len = bar.vert ? body.height : body.width, size = bar.vert ? height : width, gap = 8
            const lo = !gLeft.visible ? body.inset : (bar.vert ? gLeft.y + gLeft.height : gLeft.x + gLeft.width) + gap
            const hi = (!gRight.visible ? len - body.inset : (bar.vert ? gRight.y : gRight.x) - gap) - size
            return Math.max(lo, Math.min((len - size) / 2, hi))
          }
          x: bar.vert ? (body.width - width) / 2 : pos
          y: bar.vert ? pos : (body.height - height) / 2
        }
        Group {
          id: gRight
          zone: "right"; output: bar.scr.name; plain: bar.mode !== "pills"; editor: editor
          visible: !empty || BarConfig.editing
          x: bar.vert ? (body.width - width) / 2 : body.width - width - body.inset
          y: bar.vert ? body.height - height - body.inset : (body.height - height) / 2
        }
      }

      // ── edit mode: hidden widgets + Reset / Done, beside the bar ──
      Rectangle {
        id: stripBox
        visible: BarConfig.editing
        readonly property real pad: 10
        x: bar.vert ? (bar.edge === "left" ? bar.thick + 4 : frame.width - bar.thick - 4 - width) : (frame.width - width) / 2
        y: bar.vert ? (frame.height - height) / 2 : (bar.edge === "top" ? bar.thick + 4 : frame.height - bar.thick - 4 - height)
        width: bar.vert ? bar.strip - 8 : Math.min(frame.width, stripGrid.implicitWidth + 2 * pad)
        height: bar.vert ? Math.min(frame.height, stripGrid.implicitHeight + 2 * pad) : bar.strip - 8
        radius: Math.min(Theme.ctl(height), 18)
        color: Qt.alpha(Theme.c.bg ?? "#121212", 0.94)
        border.width: 1
        border.color: Qt.alpha(Theme.accent, editor.overTray ? 0.9 : 0.35)

        Grid {
          id: stripGrid
          anchors.centerIn: parent
          columns: bar.vert ? 1 : 99
          spacing: 8
          verticalItemAlignment: Grid.AlignVCenter
          horizontalItemAlignment: Grid.AlignHCenter
          UiLabel { head: true; text: BarConfig.zones.hidden.length ? "Hidden" : "Drag here to hide" }
          Repeater {
            model: BarConfig.zones.hidden
            Rectangle {
              id: hc
              required property string modelData
              readonly property string wid: modelData
              width: hcText.implicitWidth + 20; height: 28
              radius: Math.min(Theme.chipRadius, height / 2)
              color: hcMa.containsMouse ? Theme.chipHover : Theme.chipBg
              opacity: BarConfig.dragging === wid ? 0.3 : 1
              UiLabel { id: hcText; anchors.centerIn: parent; text: BarConfig.names[hc.wid] ?? hc.wid }
              MouseArea {
                id: hcMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                onPressed: m => editor.begin(hc.wid, hc, m.x, m.y)
                onPositionChanged: m => { if (pressed) editor.moveTo(hc, m.x, m.y) }
                onReleased: m => editor.end(hc, m.x, m.y)
                onCanceled: editor.cancel()
              }
            }
          }
          Item { width: bar.vert ? 1 : 16; height: bar.vert ? 8 : 1 }
          UiButton { text: "Reset"; onClicked: BarConfig.reset() }
          UiButton { text: "Done"; accent: true; onClicked: BarConfig.editing = false }
        }
      }

      // what's being dragged: its name, under the pointer
      Rectangle {
        id: ghost
        visible: BarConfig.dragging !== ""
        z: 100
        width: ghostText.implicitWidth + 24; height: 30
        radius: Math.min(Theme.chipRadius, height / 2)
        color: Qt.alpha(Theme.accent, 0.85)
        Text {
          id: ghostText
          anchors.centerIn: parent
          text: BarConfig.names[BarConfig.dragging] ?? ""
          color: Theme.onAccent
          font.family: Theme.font
          font.pixelSize: 13
        }
      }

      QtObject {
        id: editor
        property bool overTray: false
        function at(item, mx, my) { return item.mapToItem(frame, mx, my) }
        function place(p) { ghost.x = p.x - ghost.width / 2; ghost.y = p.y - ghost.height / 2 }
        function begin(id, item, mx, my) { BarConfig.dragging = id; place(at(item, mx, my)) }
        function moveTo(item, mx, my) { const p = at(item, mx, my); place(p); overTray = inside(p, stripBox, 8) }
        function cancel() { BarConfig.dragging = ""; overTray = false }
        function end(item, mx, my) {
          const id = BarConfig.dragging, t = target(at(item, mx, my))
          BarConfig.dragging = ""; overTray = false
          if (id && t) BarConfig.move(id, t.zone, t.index)
        }
        function inside(p, it, pad) {
          const o = it.mapToItem(frame, 0, 0)
          return p.x >= o.x - pad && p.x <= o.x + it.width + pad && p.y >= o.y - pad && p.y <= o.y + it.height + pad
        }
        // drop spot: the tray, or the zone under / nearest the pointer along
        // the bar, at the slot between the widgets on either side of it
        function target(p) {
          if (inside(p, stripBox, 8)) return { zone: "hidden", index: 1e3 }
          if (!inside(p, body, 24)) return null
          const axis = q => bar.vert ? q.y : q.x
          let best = null, bestD = Infinity
          for (const g of [gLeft, gCenter, gRight]) {
            const o = g.mapToItem(frame, 0, 0), a0 = axis(o), a1 = a0 + (bar.vert ? g.height : g.width)
            const d = axis(p) < a0 ? a0 - axis(p) : axis(p) > a1 ? axis(p) - a1 : 0
            if (d < bestD) { bestD = d; best = g }
          }
          const others = best.widgets().filter(w => w.wid !== BarConfig.dragging)
          const index = others.filter(w => {
            const c = w.mapToItem(frame, w.width / 2, w.height / 2)
            return axis(c) < axis(p)
          }).length
          return { zone: best.zone, index: index }
        }
      }
    }
  }
}
