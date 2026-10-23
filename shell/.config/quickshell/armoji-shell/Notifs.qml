pragma Singleton
// ── armojidots · notifications ──────────────────────────────────────
// The notification daemon (org.freedesktop.Notifications), shared by the
// popups (NotifPopups), the center panel (NotifCenter) and the bar bell.
// Every notification stays in the history until dismissed; `popups` is the
// subset currently shown as toasts. DND hides toasts, keeps the history;
// it's remembered in ~/.local/state/armojidots/dnd.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

Singleton {
  id: ns
  readonly property var list: server.trackedNotifications.values.slice().reverse()   // newest first
  readonly property int count: list.length
  property var popups: []
  property var times: ({})             // id → Date received
  property bool centerOpen: false

  readonly property string dndFile: Quickshell.env("HOME") + "/.local/state/armojidots/dnd"
  property bool dnd: dndView.text().trim() === "on"
  FileView { id: dndView; path: ns.dndFile; printErrors: false }
  function setDnd(on) {
    dnd = on
    if (on) popups = []
    Quickshell.execDetached(["sh", "-c", 'mkdir -p "${1%/*}" && echo "$2" > "$1"', "sh", dndFile, on ? "on" : "off"])
  }

  function toggleCenter() { centerOpen = !centerOpen; if (centerOpen) popups = [] }
  function hidePopup(n) { popups = popups.filter(p => p !== n) }
  function clear() { for (const n of list.slice()) n.dismiss() }
  // the default action (clicking the card body), else just dismiss
  function activate(n) {
    const a = n.actions.find(a => a.identifier === "default")
    if (a) a.invoke(); else n.dismiss()
  }
  // a leading icon apps put in the summary (󰹑 Screenshot) → [icon, rest]: it's
  // drawn apart in the proportional Nerd Font (the fallback glyph overlaps text)
  function splitIcon(t) {
    const m = t.match(/^([\uE000-\uF8FF]|[\uDB80-\uDBFF][\uDC00-\uDFFF])\s*/)
    return m ? [m[1], t.slice(m[0].length)] : ["", t]
  }
  function ago(n) {
    const s = (Date.now() - (times[n.id] ?? Date.now())) / 1000
    return s < 60 ? "now" : s < 3600 ? Math.floor(s / 60) + "m" : s < 86400 ? Math.floor(s / 3600) + "h" : Math.floor(s / 86400) + "d"
  }

  NotificationServer {
    id: server
    keepOnReload: true
    persistenceSupported: true
    bodySupported: true
    bodyMarkupSupported: true
    actionsSupported: true
    imageSupported: true
    onNotification: n => {
      n.tracked = true
      ns.times = Object.assign({}, ns.times, { [n.id]: new Date() })
      n.closed.connect(() => ns.hidePopup(n))
      // replaced notifications (notify-send -r) come back as the same object
      if (!ns.dnd && !ns.centerOpen) ns.popups = [n].concat(ns.popups.filter(p => p !== n)).slice(0, 5)
    }
  }

  IpcHandler {
    target: "notifs"
    function toggle(): void { ns.toggleCenter() }
    function dnd(): void { ns.setDnd(!ns.dnd) }
    function clear(): void { ns.clear() }
  }
}
