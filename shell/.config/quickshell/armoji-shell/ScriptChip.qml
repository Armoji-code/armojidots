// Chip driven by a waybar-style script printing {"text","class"} JSON.
// One-shot scripts re-run `status` after their own `toggle`; `watch` scripts
// (lang.sh) stream lines instead.
import QtQuick
import Quickshell
import Quickshell.Io

Chip {
  id: sc
  required property string script
  property bool watch: false
  property var colors: ({})          // class -> color
  property string cls: ""
  readonly property string path: Quickshell.env("HOME") + "/.config/waybar/scripts/" + script

  icon: true
  fg: colors[cls] ?? Theme.fg
  onClicked: toggle.running = true

  function take(line) {
    try { const j = JSON.parse(line); sc.text = j.text ?? ""; sc.cls = j.class ?? ""; sc.tip = j.tooltip ?? "" } catch (e) {}
  }
  Process {
    id: status
    running: true
    // pdeathsig: helpers die with the bar instead of orphaning
    command: ["setpriv", "--pdeathsig", "TERM", sc.path, sc.watch ? "watch" : "status"]
    stdout: SplitParser { onRead: data => sc.take(data) }
  }
  Process {
    id: toggle
    command: [sc.path, "toggle"]
    onExited: if (!sc.watch) status.running = true
  }
}
