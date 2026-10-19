//@ pragma UseQApplication
// same icon theme theme.sh gives GTK (Qt otherwise only searches hicolor)
//@ pragma IconTheme Slot-Multicolor-Dark-Icons
// ── armojidots · shell ──────────────────────────────────────────────
// The whole desktop shell in one Quickshell process: bar, dock, OSD,
// spotlight. Theme: Theme.qml (colors/style json written by theme.sh).
import QtQuick
import Quickshell

ShellRoot {
  Bar {}
  Osd {}
  Dock {}
  Spotlight {}
}
