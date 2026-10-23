#!/bin/sh
# Lock the session: the shell's lock screen, or plain swaylock when the
# shell isn't running (or can't lock).
qs -c armoji-shell ipc call lock lock 2>/dev/null || exec swaylock -f -c 111111
