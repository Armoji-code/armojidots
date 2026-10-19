// Clock; click toggles the month between number and name.
import QtQuick
import Quickshell

Chip {
  property bool alt: false
  SystemClock { id: clk; precision: SystemClock.Seconds }
  text: Qt.formatDateTime(clk.date, alt ? "HH:mm:ss  yyyy-MMMM-dd" : "HH:mm:ss  yyyy-MM-dd")
  fg: Theme.col("clock", "accent")
  fontSize: Theme.n("clockSize", Theme.fontSize)
  fontFamily: Theme.n("clockFont", Theme.font)   // nothingos: dot-matrix accent
  onClicked: alt = !alt
  tip: cal(clk.date)

  // month calendar, Monday first, today in the accent
  function cal(d) {
    const y = d.getFullYear(), m = d.getMonth(), today = d.getDate()
    const first = (new Date(y, m, 1).getDay() + 6) % 7
    const days = new Date(y, m + 1, 0).getDate()
    const pad = n => (n < 10 ? "&nbsp;" : "") + n
    let out = "<b>" + Qt.formatDate(d, "yyyy MMMM") + "</b><br><font color='"
      + Theme.muted + "'>Mo&nbsp;Tu&nbsp;We&nbsp;Th&nbsp;Fr&nbsp;Sa&nbsp;Su</font><br>"
    let cells = Array(first).fill("&nbsp;&nbsp;")
    for (let i = 1; i <= days; i++)
      cells.push(i === today ? "<font color='" + Theme.accent + "'><b>" + pad(i) + "</b></font>" : pad(i))
    for (let i = 0; i < cells.length; i += 7)
      out += cells.slice(i, i + 7).join("&nbsp;") + "<br>"
    return out.replace(/<br>$/, "")
  }
}
