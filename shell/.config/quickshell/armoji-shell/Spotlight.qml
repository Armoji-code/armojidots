// ── armojidots · spotlight ──────────────────────────────────────────
// Launcher: a search capsule plus a results panel under it. Empty query =
// 5×2 grid of top apps; typing = list (elephant apps + calc); "/" = our own
// commands (Commands.js). Toggle: `qs -c armoji-shell ipc call spotlight toggle`.
//
// One full-screen transparent overlay that only exists while open: both pills
// are drawn in it (SwayFX blur_ignore_transparent blurs just behind them),
// and a click on the empty rest closes it.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.I3
import Quickshell.Wayland
import Quickshell.Widgets
import "Commands.js" as Cmd

Scope {
  id: sp
  readonly property real w: 640
  readonly property real searchH: 40
  readonly property int cols: 5

  property bool open: false            // overlay exists
  property bool shown: false           // target of the open/close animation
  property string query: ""
  property var items: []
  property string mode: "grid"         // grid (empty query) | list
  property int sel: 0
  property var ctx: ({ home: Quickshell.env("HOME"), style: "default", packs: {}, wallpapers: [] })

  IpcHandler {
    target: "spotlight"
    function toggle(): void { sp.shown ? sp.close() : sp.show() }
    // open with a query typed in (scripts, testing): `… ipc call spotlight search "/set"`
    function search(q: string): void { if (!sp.shown) sp.show(); sp.query = q; sp.run(q) }
  }

  function show() {
    closeT.stop()
    query = ""; items = []; sel = 0; mode = "grid"
    ctxProc.running = true
    run("")
    open = true; shown = true
  }
  function close() { shown = false; closeT.restart() }
  Timer { id: closeT; interval: 130; onTriggered: sp.open = false }

  // style, style packs and wallpapers for the /set commands (re-read on open)
  Process {
    id: ctxProc
    command: ["sh", "-c", 'cat ~/.local/state/armojidots/style 2>/dev/null; echo "\n@@@";'
      + ' for d in ~/.config/armoji-styles/*/; do echo "@@$(basename "$d")"; cat "$d/pack.conf" 2>/dev/null; done;'
      + ' echo "@@@"; ls ~/Pictures/Wallpapers 2>/dev/null']
    stdout: StdioCollector {
      onStreamFinished: {
        const parts = text.split("@@@\n")
        const packs = {}
        for (const blk of (parts[1] || "").split("@@").slice(1)) {
          const nl = blk.indexOf("\n")
          packs[blk.slice(0, nl < 0 ? undefined : nl).trim()] = Cmd.packConf(nl < 0 ? "" : blk.slice(nl + 1))
        }
        sp.ctx = { home: sp.ctx.home, style: (parts[0] || "").trim() || "default", packs: packs,
                   wallpapers: (parts[2] || "").split("\n").filter(s => s) }
      }
    }
  }

  // one elephant query per keystroke; stale answers are dropped
  Component {
    id: queryComp
    Process {
      id: pr
      property string q
      property string spec
      running: true
      command: ["elephant", "query", "--json", spec]
      stdout: StdioCollector {
        onStreamFinished: {
          if (pr.q === sp.query) sp.setItems(Cmd.elephant(text), pr.q === "" ? "grid" : "list")
          pr.destroy()
        }
      }
    }
  }

  function run(text) {
    if (text.startsWith("/")) { setItems(Cmd.run(ctx, text), "list"); return }
    queryComp.createObject(sp, { q: text,
      spec: text === "" ? "desktopapplications;;" + cols * 2 : "desktopapplications,calc;" + text + ";8" })
  }
  // pack info arrives just after open: redo a "/" query that ran without it
  onCtxChanged: if (query.startsWith("/")) run(query)
  function setItems(list, m) { items = list; mode = m; sel = 0 }

  function activate(i) {
    const it = items[i]
    if (!it || it.kind === "noop") return
    if (it.kind === "fill") { query = it.value; run(it.value); return }
    if (it.kind === "calc") Quickshell.execDetached(["wl-copy", it.value])
    else if (it.kind === "cmd") Quickshell.execDetached(["sh", "-c", it.value])
    else Quickshell.execDetached(["gtk-launch", it.value])
    close()
  }
  function move(step) { if (items.length) sel = Math.max(0, Math.min(items.length - 1, sel + step)) }

  function iconSrc(icon) {
    // iconPath(name, true) is "" when the theme lacks it (the string-fallback
    // form still renders Qt's magenta "missing" pattern)
    return icon.startsWith("/") ? "file://" + icon
      : Quickshell.iconPath(icon, true) || Quickshell.iconPath("application-x-executable", true)
  }

  LazyLoader {
    active: sp.open

    PanelWindow {
      id: win
      screen: Quickshell.screens.find(s => s.name === I3.focusedMonitor?.name) ?? Quickshell.screens[0]
      WlrLayershell.namespace: "spotlight-search"
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
      exclusionMode: ExclusionMode.Ignore
      anchors { top: true; bottom: true; left: true; right: true }
      color: "transparent"

      // 0 → 1 open, eased; starts at 0 so the first frame animates in
      property real t: 0
      Component.onCompleted: t = Qt.binding(() => sp.shown ? 1 : 0)
      Behavior on t {
        NumberAnimation { duration: sp.shown ? 190 : 110; easing.type: sp.shown ? Easing.OutCubic : Easing.InCubic }
      }

      MouseArea { anchors.fill: parent; onClicked: sp.close() }   // click outside = close

      // ── search capsule ──
      Rectangle {
        id: search
        x: (parent.width - sp.w) / 2
        y: Math.round(parent.height * 0.18)
        width: sp.w; height: sp.searchH
        radius: Math.min(Theme.n("spSearchRadius", 20), height / 2)
        color: Theme.col("spBg", "bgPop")
        border.width: Theme.line("spBorder")
        border.color: Theme.col("spBorder", "transparent")
        opacity: win.t
        scale: 0.955 + 0.045 * win.t
        MouseArea { anchors.fill: parent }   // swallow clicks

        Text {
          id: glass
          x: Theme.n("spSearchPad", 18)
          anchors.verticalCenter: parent.verticalCenter
          text: "󰍉"
          color: Theme.muted
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 20
        }
        TextInput {
          id: input
          anchors { left: glass.right; leftMargin: 10; right: parent.right; rightMargin: Theme.n("spSearchPad", 18); verticalCenter: parent.verticalCenter }
          focus: true
          text: sp.query
          onTextChanged: if (text !== sp.query) { sp.query = text; sp.run(text) }
          color: Theme.fg
          selectionColor: Qt.alpha(Theme.accent, 0.4)
          cursorDelegate: Rectangle { width: 2; color: Theme.accent }
          font.family: Theme.n("spEntryFont", Theme.font)
          font.pixelSize: Theme.n("spEntrySize", 18)
          clip: true
          Text {
            visible: !input.text
            text: "Search"
            color: Theme.muted
            font: input.font
          }
          Keys.onPressed: e => {
            const grid = sp.mode === "grid"
            if (e.key === Qt.Key_Escape) sp.close()
            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) sp.activate(sp.sel)
            else if (e.key === Qt.Key_Down) sp.move(grid ? sp.cols : 1)
            else if (e.key === Qt.Key_Up) sp.move(grid ? -sp.cols : -1)
            else if (grid && e.key === Qt.Key_Right) sp.move(1)
            else if (grid && e.key === Qt.Key_Left) sp.move(-1)
            else return
            e.accepted = true
          }
        }
        // a "fill" item rewrites the query: keep the caret at the end
        Connections { target: sp; function onQueryChanged() { if (input.text === sp.query) input.cursorPosition = input.text.length } }
      }

      // ── results panel ──
      Rectangle {
        id: panel
        readonly property real pad: Theme.n("spContentPad", 10)
        readonly property real target: sp.items.length === 0 ? 0
          : sp.mode === "grid" ? gridView.implicitHeight + 2 * pad
          : Math.min(list.contentHeight, 360) + 2 * pad
        x: search.x
        y: search.y + sp.searchH + 12 - (1 - win.t) * 10
        width: sp.w
        height: target
        Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        visible: height > 0.5
        radius: Theme.n("spContentRadius", 16)
        color: Theme.col("spBg", "bgPop")
        border.width: Theme.line("spBorder")
        border.color: Theme.col("spBorder", "transparent")
        opacity: win.t
        clip: true
        MouseArea { anchors.fill: parent }   // swallow clicks

        // cross-fade when switching grid <-> list
        Item {
          id: content
          anchors.fill: parent
          anchors.margins: panel.pad
          Connections { target: sp; function onModeChanged() { fade.restart() } }
          NumberAnimation { id: fade; target: content; property: "opacity"; from: 0; to: 1; duration: 150 }

          Grid {
            id: gridView
            visible: sp.mode === "grid"
            columns: sp.cols
            spacing: 6
            Repeater {
              model: sp.mode === "grid" ? sp.items : []
              Rectangle {
                id: cell
                required property var modelData
                required property int index
                readonly property bool on: sp.sel === index
                width: (sp.w - 2 * panel.pad - (sp.cols - 1) * gridView.spacing) / sp.cols
                height: 44 + 6 + 16 + 20
                radius: Theme.n("spCellRadius", 12)
                color: on ? Qt.alpha(Theme.accent, Theme.n("spSelAlpha", 0.22)) : Theme.col("spCellBg", "transparent")
                border.width: 1
                border.color: on ? Qt.alpha(Theme.accent, Theme.n("spSelBorderAlpha", 0.35)) : "transparent"
                Behavior on color { ColorAnimation { duration: 140 } }
                Column {
                  anchors.centerIn: parent
                  spacing: 6
                  Image {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 44; height: 44
                    sourceSize: Qt.size(88, 88)
                    source: sp.iconSrc(cell.modelData.icon)
                    asynchronous: true
                  }
                  Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Math.min(implicitWidth, cell.width - 12)
                    elide: Text.ElideRight
                    text: cell.modelData.text
                    color: cell.on ? Theme.fg : Theme.muted
                    font.family: Theme.n("spLabelFont", Theme.font)
                    font.pixelSize: Theme.n("spLabelSize", 12)
                    font.letterSpacing: Theme.ls(Theme.n("spLabelSize", 12), "spLabelSpacing")
                  }
                }
                MouseArea {
                  anchors.fill: parent
                  hoverEnabled: true
                  onEntered: sp.sel = cell.index
                  onClicked: sp.activate(cell.index)
                }
              }
            }
          }

          ListView {
            id: list
            visible: sp.mode === "list"
            anchors.fill: parent
            interactive: contentHeight > height
            boundsBehavior: Flickable.StopAtBounds
            model: sp.mode === "list" ? sp.items : []
            currentIndex: sp.sel
            highlightFollowsCurrentItem: false
            onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
            delegate: Rectangle {
              id: row
              required property var modelData
              required property int index
              readonly property bool on: sp.sel === index
              readonly property real ic: modelData.iconPx || 30
              width: ListView.view.width
              height: ic + 16
              radius: Theme.n("spRowRadius", 12)
              color: on ? Qt.alpha(Theme.accent, Theme.n("spSelAlpha", 0.22)) : "transparent"
              border.width: 1
              border.color: on ? Qt.alpha(Theme.accent, Theme.n("spSelBorderAlpha", 0.35)) : "transparent"
              Behavior on color { ColorAnimation { duration: 140 } }
              Image {
                id: rowIcon
                x: 12
                anchors.verticalCenter: parent.verticalCenter
                width: row.ic; height: row.ic
                sourceSize: Qt.size(row.ic * 2, row.ic * 2)
                fillMode: Image.PreserveAspectCrop
                source: sp.iconSrc(row.modelData.icon)
                asynchronous: true
              }
              Column {
                anchors { left: rowIcon.right; leftMargin: 12; right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                Text {
                  width: parent.width
                  elide: Text.ElideRight
                  text: row.modelData.text
                  color: Theme.fg
                  font.family: Theme.n("spTitleFont", Theme.font)
                  font.pixelSize: Theme.n("spTitleSize", 15)
                }
                Text {
                  visible: text !== ""
                  width: parent.width
                  elide: Text.ElideRight
                  text: row.modelData.subtext
                  color: Theme.muted
                  font.family: Theme.n("spSubFont", Theme.font)
                  font.pixelSize: Theme.n("spSubSize", 12)
                  font.letterSpacing: Theme.ls(Theme.n("spSubSize", 12), "spSubSpacing")
                }
              }
              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: sp.sel = row.index
                onClicked: sp.activate(row.index)
              }
            }
          }
        }
      }
    }
  }
}
