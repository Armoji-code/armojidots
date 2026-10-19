// One of the three bar pills (left / center / right). Neat by construction:
// the gap between the outline and the chips is the same on all four sides,
// and each end's corner is its end chip's corner + gap + outline, so the two
// curves run parallel (left and right ends can differ: square chip vs circle).
import QtQuick

Rectangle {
  id: g
  default property alias content: row.data
  readonly property real gap: Theme.groupGap
  // first/last visible child; row width changes whenever one shows or hides
  readonly property var ends: {
    row.implicitWidth
    const vis = row.children.filter(c => c.visible && c.width > 0)
    return [vis[0] ?? null, vis[vis.length - 1] ?? null]
  }
  function outer(c) {
    const r = c ? (c.edgeRadius ?? c.radius ?? 0) : 0
    return Math.min(height / 2, Math.min(r, Theme.chipHeight / 2) + gap + border.width)
  }
  // the outline sits outside the pack's size, like the CSS border it replaces
  implicitWidth: row.implicitWidth + 2 * (gap + border.width)
  implicitHeight: Theme.chipHeight + 2 * (gap + border.width)
  topLeftRadius: outer(ends[0]); bottomLeftRadius: topLeftRadius
  topRightRadius: outer(ends[1]); bottomRightRadius: topRightRadius
  color: Theme.bg
  border.width: Theme.line("border")
  border.color: Theme.border

  Row {
    id: row
    anchors.centerIn: parent
    spacing: Theme.spacing
  }
}
