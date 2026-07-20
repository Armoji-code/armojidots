#!/bin/sh
# ── macOS-style dock (nwg-dock) ─────────────────────
#   -d          autohide: reveal when the cursor hits the bottom edge,
#               hide again on leave or after clicking an app
#   -l overlay  floats on top of windows, reserves no space
#   -nolauncher no Launchpad button (Spotlight/walker covers that)
#   -nows       no workspace switcher — just the running apps
#   clicking an app focuses it, which teleports you to its workspace
# No -mb: a bottom margin also shifts the reveal hotspot up, leaving a
# dead strip at the very screen edge where the cursor can't trigger it.
# The floating gap is done in CSS (window margin) instead.
# -hd 0 disables the reveal speed-gate so a gentle scrape of the bottom
# edge triggers it, not only a fast jab.
pkill -x nwg-dock 2>/dev/null
exec nwg-dock -d -hd 0 -l overlay -nolauncher -nows -i 44
