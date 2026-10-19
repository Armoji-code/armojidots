pragma Singleton
// Colors (colors.json, palette) and shape tokens (style.json, style pack) —
// both written by sway/scripts/theme.sh and reloaded live on change.
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: t
  readonly property string dir: Quickshell.env("HOME") + "/.config/armoji-shell"
  property var c: ({})
  property var s: ({})

  readonly property color accent: c.accent ?? "#537ff2"
  readonly property color accentDim: c.accentDim ?? "#3957a4"
  readonly property color fg: c.fg ?? "#d4d4d4"
  readonly property color muted: c.muted ?? "#8c8c8c"
  readonly property color bg: Qt.alpha(c.bg ?? "#121212", c.bgAlpha ?? 0.55)
  readonly property color bgPop: Qt.alpha(c.bg ?? "#121212", c.bgPopAlpha ?? 0.58)  // dock/popups

  // style token: a color name ("accent", "fg", "muted", "accentDim") or literal
  function col(key, fallback) {
    const v = s[key] ?? fallback
    return v === "accent" ? accent : v === "accentDim" ? accentDim
         : v === "fg" ? fg : v === "muted" ? muted : v === "bg" ? bg : v === "bgPop" ? bgPop : v
  }
  function n(key, fallback) { return s[key] ?? fallback }
  // 1px outline if the pack sets a visible border color for `key`
  // (pack values are strings, so `.a` on them would be undefined)
  function line(key) { const v = s[key]; return v && v !== "transparent" ? 1 : 0 }
  // pack letter-spacing is in em, Qt wants px
  function ls(px, key) { return (s[key ?? "letterSpacing"] ?? 0) * px }

  readonly property string font: n("font", "JetBrainsMono Nerd Font")
  readonly property real fontSize: n("fontSize", 13)
  readonly property real groupHeight: n("groupHeight", 28)
  readonly property real chipHeight: n("chipHeight", 22)
  readonly property real groupPad: n("groupPad", 6)
  // even gap between a bar group's outline and its chips (all four sides)
  readonly property real groupGap: n("groupGap", 4)
  readonly property real chipPad: n("chipPad", 9)
  readonly property real spacing: n("spacing", 4)
  readonly property real chipRadius: n("chipRadius", 999)
  readonly property bool iconRound: n("iconRound", false)
  readonly property color border: col("border", "transparent")
  readonly property color chipBg: col("chipBg", "#12ffffff")
  readonly property color chipHover: col("chipHover", "#24ffffff")

  // one knob for every animation in the bar
  readonly property int animMs: 220

  function parse(view) { try { return JSON.parse(view.text()) } catch (e) { return null } }
  FileView {
    path: t.dir + "/colors.json"
    watchChanges: true
    onFileChanged: reload()
    onLoaded: t.c = t.parse(this) ?? t.c
  }
  FileView {
    path: t.dir + "/style.json"
    watchChanges: true
    onFileChanged: reload()
    onLoaded: t.s = t.parse(this) ?? t.s
  }
}
