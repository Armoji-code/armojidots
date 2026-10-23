// ── armojidots · spotlight ──────────────────────────────────────────
// Launcher: a search capsule plus a results panel under it. Empty query =
// 5×2 grid of top apps; typing = list (elephant apps + calc); "/" = our own
// commands (Commands.js): each is a mouse page (Page*.qml) the box fits to —
// "/" or the cog = the settings hub, /wifi /colors /power … (prefixes work:
// /po) — and an argument after it is a quick keyboard action for Enter
// (/colors ruby). Only /web is a list.
// Toggle: `qs -c armoji-shell ipc call spotlight toggle`.
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
  property var ctx: ({ home: Quickshell.env("HOME"), style: "material", packs: {}, wallpapers: [], tools: [] })

  // page in the box: "" (results) | hub | wifi | bluetooth | monitors |
  // customize (+ its tabs: style colors wallpaper fonts cursor icons) | idle |
  // layout | power | keys | updates | term:<cmd>
  property string page: ""
  property string termTitle: ""
  property var pageObj: null           // the loaded Page*.qml
  readonly property bool isTerm: page.startsWith("term:")
  readonly property bool busy: isTerm && (pageObj?.busy ?? false)
  readonly property var titles: ({ hub: "Settings", wifi: "Wi-Fi", bluetooth: "Bluetooth", monitors: "Monitors",
    customize: "Customize", style: "Customize", colors: "Customize", wallpaper: "Customize", fonts: "Customize",
    cursor: "Customize", icons: "Customize", idle: "Idle", layout: "Layout", power: "Power", keys: "Shortcuts",
    updates: "Updates" })
  readonly property string pageTitle: isTerm ? termTitle : titles[page] ?? ""
  // Enter on a page runs the typed argument (/colors ruby) — the first
  // quick-list item, which stays computed but hidden
  readonly property var quick: page !== "" && !isTerm && Cmd.quickArg(query) && items[0]?.kind === "cmd" ? items[0] : null

  function openPage(name, title) {
    if (name.startsWith("term:")) termTitle = title ?? "Update"
    pageObj = null; page = name
  }
  // Esc / ‹ : page → its parent (hub, or Updates for a terminal) → results
  function back() {
    if (busy) return
    if (page === "") { close(); return }
    const typed = Cmd.pageFor(query)
    if (isTerm) openPage("updates")
    else if (page !== "hub" && page !== typed) openPage("hub")
    else { page = ""; if (typed !== "") { query = ""; run("") } }
  }

  IpcHandler {
    target: "spotlight"
    function toggle(): void { sp.shown ? sp.close() : sp.show() }
    function hide(): void { sp.close() }
    // open with a query typed in (scripts, testing): `… ipc call spotlight search "/wifi"`
    function search(q: string): void { if (!sp.shown) sp.show(); sp.query = q; sp.page = Cmd.pageFor(q); sp.run(q) }
    // press Enter / Esc (testing without a keyboard)
    function enter(): void { sp.activate(sp.sel) }
    function goBack(): void { sp.back() }
    // open a page by name (bar chips): `… ipc call spotlight page wifi`
    function page(name: string): void { if (!sp.shown) sp.show(); sp.openPage(name) }
  }

  function show() {
    closeT.stop()
    page = ""; pageObj = null
    query = ""; items = []; sel = 0; mode = "grid"
    ctxProc.running = true
    run("")
    open = true; shown = true
  }
  // put text in the search pill as if typed (hub's Web tile → "/web ")
  function typeQuery(q) { query = q; page = Cmd.pageFor(q); run(q) }
  function refreshCtx() { ctxProc.running = true }   // after a style change
  function close() { if (busy) return; shown = false; closeT.restart() }
  Timer { id: closeT; interval: 130; onTriggered: sp.open = false }

  // style, style packs and wallpapers for the / commands (re-read on open)
  Process {
    id: ctxProc
    command: ["sh", "-c", 'cat ~/.local/state/armojidots/style 2>/dev/null; echo "\n@@@";'
      + ' for d in ~/.config/armoji-styles/*/; do echo "@@$(basename "$d")"; cat "$d/pack.conf" 2>/dev/null; done;'
      + ' echo "@@@"; ls ~/Pictures/Wallpapers 2>/dev/null;'
      + ' echo "@@@"; for c in yay paru flatpak cachyos-kernel-manager; do command -v $c >/dev/null && echo $c; done']
    stdout: StdioCollector {
      onStreamFinished: {
        const parts = text.split("@@@\n")
        const packs = {}
        for (const blk of (parts[1] || "").split("@@").slice(1)) {
          const nl = blk.indexOf("\n")
          packs[blk.slice(0, nl < 0 ? undefined : nl).trim()] = Cmd.packConf(nl < 0 ? "" : blk.slice(nl + 1))
        }
        sp.ctx = { home: sp.ctx.home, style: (parts[0] || "").trim() || "material", packs: packs,
                   wallpapers: (parts[2] || "").split("\n").filter(s => s),
                   tools: (parts[3] || "").split("\n").filter(s => s) }
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
    if (page !== "" && !quick) return
    const it = quick ?? items[i]
    if (!it || it.kind === "noop") return
    if (it.kind === "page") { openPage(it.value, it.text); return }
    if (it.kind === "fill") { query = it.value; page = Cmd.pageFor(it.value); run(it.value); return }
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

      MouseArea { anchors.fill: parent; onClicked: sp.close() }   // click outside = close (not while busy)

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
          anchors { left: glass.right; leftMargin: 10; right: cog.left; rightMargin: 10; verticalCenter: parent.verticalCenter }
          focus: true
          text: sp.query
          onTextChanged: if (text !== sp.query && !sp.busy) { sp.query = text; sp.page = Cmd.pageFor(text); sp.run(text) }
          color: Theme.fg
          selectionColor: Qt.alpha(Theme.accent, 0.4)
          cursorDelegate: Rectangle { width: 2; color: Theme.accent }
          font.family: Theme.n("spEntryFont", Theme.font)
          font.pixelSize: Theme.n("spEntrySize", 18)
          clip: true
          Text {
            visible: !input.text
            text: sp.page !== "" ? sp.pageTitle : "Search"

            color: Theme.muted
            font: input.font
          }
          Keys.onPressed: e => {
            const grid = sp.mode === "grid"
            if (e.key === Qt.Key_Escape) sp.back()
            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) sp.activate(sp.sel)
            else if (e.key === Qt.Key_Down) sp.move(grid ? sp.cols : 1)
            else if (e.key === Qt.Key_Up) sp.move(grid ? -sp.cols : -1)
            else if (grid && e.key === Qt.Key_Right) sp.move(1)
            else if (grid && e.key === Qt.Key_Left) sp.move(-1)
            else return
            e.accepted = true
          }
        }
        // settings cog: the mouse way into the pages
        Text {
          id: cog
          anchors { right: parent.right; rightMargin: Theme.n("spSearchPad", 18) - 4; verticalCenter: parent.verticalCenter }
          text: "󰒓"
          color: cogMa.containsMouse || sp.page === "hub" ? Theme.accent : Theme.muted
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 19
          Behavior on color { ColorAnimation { duration: 120 } }
          MouseArea { id: cogMa; anchors.fill: parent; anchors.margins: -6; hoverEnabled: true
                      onClicked: sp.page === "hub" ? sp.back() : sp.openPage("hub") }
        }
        // a "fill" item rewrites the query: keep the caret at the end
        Connections { target: sp; function onQueryChanged() { if (input.text === sp.query) input.cursorPosition = input.text.length } }
      }

      // ── results panel ──
      Rectangle {
        id: panel
        readonly property real pad: Theme.n("spContentPad", 10)
        // a page sizes the box to itself (header + its implicit size)
        readonly property real target: sp.page !== "" ? header.height + 10 + pageLoader.height + 2 * pad
          : sp.items.length === 0 ? 0
          : sp.mode === "grid" ? gridView.implicitHeight + 2 * pad
          : Math.min(list.contentHeight, 360) + 2 * pad
        x: Math.round((parent.width - width) / 2)
        y: search.y + sp.searchH + 12 - (1 - win.t) * 10
        width: sp.page !== "" ? Math.max(sp.w, pageLoader.width + 2 * pad) : sp.w
        height: target
        Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
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
          Connections { target: sp; function onModeChanged() { fade.restart() } function onPageChanged() { fade.restart() } }
          NumberAnimation { id: fade; target: content; property: "opacity"; from: 0; to: 1; duration: 150 }

          Grid {
            id: gridView
            visible: sp.mode === "grid" && sp.page === ""
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
                radius: Theme.cardRadius
                color: on || cellMa.containsMouse ? Theme.chipHover : Theme.col("spCellBg", "transparent")
                border.width: 1
                border.color: on ? Theme.selBorder : "transparent"
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
                  id: cellMa
                  anchors.fill: parent
                  hoverEnabled: true
                  onClicked: sp.activate(cell.index)
                }
              }
            }
          }

          // ── page: header (‹ title) + the page itself ──
          Item {
            id: pageArea
            anchors.fill: parent
            visible: sp.page !== ""
            Row {
              id: header
              spacing: 8
              height: 30
              Rectangle {
                width: 30; height: 30; radius: Theme.ctl(30)
                color: backMa.containsMouse ? Theme.chipHover : Theme.chipBg
                opacity: sp.busy ? 0.4 : 1
                Text { anchors.centerIn: parent; text: "󰅁"; color: Theme.fg; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16 }
                MouseArea { id: backMa; anchors.fill: parent; hoverEnabled: true; onClicked: sp.back() }
              }
              UiLabel { anchors.verticalCenter: parent.verticalCenter; text: sp.pageTitle; font.pixelSize: 16 }
            }
            UiLabel {
              anchors { right: parent.right; rightMargin: 4; verticalCenter: header.verticalCenter }
              visible: sp.quick !== null
              text: "↵  " + (sp.quick?.text ?? "")
              color: Theme.accent
            }
            Loader {
              id: pageLoader
              y: header.height + 10
              active: sp.page !== ""
              // the look tabs share one Customize page (it picks the tab from sp.page)
              sourceComponent: ({ hub: hubC, wifi: wifiC, bluetooth: btC, monitors: monC, customize: custC,
                                  style: custC, colors: custC, wallpaper: custC, fonts: custC, cursor: custC,
                                  icons: custC, idle: idleC, layout: layoutC, power: powerC, keys: keysC,
                                  updates: updC })[sp.page] ?? (sp.isTerm ? termC : null)
              onLoaded: sp.pageObj = item
              // back to results: the search pill takes the keys again
              onActiveChanged: if (!active) input.forceActiveFocus()
            }
          }
          Component { id: hubC; PageHub { host: sp } }
          Component { id: wifiC; PageWifi { host: sp } }
          Component { id: btC; PageBluetooth { host: sp } }
          Component { id: monC; PageMonitors { host: sp } }
          Component { id: custC; PageCustomize { host: sp } }
          Component { id: idleC; PageIdle { host: sp } }
          Component { id: layoutC; PageLayout { host: sp } }
          Component { id: powerC; PagePower { host: sp } }
          Component { id: keysC; PageKeys { host: sp } }
          Component { id: updC; PageUpdates { host: sp } }
          Component { id: termC; SpotTerm { host: sp; cmd: sp.page.slice(5) } }

          ListView {
            id: list
            visible: sp.mode === "list" && sp.page === ""
            anchors.fill: parent
            interactive: contentHeight > height
            boundsBehavior: Flickable.StopAtBounds
            model: sp.mode === "list" ? sp.items : []
            currentIndex: sp.sel
            highlightFollowsCurrentItem: false
            onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
            delegate: SpotRow {
              required property var modelData
              required property int index
              width: ListView.view.width
              cursor: sp.sel === index
              ic: modelData.iconPx || 30
              icon: sp.iconSrc(modelData.icon)
              title: modelData.text
              sub: modelData.subtext
              onClicked: sp.activate(index)
            }
          }
        }
      }
    }
  }
}
