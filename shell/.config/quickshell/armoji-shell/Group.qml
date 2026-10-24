// One bar zone (BarConfig.zones[zone]) as a pill. Neat by construction: the
// gap between the outline and the chips is the same on all four sides, and
// each end's corner is its end chip's corner + gap + outline, so the two
// curves run parallel (the ends can differ: square chip vs circle).
// `plain`: no fill / outline (one-pill and taskbar modes draw their own).
import QtQuick

Rectangle {
  id: g
  required property string zone
  required property string output
  property bool plain: false
  property var editor: null
  readonly property bool vert: BarConfig.vertical
  readonly property real gap: Theme.groupGap
  readonly property real thickness: Theme.chipHeight + 2 * (gap + border.width)
  // first/last visible widget; the grid's size changes whenever one shows or hides
  readonly property var ends: {
    grid.implicitWidth; grid.implicitHeight
    const vis = grid.children.filter(c => c.visible && c.width > 0 && c.height > 0)
    return [vis[0] ?? null, vis[vis.length - 1] ?? null]
  }
  // from the config, not from `ends`: a hidden group's children all read invisible
  readonly property bool empty: (BarConfig.zones[zone] ?? []).length === 0
  // this zone's widgets on screen, in order (edit-mode drop slots)
  function widgets() { return grid.children.filter(c => c.wid !== undefined && c.visible && c.width > 0) }
  function outer(c) {
    const it = c?.item ?? c
    const r = it ? (it.edgeRadius ?? it.radius ?? 0) : 0
    return Math.min(thickness / 2, Math.min(r, Theme.chipHeight / 2) + gap + border.width)
  }
  // the outline sits outside the pack's size, like the CSS border it replaces
  // while editing, an empty zone keeps a drop target's worth of length
  readonly property real len: Math.max(BarConfig.editing ? 56 : 0, (vert ? grid.implicitHeight : grid.implicitWidth) + 2 * (gap + border.width))
  implicitWidth: vert ? thickness : len
  implicitHeight: vert ? len : thickness
  topLeftRadius: outer(ends[0])
  topRightRadius: vert ? topLeftRadius : outer(ends[1])
  bottomLeftRadius: vert ? outer(ends[1]) : topLeftRadius
  bottomRightRadius: vert ? bottomLeftRadius : topRightRadius
  color: plain ? "transparent" : Theme.bg
  border.width: plain ? 0 : Theme.line("border")
  border.color: Theme.border

  Rectangle {   // empty zone while editing: a dashed-looking drop slot
    visible: BarConfig.editing && g.empty
    anchors { fill: parent; margins: g.gap }
    radius: Math.min(Theme.chipRadius, Math.min(width, height) / 2)
    color: "transparent"
    border.width: 1
    border.color: Qt.alpha(Theme.accent, 0.5)
  }
  Grid {
    id: grid
    anchors.centerIn: parent
    // exact count of shown widgets: a spare column (a hidden widget, or the
    // Repeater itself) adds a trailing gap
    columns: g.vert ? 1 : Math.max(1, children.filter(c => c.wid !== undefined && c.visible).length)
    spacing: Theme.spacing
    horizontalItemAlignment: Grid.AlignHCenter
    verticalItemAlignment: Grid.AlignVCenter
    Repeater {
      id: rep
      model: BarConfig.zones[g.zone] ?? []
      BarWidget { required property string modelData; wid: modelData; output: g.output; editor: g.editor }
    }
  }
}
