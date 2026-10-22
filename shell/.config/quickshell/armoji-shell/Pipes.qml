// pipes.sh, drawn: a few pipes crawl a grid one cell per tick, turning now
// and then, in the theme's colors; the canvas clears after `limit` steps.
// Colors follow the palette live (a theme change starts a fresh screen).
import QtQuick

Canvas {
  id: c
  property real cell: Theme.n("pipesCell", 20)
  property int count: Theme.n("pipesCount", 4)
  property int interval: Theme.n("pipesMs", 45)        // frame time
  property real speed: Theme.n("pipesSpeed", 0.4)      // cells per frame
  property int limit: Theme.n("pipesLimit", 7200)      // cells drawn before a clear
  property real turn: 0.14                     // chance to turn per step
  property bool running: visible
  readonly property color bgc: Qt.alpha(Theme.bg, 1)
  readonly property var colors: [Theme.accent, Theme.accentDim, Qt.lighter(Theme.accent, 1.35), Theme.fg, Theme.muted]
  readonly property int cols: Math.max(1, Math.floor(width / cell))
  readonly property int rows: Math.max(1, Math.floor(height / cell))
  property var pipes: []
  property int steps: 0
  property bool wipe: true

  renderTarget: Canvas.FramebufferObject
  onColorsChanged: reset()
  onWidthChanged: reset()
  onHeightChanged: reset()

  function spawn() {
    return { x: Math.floor(Math.random() * cols), y: Math.floor(Math.random() * rows),
             d: Math.floor(Math.random() * 4), t: 0, col: colors[Math.floor(Math.random() * colors.length)] }
  }
  function reset() { wipe = true; steps = 0; pipes = Array.from({ length: count }, spawn); requestPaint() }

  Timer {
    running: c.running && c.width > 0
    repeat: true
    interval: c.interval
    onTriggered: c.requestPaint()
  }

  onPaint: {
    const ctx = getContext("2d")
    if (wipe || steps >= limit) {
      ctx.fillStyle = bgc
      ctx.fillRect(0, 0, width, height)
      if (!wipe) pipes = Array.from({ length: count }, spawn)
      wipe = false; steps = 0
      return
    }
    // grid inset so pipes sit evenly inside the screen
    const ox = (width - cols * cell) / 2 + cell / 2, oy = (height - rows * cell) / 2 + cell / 2
    ctx.lineWidth = Math.max(2, cell / 4)
    ctx.lineCap = Theme.ctlRadius > 0 ? "round" : "square"
    const dx = [1, 0, -1, 0], dy = [0, 1, 0, -1]
    // each frame grows a pipe `speed` of a cell; turns happen only at cell centers
    for (const p of pipes) {
      if (p.t === 0) {
        if (Math.random() < turn) p.d = (p.d + (Math.random() < 0.5 ? 1 : 3)) % 4
        const nx = p.x + dx[p.d], ny = p.y + dy[p.d]
        if (nx < 0 || ny < 0 || nx >= cols || ny >= rows) {
          // off the edge: re-enter on the far side in a new color, like pipes.sh
          p.x = (nx + cols) % cols; p.y = (ny + rows) % rows
          p.col = colors[Math.floor(Math.random() * colors.length)]
          continue
        }
      }
      const t1 = Math.min(1, p.t + speed)
      ctx.strokeStyle = p.col
      ctx.beginPath()
      ctx.moveTo(ox + (p.x + dx[p.d] * p.t) * cell, oy + (p.y + dy[p.d] * p.t) * cell)
      ctx.lineTo(ox + (p.x + dx[p.d] * t1) * cell, oy + (p.y + dy[p.d] * t1) * cell)
      ctx.stroke()
      if (t1 >= 1) { p.x += dx[p.d]; p.y += dy[p.d]; p.t = 0; steps++ }
      else p.t = t1
    }
  }
}
