// ── armojidots · dock ───────────────────────────────────────────────
// macOS-style autohide dock of running windows. A 3px hotspot strip at the
// bottom edge reveals it; it hides 1s after the pointer leaves. Windows are
// grouped per workspace into sub-pills, sidebars (app_id sidebar-*) get their
// own pill after a divider. Click focuses the window (sway jumps to it).
// Both surfaces stay mapped; the dock is click-through while hidden.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.I3
import Quickshell.Wayland

Scope {
  id: root
  readonly property real icon: 40
  readonly property real magMax: 1.55          // peak icon scale
  readonly property real magSigma: 58          // px falloff of the bump
  readonly property real appPad: Theme.n("dockAppPad", 4)
  readonly property real wsPadY: Theme.n("dockWsPadY", 2)
  readonly property real padY: Theme.n("dockPadY", 6)
  readonly property real shelfH: icon + 2 * (appPad + wsPadY + padY)
  readonly property real headroom: Math.ceil(icon * (magMax - 1)) + 2

  property bool shown: false
  property var groups: []                      // [{ sidebar, apps: [{id, appId, title}] }]

  function reveal() { hideT.stop(); if (!shown) { tree.running = true; shown = true } }
  function armHide() { hideT.restart() }
  Timer { id: hideT; interval: 1000; onTriggered: root.shown = false }

  // running windows from the sway tree (re-read on every reveal)
  Process {
    id: tree
    command: ["swaymsg", "-t", "get_tree"]
    stdout: StdioCollector { onStreamFinished: root.groups = root.parse(text) }
  }
  function parse(text) {
    let t
    try { t = JSON.parse(text) } catch (e) { return [] }
    const byWs = {}, side = []
    const walk = (n, ws) => {
      if (n.type === "workspace") ws = n.name
      const name = n.app_id || n.window_properties?.class
      const leaf = !(n.nodes?.length || n.floating_nodes?.length)
      if (name && (n.type === "con" || n.type === "floating_con") && leaf
          && !name.startsWith("org.armojidots")) {
        const w = { id: n.id, appId: name, title: n.name || "" }
        if (name.startsWith("sidebar-")) side.push(w)
        else (byWs[ws] = byWs[ws] || []).push(w)
      }
      for (const c of (n.nodes || []).concat(n.floating_nodes || [])) walk(c, ws)
    }
    walk(t, null)
    const key = ws => isNaN(parseInt(ws)) ? Infinity : parseInt(ws)   // scratchpad last
    const out = Object.keys(byWs).sort((a, b) => key(a) - key(b))
      .map(ws => ({ sidebar: false, apps: byWs[ws] }))
    if (side.length) out.push({ sidebar: true, apps: side })
    return out
  }

  function iconFor(appId) {
    const e = DesktopEntries.heuristicLookup(appId)
    return Quickshell.iconPath(e?.icon || appId, true) || Quickshell.iconPath("application-x-executable", true)
  }

  Variants {
    model: Quickshell.screens.filter(s => s.name === "eDP-1")

    Scope {
      required property var modelData

      // reveal strip
      PanelWindow {
        screen: modelData
        WlrLayershell.namespace: "armoji-dock-hotspot"
        WlrLayershell.layer: WlrLayer.Top
        exclusionMode: ExclusionMode.Ignore
        anchors { bottom: true; left: true; right: true }
        implicitHeight: 3
        color: "transparent"
        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          onEntered: root.reveal()
          onExited: root.armHide()
        }
      }

      PanelWindow {
        id: win
        screen: modelData
        WlrLayershell.namespace: "armoji-dock"
        WlrLayershell.layer: WlrLayer.Overlay
        exclusionMode: ExclusionMode.Ignore
        anchors { bottom: true; left: true; right: true }
        margins.bottom: 8
        implicitHeight: root.shelfH + root.headroom
        color: "transparent"
        // input only where the dock is, and nowhere while hidden
        mask: Region { item: root.shown ? hit : null }

        property real t: root.shown ? 1 : 0
        Behavior on t { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        // pointer x in row coordinates, or -1e6 when away (no magnification)
        property real px: -1e6

        Item { id: hit; x: shelf.x; width: shelf.width; height: parent.height }
        // on the window root so it's an ancestor of every icon (Qt only
        // delivers hover to the hovered item's ancestors)
        HoverHandler {
          onHoveredChanged: {
            if (hovered) root.reveal()
            else { win.px = -1e6; root.armHide() }   // icons ease back to rest
          }
          onPointChanged: win.px = hovered ? point.position.x - shelf.x - row.x : -1e6
        }

        Rectangle {
          id: shelf
          anchors.horizontalCenter: parent.horizontalCenter
          y: win.height - root.shelfH + (1 - win.t) * 24
          opacity: win.t
          width: row.width + 2 * Theme.n("dockPadX", 16)
          height: root.shelfH
          radius: Math.min(Theme.n("dockRadius", 999), height / 2)
          color: Theme.col("dockBg", "bgPop")
          border.width: Theme.line("dockBorder")
          border.color: Theme.col("dockBorder", "transparent")

          Row {
            id: row
            x: Theme.n("dockPadX", 16)
            anchors.bottom: parent.bottom
            anchors.bottomMargin: root.padY
            spacing: Theme.n("dockWsGap", 6)

            Repeater {
              model: root.groups
              Row {
                id: grp
                required property var modelData
                required property int index
                anchors.bottom: parent.bottom
                spacing: Theme.n("dockWsGap", 6)

                Rectangle {   // divider before the sidebar pill
                  visible: grp.modelData.sidebar && grp.index > 0
                  width: 1; height: root.icon - 6
                  anchors.bottom: parent.bottom
                  anchors.bottomMargin: root.wsPadY + 3
                  color: Theme.col("dockSep", "#40ffffff")
                }

                Rectangle {   // per-workspace sub-pill (stays at rest height; icons rise out)
                  id: sub
                  anchors.bottom: parent.bottom
                  width: apps.width + 2 * Theme.n("dockWsPadX", 6)
                  height: root.icon + 2 * (root.appPad + root.wsPadY)
                  radius: Math.min(Theme.n("dockWsRadius", 999), height / 2)
                  color: Theme.col("dockWsBg", "#12ffffff")

                  Row {
                    id: apps
                    x: Theme.n("dockWsPadX", 6)
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: root.wsPadY
                    spacing: Theme.n("dockAppGap", 4)

                    Repeater {
                      model: grp.modelData.apps
                      Rectangle {
                        id: app
                        required property var modelData
                        // eased Gaussian bump around the pointer
                        readonly property real c: grp.x + sub.x + apps.x + x + width / 2   // centre in row coords
                        readonly property real d: win.px - c
                        property real s: 1 + (root.magMax - 1) * Math.exp(-(d * d) / (2 * root.magSigma * root.magSigma))
                        Behavior on s { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }
                        readonly property real size: root.icon * s
                        anchors.bottom: parent.bottom
                        width: size + 2 * root.appPad
                        height: width
                        radius: Theme.n("dockAppRadius", 12)
                        color: ma.containsMouse ? Qt.alpha(Theme.accent, Theme.n("dockAppHoverAlpha", 0.22)) : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Image {
                          anchors.centerIn: parent
                          width: app.size; height: app.size
                          // decode once at peak size, then just scale (themes ship
                          // different artwork per size, so re-lookups swapped icons)
                          sourceSize: Qt.size(root.icon * root.magMax * 2, root.icon * root.magMax * 2)
                          source: root.iconFor(app.modelData.appId)
                          smooth: true
                          mipmap: true
                        }
                        MouseArea {
                          id: ma
                          anchors.fill: parent
                          hoverEnabled: true
                          onClicked: {
                            root.shown = false
                            I3.dispatch("[con_id=" + app.modelData.id + "] focus")
                          }
                        }
                        TipHost { target: app; above: true; hovered: ma.containsMouse; text: app.modelData.title || app.modelData.appId }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
