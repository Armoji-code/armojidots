// swaync bell: count stream + control center on click.
import QtQuick
import Quickshell
import Quickshell.Io

Chip {
  id: nb
  property string alt: "none"
  icon: true
  text: alt.startsWith("dnd") ? "󰂛" : alt.endsWith("notification") ? "󱅫" : "󰂚"
  fg: alt.startsWith("dnd") ? Theme.col("dnd", "muted")
    : alt.endsWith("notification") ? Theme.col("notif", "accent") : Theme.fg
  onClicked: Quickshell.execDetached(["swaync-client", "-t", "-sw"])
  Process {
    running: true
    command: ["setpriv", "--pdeathsig", "TERM", "swaync-client", "-swb"]
    stdout: SplitParser {
      onRead: data => { try { nb.alt = JSON.parse(data).alt ?? "none" } catch (e) {} }
    }
  }
}
