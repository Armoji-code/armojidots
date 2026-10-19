// Shows a Tip under `target` after a short hover; the popup only exists while shown.
import QtQuick
import Quickshell

QtObject {
  id: h
  required property Item target
  property string text: ""
  property bool hovered: false
  property bool above: false         // open above the target (bottom-edge widgets)
  onHoveredChanged: if (hovered) delay.restart(); else { delay.stop(); loader.active = false }

  property Timer delay: Timer { interval: 450; onTriggered: h.loader.active = h.text !== "" }
  property LazyLoader loader: LazyLoader {
    Tip { target: h.target; text: h.text; above: h.above }
  }
}
