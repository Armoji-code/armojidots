// Freedesktop icon name → Nerd Font glyph for the shell's own (non-app)
// icons, so Spotlight's settings and "/" lists use one monochrome line set
// in every style. Names missing here fall back to the icon theme (UiIcon.qml).
.pragma library

const map = {
  "system-lock-screen": "󰌾",
  "system-suspend": "󰒲",
  "system-log-out": "󰍃",
  "system-reboot": "󰜉",
  "system-shutdown": "󰐥",
  "system-software-update": "󰚰",
  "folder-git": "󰊢",
  "org.cachyos.KernelManager": "󰌽",
  "preferences-desktop-theme": "󰏘",
  "applications-graphics": "󰏘",
  "preferences-desktop-display": "󰃟",
  "preferences-desktop-screensaver": "󰒲",
  "preferences-system-windows": "󰕰",
  "input-keyboard": "󰌌",
  "video-display": "󰍹",
  "web-browser": "󰖟",
  "dialog-question": "󰋗",
  "image-missing": "󰋩",
  "network-wireless": "󰖩",
  "network-wireless-signal-excellent": "󰤨",
  "network-wireless-signal-good": "󰤥",
  "network-wireless-signal-ok": "󰤢",
  "network-wireless-signal-weak": "󰤟",
  "bluetooth": "󰂯",
  "audio-headset": "󰋎",
  "audio-headphones": "󰋋",
  "audio-card": "󰓃",
  "input-mouse": "󰍽",
  "input-gaming": "󰺵",
  "input-tablet": "󰓶",
  "phone": "󰏲",
  "computer": "󰍹",
  "camera-photo": "󰄀",
  "printer": "󰐪",
  "audio-volume-high": "󰕾",
  "audio-input-microphone": "󰍬"
}
function of(name) { return map[name] ?? "" }
