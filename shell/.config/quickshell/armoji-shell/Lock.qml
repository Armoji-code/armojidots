// ── armojidots · lock screen ────────────────────────────────────────
// ext-session-lock (the compositor keeps everything hidden until unlock,
// even if this process dies) + PAM. One LockSurface per screen; they share
// the typed password and state here, so typing works on whichever has focus.
//   lock:   ~/.config/sway/scripts/lock.sh  (IPC, swaylock if the shell is down)
//   stuck (shell crashed while locked)? Ctrl+Alt+F2, log in, then
//           SWAYSOCK=$(ls /run/user/$UID/sway-ipc.*.sock) swaymsg exec swaylock
//           and unlock that (sway lets a new locker take over a dead one).
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam

Scope {
  id: lk
  property string buffer: ""
  property string state: ""          // "" | checking | wrong | unlocking
  property int fails: 0              // bumps → shake
  readonly property bool locked: sl.locked

  function lock() { if (!sl.locked) { buffer = ""; state = ""; sl.locked = true } }
  function submit() {
    if (state === "checking" || state === "unlocking" || buffer === "") return
    state = "checking"
    pam.start()
  }

  PamContext {
    id: pam
    config: "swaylock"                // /etc/pam.d/swaylock, from the fallback locker
    onResponseRequiredChanged: if (responseRequired) respond(lk.buffer)
    onCompleted: result => {
      // surfaces play their exit animation, then the lock lifts
      if (result === PamResult.Success) { lk.buffer = ""; lk.state = "unlocking"; unlockT.restart() }
      else { lk.buffer = ""; lk.state = "wrong"; lk.fails++ }
    }
    onError: { lk.buffer = ""; lk.state = "wrong"; lk.fails++ }
  }

  Timer { id: unlockT; interval: 420; onTriggered: { sl.locked = false; lk.state = "" } }

  WlSessionLock {
    id: sl
    LockSurface { lock: lk }
  }

  IpcHandler {
    target: "lock"
    function lock(): void { lk.lock() }
    function isLocked(): bool { return sl.locked }
  }
}
