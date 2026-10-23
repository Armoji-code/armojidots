// 󰅶 = staying awake (default, auto-lock off) · 󰒲 = auto-lock armed (Idle.qml)
import QtQuick

Chip {
  icon: true
  text: Idle.lockOn ? "󰒲" : "󰅶"
  fg: Idle.lockOn ? Theme.fg : Theme.col("idleOn", "accent")
  tip: Idle.lockOn ? "auto-lock: ON (locks after " + Idle.lockMin + "m)" : "auto-lock: OFF (click to arm)"
  onClicked: Idle.set("lockOn", !Idle.lockOn)
}
