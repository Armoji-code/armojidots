// Spotlight page: everything about the look in one place, one tab at a time.
// The tab is the page name itself (/style, /colors, /fonts …), so commands
// open their tab directly; "customize" alone opens the first one.
import QtQuick

Item {
  id: pg
  required property var host
  readonly property var tabs: ["style", "colors", "wallpaper", "fonts", "cursor", "icons"]
  readonly property string tab: tabs.includes(host.page) ? host.page : "style"
  implicitWidth: Math.max(seg.implicitWidth, body.item?.implicitWidth ?? 0)
  implicitHeight: seg.height + 16 + (body.item?.implicitHeight ?? 0)

  UiSegment {
    id: seg
    anchors.horizontalCenter: parent.horizontalCenter
    options: ["Style", "Colors", "Wallpaper", "Fonts", "Cursor", "Icons"]
    current: pg.tabs.indexOf(pg.tab)
    onPicked: i => pg.host.page = pg.tabs[i]
  }
  Loader {
    id: body
    y: seg.height + 16
    width: pg.width
    sourceComponent: ({ style: styleC, colors: colorsC, wallpaper: wallC, fonts: fontsC, cursor: cursorC, icons: iconsC })[pg.tab]
  }
  Component { id: styleC; PageStyle { host: pg.host } }
  Component { id: colorsC; PageColors { host: pg.host } }
  Component { id: wallC; PageWallpaper { host: pg.host } }
  Component { id: fontsC; PageFonts { host: pg.host } }
  Component { id: cursorC; PageCursor { host: pg.host } }
  Component { id: iconsC; PageIcons { host: pg.host } }
}
