# armojidots

My SwayFX dotfiles — built from scratch, one step at a time.

> Status: **barebones stage** — SwayFX launches with a single keybind. Theming, bar, and the rest are coming.

## What's here

| Package | What it configures |
|---------|--------------------|
| `sway/` | SwayFX window manager |

## Setup

- **OS:** CachyOS (Arch)
- **WM:** [SwayFX](https://github.com/WillPower3309/swayfx)
- **Terminal:** [foot](https://codeberg.org/dnkl/foot)

## Install

```sh
sudo pacman -S swayfx foot stow
yay -S swaysome   # per-monitor workspaces (AUR)
git clone https://github.com/Armoji-code/armojidots.git ~/dotfiles
cd ~/dotfiles
stow sway
```

Configs are symlinked into `~/.config` by [GNU Stow](https://www.gnu.org/software/stow/) — editing the live config edits the repo.

## Keybinds (so far)

| Keys | Action |
|------|--------|
| `Win+T` | Open terminal |
| `Win+Q` | Close window |
| `Win+Space` | Toggle floating |
| `Win+F` | Toggle fullscreen |
| `Win` + left-drag | Move window |
| `Win` + right-drag | Resize window |
| `Win+1…0` | Switch workspace (per-monitor, via [swaysome](https://gitlab.com/hyask/swaysome)) |
| `Win+Shift+1…0` | Move window to workspace and follow |
| `Win+Alt+1…0` | Move the whole workspace (all windows) to slot N and follow |

## Config structure

Modular, one file per concern — new features get their own module:

```
sway/.config/sway/
├── config           # entry point: variables + includes
├── keybinds.conf    # apps + window controls
├── workspaces.conf  # swaysome per-monitor workspaces
├── appearance.conf  # borders (SwayFX effects coming)
└── scripts/         # helpers for what plain keybinds can't do
```
