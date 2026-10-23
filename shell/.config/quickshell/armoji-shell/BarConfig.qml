pragma Singleton
// Bar layout, set from Spotlight's Layout page and the bar's edit mode:
// mode (pills | pill | taskbar), edge (top | bottom | left | right) and which
// widget sits in which zone. Saved in ~/.local/state/armojidots/bar.json.
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: bc
  readonly property string file: Quickshell.env("HOME") + "/.local/state/armojidots/bar.json"
  readonly property var widgets: ["clock", "media", "workspaces", "tray", "bluetooth", "network", "lang",
    "volume", "backlight", "battery", "power", "idle", "bluelight", "notifs"]
  readonly property var defaults: ({ left: ["clock", "media"], center: ["workspaces"],
    right: ["tray", "bluetooth", "network", "lang", "volume", "backlight", "battery", "power", "idle", "bluelight", "notifs"],
    hidden: [] })

  readonly property var names: ({ clock: "Clock", media: "Media", workspaces: "Workspaces", tray: "Tray",
    bluetooth: "Bluetooth", network: "Wi-Fi", lang: "Keyboard", volume: "Volume", backlight: "Brightness",
    battery: "Battery", power: "Power profile", idle: "Auto-lock", bluelight: "Night light", notifs: "Notifications" })

  property string mode: "pills"
  property string edge: "top"
  property var zones: defaults
  property bool editing: false
  onEditingChanged: dragging = ""
  property string dragging: ""       // widget id being dragged in edit mode
  readonly property bool vertical: edge === "left" || edge === "right"
  // where bar popups (tooltips, tray menus) open: away from the edge
  readonly property string popSide: ({ top: "below", bottom: "above", left: "right", right: "left" })[edge]

  // known ids only, each once; ids the file doesn't mention (new widgets) go right
  function clean(z) {
    const out = { left: [], center: [], right: [], hidden: [] }, seen = {}
    for (const k of ["left", "center", "right", "hidden"])
      for (const id of (z?.[k] ?? [])) if (widgets.includes(id) && !seen[id]) { out[k].push(id); seen[id] = true }
    for (const id of widgets) if (!seen[id]) out.right.push(id)
    return out
  }

  FileView {
    path: bc.file
    printErrors: false
    onLoaded: {
      try {
        const j = JSON.parse(text())
        if (["pills", "pill", "taskbar"].includes(j.mode)) bc.mode = j.mode
        if (["top", "bottom", "left", "right"].includes(j.edge)) bc.edge = j.edge
        bc.zones = bc.clean(j.zones)
      } catch (e) {}
    }
  }
  function save() {
    const t = JSON.stringify({ mode: mode, edge: edge, zones: zones }, null, 2)
    Quickshell.execDetached(["sh", "-c", 'mkdir -p "${1%/*}" && printf "%s\\n" "$2" > "$1"', "sh", file, t])
  }
  function set(key, value) { bc[key] = value; save() }
  // put widget `id` into `zone` at `index` (dragging in edit mode)
  function move(id, zone, index) {
    const z = clean(zones)
    for (const k in z) z[k] = z[k].filter(x => x !== id)
    z[zone].splice(Math.max(0, Math.min(index, z[zone].length)), 0, id)
    zones = z; save()
  }
  function reset() { zones = clean(defaults); save() }

  IpcHandler {
    target: "bar"
    function edit(): void { bc.editing = true }
    function done(): void { bc.editing = false }
    function reset(): void { bc.reset() }
    function set(key: string, value: string): void { if (key === "mode" || key === "edge") bc.set(key, value) }
    function move(id: string, zone: string, index: int): void { bc.move(id, zone, index) }
  }
}
