// 󰅶 = staying awake (default, auto-lock off) · 󰒲 = auto-lock armed
import QtQuick
import Quickshell
import Quickshell.Wayland

Chip {
  IdleInhibitor { id: inh; enabled: true; window: QsWindow.window }
  icon: true
  text: inh.enabled ? "󰅶" : "󰒲"
  fg: inh.enabled ? Theme.col("idleOn", "accent") : Theme.fg
  tip: inh.enabled ? "auto-lock: OFF (click to arm)" : "auto-lock: ON (5m lock, 10m screen off)"
  onClicked: inh.enabled = !inh.enabled
}
