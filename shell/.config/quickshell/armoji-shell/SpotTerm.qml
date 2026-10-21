// Spotlight panel: a command (the /update entries) running in a terminal
// inside the box — prompts and the sudo password are typed right here.
// `busy` while it runs: Spotlight won't close then (that would kill it).
import QtQuick
import Quickshell
import QMLTermWidget

Item {
  id: st
  required property var host
  required property string cmd
  property bool busy: true
  implicitWidth: 820
  implicitHeight: 400

  QMLTermWidget {
    id: term
    anchors.fill: parent
    font.family: Theme.n("termFont", "JetBrainsMono Nerd Font")
    font.pointSize: 10
    colorScheme: "armoji"
    // same trick as the sidebars: the scheme's black background → glass
    layer.enabled: true
    layer.effect: ShaderEffect { fragmentShader: Qt.resolvedUrl("shaders/unblack.frag.qsb") }
    session: QMLTermSession {
      id: session
      shellProgram: "sh"
      shellProgramArgs: ["-c", st.cmd + '; printf "\\n\\033[2m── done · Esc to go back ──\\033[0m"']
      initialWorkingDirectory: Quickshell.env("HOME")
      onFinished: st.busy = false
    }
    Keys.priority: Keys.BeforeItem
    Keys.onPressed: e => { if (e.key === Qt.Key_Escape && !st.busy) { st.host.back(); e.accepted = true } }
  }
  // started once laid out (at 0×0 the program sees a 1-column terminal)
  Timer { interval: 80; running: true; onTriggered: { session.startShellProgram(); term.forceActiveFocus() } }
}
