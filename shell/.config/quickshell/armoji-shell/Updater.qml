pragma Singleton
// Background updates (/update with "Run in background" on): owns the
// update-bg.sh process so it outlives Spotlight closing. The password goes
// to the script's stdin and nowhere else. The toggle is remembered in
// ~/.local/state/armojidots/update-bg.
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: u
  property bool running: false
  property string target: ""
  property bool authFailed: false
  signal authOk()

  readonly property string stateFile: Quickshell.env("HOME") + "/.local/state/armojidots/update-bg"
  property bool background: bgFile.text().trim() === "on"
  function setBackground(on) {
    background = on
    Quickshell.execDetached(["sh", "-c", 'mkdir -p "${1%/*}" && echo "$2" > "$1"', "sh", stateFile, on ? "on" : "off"])
  }
  FileView { id: bgFile; path: u.stateFile; printErrors: false }

  function run(what, pw) {
    if (running) return
    target = what; authFailed = false; running = true
    proc.pw = pw
    proc.running = true
  }

  Process {
    id: proc
    property string pw
    command: ["sh", Quickshell.env("HOME") + "/.config/sway/scripts/update-bg.sh", u.target]
    stdinEnabled: true
    onStarted: { write(pw + "\n"); pw = ""; stdinEnabled = false }
    stdout: SplitParser { onRead: data => { if (data === "AUTH_OK") u.authOk() } }
    onExited: code => { u.authFailed = code === 3; u.running = false; stdinEnabled = true }
  }
}
