// ── armojidots · sidebars ───────────────────────────────────────────
// Quick-access terminals (fish / claude) as glass panels that slide in from
// a screen edge — layer surfaces, so they sit above windows on every
// workspace and never get tiled. Hidden, never killed: the session lives on
// until its program exits (it restarts on the next show).
//
// Geometry mirrors the old sway/scripts/sidebar-control.sh and reuses its
// state files (~/.local/state/armojidots/sidebar-<name>.{pos,stage},
// last-sidebar): dock edge left|right|top|bottom, size default|half|full.
//   qs -c armoji-shell ipc call sidebar toggle term|claude
//   qs -c armoji-shell ipc call sidebar sides|mode|size   (acts on the last shown)
//
// Terminal: QMLTermWidget (pacman qmltermwidget). Its colors come from the
// "armoji" scheme, which theme.sh writes to ~/.config/armoji-shell/
// terminal.colorscheme (symlinked into the plugin's color-schemes dir).
// The plugin reads schemes once per process, so the 16 terminal colors catch
// up on the next shell restart; the glass, the starship prompt and fish's
// syntax colors follow a palette change live (theme.sh sets them as hexes).
//
// Note: the sessions live in this shell process — restarting/reloading the
// shell (e.g. editing these QML files) ends them.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.I3
import Quickshell.Wayland

Scope {
  id: sb
  readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/armojidots"
  property string last: ""                // last shown sidebar (keybinds act on it)

  FileView {
    path: sb.stateDir + "/last-sidebar"
    onLoaded: sb.last = text().trim().replace(/^sidebar-/, "")
  }
  function remember(name) {
    last = name
    Quickshell.execDetached(["sh", "-c", 'printf %s "$1" > "$2"', "sh", "sidebar-" + name, stateDir + "/last-sidebar"])
  }
  function panel(name) { return name === "term" ? term : name === "claude" ? claude : null }

  IpcHandler {
    target: "sidebar"
    function toggle(name: string): void { const p = sb.panel(name); if (p) { if (!sb.anyOpen) sb.target = sb.focusedScreen(); p.toggle(); if (p.shown) sb.remember(name) } }
    function sides(): void { sb.panel(sb.last)?.cycle("sides") }
    function mode(): void { sb.panel(sb.last)?.cycle("mode") }
    function size(): void { sb.panel(sb.last)?.cycle("size") }
  }

  // ONE layer window for both panels. Full usable area only while a panel
  // is on screen (shown or sliding); 1×1 px otherwise — a transparent
  // full-screen layer still costs SwayFX blur work every frame anything
  // under it redraws. Never unmapped: a remapped Qt layer window isn't drawn
  // until some input arrives.
  readonly property bool anyOpen: term.active || claude.active
  function focusedScreen() { return Quickshell.screens.find(s => s.name === I3.focusedMonitor?.name) ?? Quickshell.screens[0] }
  property var target: focusedScreen()   // latched on open, so it doesn't follow focus while shown
  PanelWindow {
    id: win
    screen: sb.target
    WlrLayershell.namespace: "armoji-sidebar"
    WlrLayershell.layer: WlrLayer.Top
    // SwayFX drops focus from any non-exclusive layer on every layer
    // re-arrange, so on-demand only works after a click. Instead: exclusive
    // while a panel is in use (just opened, or under the pointer), on-demand
    // once the pointer leaves (keyboard back to your windows), none if hidden.
    WlrLayershell.keyboardFocus: (term.shown && term.grabbing) || (claude.shown && claude.grabbing)
      ? WlrKeyboardFocus.Exclusive
      : (term.shown || claude.shown) ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    exclusiveZone: 0                 // the usable area below the bar; pushes nothing
    anchors { top: true; left: true; bottom: sb.anyOpen; right: sb.anyOpen }
    implicitWidth: 1
    implicitHeight: 1
    color: "transparent"
    // input only on the visible glass panels
    mask: Region {
      regions: [
        Region { item: term.shown ? term.glass : null },
        Region { item: claude.shown ? claude.glass : null }
      ]
    }
    // usable area = screen minus the bar's reserved strip (Bar.qml: 8px top
    // margin + its height); the real window size takes over once it's full
    readonly property real barZone: 8 + Theme.chipHeight + 2 * (Theme.groupGap + Theme.line("border")) + 6
    readonly property real areaW: sb.anyOpen && width > 1 ? width : screen.width
    readonly property real areaH: sb.anyOpen && height > 1 ? height : screen.height - barZone

    SidebarPanel { id: term; name: "term"; program: "env"; args: ["SIDEBAR=1", "fish"]; stateDir: sb.stateDir; areaW: win.areaW; areaH: win.areaH }
    SidebarPanel { id: claude; name: "claude"; program: "claude"; args: []; stateDir: sb.stateDir; areaW: win.areaW; areaH: win.areaH }
  }
}
