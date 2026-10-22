// Glass card for Spotlight's pages (the detail sidebar, tiles' backdrop).
// `sel`: selected/active look (Theme.selBg + selBorder); `hover`: chipHover.
import QtQuick

Rectangle {
  property bool sel: false
  property bool hover: false
  radius: Theme.cardRadius
  color: sel ? Theme.selBg : hover ? Theme.chipHover : Theme.chipBg
  border.width: sel ? Math.max(1, Theme.line("spBorder")) : Theme.line("spBorder")
  border.color: sel ? Theme.selBorder : Theme.col("spBorder", "transparent")
  Behavior on color { ColorAnimation { duration: 140 } }
}
