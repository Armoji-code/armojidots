// One sidebar terminal (see Sidebar.qml): a glass panel with a QMLTermWidget
// inside. Lives in Sidebar.qml's single shared window and positions itself
// from the usable screen area it's given (areaW/areaH), so the window can
// shrink to nothing while every panel is hidden without the panels jumping.
import QtQuick
import Quickshell
import Quickshell.Io
import QMLTermWidget

Item {
  id: p
  required property string name
  required property string program
  required property var args
  required property string stateDir
  required property real areaW           // usable area (below the bar)
  required property real areaH
  readonly property alias glass: glass
  readonly property int gap: 12
  readonly property int crossTB: 920     // width of the slim top/bottom strip
  property bool shown: false
  property bool started: false           // program starts on first show, at real size
  property bool grabbing: false          // wants the keyboard (exclusive)
  property string pos: "left"
  property string stage: "default"
  readonly property bool side: pos === "left" || pos === "right"
  readonly property bool active: shown || t > 0.001   // on screen, incl. sliding out

  function toggle() { shown = !shown }
  function cycle(what) {
    if (what === "sides") pos = { left: "right", right: "left", top: "bottom", bottom: "top" }[pos]
    else if (what === "mode") pos = side ? "top" : "left"
    else stage = { default: "half", half: "full", full: "default" }[stage]
    posFile.setText(pos); stageFile.setText(stage)
  }

  FileView { id: posFile; path: p.stateDir + "/sidebar-" + p.name + ".pos"; onLoaded: p.pos = text().trim() || "left" }
  FileView { id: stageFile; path: p.stateDir + "/sidebar-" + p.name + ".stage"; onLoaded: p.stage = text().trim() || "default" }

  // target rectangle of the glass (window coords = usable area)
  readonly property real safeW: areaW - 2 * gap
  readonly property real safeH: areaH - 2 * gap
  readonly property real pct: stage === "full" ? 1 : stage === "half" ? 0.5 : side ? 0.25 : 0.32
  readonly property real tw: side ? Math.round(safeW * pct) : (stage === "default" ? crossTB : safeW)
  readonly property real th: side ? safeH : Math.round(safeH * pct)
  readonly property real tx: pos === "right" ? areaW - gap - tw : side ? gap : Math.round((areaW - tw) / 2)
  readonly property real ty: pos === "bottom" ? areaH - gap - th : gap

  // 0 hidden → 1 shown: slides in from its edge
  property real t: 0
  Behavior on t { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
  Component.onCompleted: t = Qt.binding(() => p.shown ? 1 : 0)
  onShownChanged: { grabbing = shown; if (shown) termView.forceActiveFocus() }

  Rectangle {
    id: glass
    readonly property real slide: (1 - p.t) * 40
    // glides between edges/sizes; the slide offset rides on top
    property real gx: p.tx
    property real gy: p.ty
    Behavior on gx { NumberAnimation { duration: 280; easing.type: Easing.InOutCubic } }
    Behavior on gy { NumberAnimation { duration: 280; easing.type: Easing.InOutCubic } }
    Behavior on width { NumberAnimation { duration: 280; easing.type: Easing.InOutCubic } }
    Behavior on height { NumberAnimation { duration: 280; easing.type: Easing.InOutCubic } }
    x: gx + (p.pos === "left" ? -slide : p.pos === "right" ? slide : 0)
    y: gy + (p.pos === "top" ? -slide : p.pos === "bottom" ? slide : 0)
    width: p.tw
    height: p.th
    opacity: p.t
    visible: p.active
    radius: 16
    clip: true
    color: Theme.bgPop             // same frosted glass as the other popups
    border.width: Theme.line("border")
    border.color: Theme.border
    HoverHandler {
      onHoveredChanged: if (p.shown) { p.grabbing = hovered; if (hovered) termView.forceActiveFocus() }
    }

    QMLTermWidget {
      id: termView
      // sized to the TARGET, not the animating glass: the program reflows
      // once per move instead of every frame (the glass clips meanwhile)
      x: 12; y: 12
      width: p.tw - 24
      height: p.th - 24
      font.family: Theme.n("termFont", "JetBrainsMono Nerd Font")
      font.pointSize: 11
      colorScheme: "armoji"
      // the widget always paints its background opaque (its opacity setting
      // isn't reachable from QML): the scheme's background is pure black and
      // this shader turns black into transparency, so the glass shows through
      layer.enabled: true
      layer.effect: ShaderEffect { fragmentShader: Qt.resolvedUrl("shaders/unblack.frag.qsb") }
      session: QMLTermSession {
        id: session
        shellProgram: p.program
        shellProgramArgs: p.args
        initialWorkingDirectory: Quickshell.env("HOME")
        onFinished: { p.shown = false; restart.start() }
      }
      // start once shown and laid out: started at 0×0 the program sees a
      // 1-column terminal and wraps everything one character per line
      Timer { id: firstStart; interval: 80; onTriggered: { p.started = true; session.startShellProgram() } }
      Connections { target: p; function onShownChanged() { if (p.shown && !p.started) firstStart.start() } }
      // program exited: start a fresh one for the next show
      Timer { id: restart; interval: 300; onTriggered: session.startShellProgram() }
    }
  }
}
