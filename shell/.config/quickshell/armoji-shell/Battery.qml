import QtQuick
import Quickshell.Services.UPower

Chip {
  numeric: true
  readonly property var dev: UPower.displayDevice
  readonly property real p: dev.percentage <= 1 ? dev.percentage * 100 : dev.percentage
  readonly property bool charging: dev.state === UPowerDeviceState.Charging
    || dev.state === UPowerDeviceState.FullyCharged
  visible: dev.isLaptopBattery
  function hm(s) { const h = Math.floor(s / 3600), mm = Math.round(s % 3600 / 60); return (h ? h + "h " : "") + mm + "m" }
  tip: charging ? (dev.timeToFull > 0 ? hm(dev.timeToFull) + " to full" : "charging")
       : dev.timeToEmpty > 0 ? hm(dev.timeToEmpty) + " left" : ""
  text: (charging ? "󰂄" : ["󰁺", "󰁼", "󰁾", "󰂀", "󰁹"][Math.min(4, Math.floor(p / 20))])
        + " " + Math.round(p) + "%"
  fg: charging ? Theme.col("batteryCharging", "#98c379")
    : p <= 10 ? Theme.col("batteryCritical", "#e06c75")
    : p <= 25 ? Theme.col("batteryWarning", "#e5c07b")
    : Theme.col("battery", "fg")
}
