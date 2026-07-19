# armojidots

My SwayFX dotfiles — built from scratch, one step at a time.

> Status: **barebones stage** — SwayFX launches with a single keybind. Theming, bar, and the rest are coming.

## What's here

| Package | What it configures |
|---------|--------------------|
| `sway/` | SwayFX window manager |
| `waybar/` | Top status bar |
| `walker/` | Spotlight-style launcher (walker + elephant) |

## Setup

- **OS:** CachyOS (Arch)
- **WM:** [SwayFX](https://github.com/WillPower3309/swayfx)
- **Terminal:** [foot](https://codeberg.org/dnkl/foot)

## Install

```sh
sudo pacman -S swayfx foot stow waybar brightnessctl pavucontrol swaybg nemo swaync jq
yay -S swaysome walker-bin elephant-desktopapplications elephant-calc \
       elephant-runner elephant-websearch elephant-menus bluetuith-bin
git clone https://github.com/Armoji-code/armojidots.git ~/dotfiles
cd ~/dotfiles
stow sway waybar walker
elephant service enable
```

Configs are symlinked into `~/.config` by [GNU Stow](https://www.gnu.org/software/stow/) — editing the live config edits the repo.

## Keybinds (so far)

| Keys | Action |
|------|--------|
| tap `Win` | Toggle Spotlight launcher |
| `Win+T` | Open terminal |
| `Win+E` | Open file manager (Nemo) |
| `Win+Q` | Close window |
| `Win+Space` | Toggle floating |
| `Win+F` | Toggle fullscreen |
| `Win` + left-drag | Move window |
| `Win` + right-drag | Resize window |
| `Win+1…0` | Switch workspace (per-monitor, via [swaysome](https://gitlab.com/hyask/swaysome)) |
| `Win+Shift+1…0` | Move window to workspace and follow |
| `Win+Alt+1…0` | Move the whole workspace (all windows) to slot N and follow |
| `Win+Shift+S` | Region screenshot → clipboard + notification |
| `Win+R` | Toggle quick-access terminal sidebar (left, sticky across workspaces) |
| `Win+Shift+R` | Toggle Claude Code sidebar (same, runs `claude --resume`) |

## Spotlight

Tap `Win`: apps sorted by your usage, plus hidden commands —
`/set wifi · blue · wallpaper`, `/power`, `/web <query>`, `/bash <cmd>`,
and inline math (`23*7`, Enter copies the result). Clicking the bar's
wifi/bluetooth pills opens nmtui/bluetuith in floating glass terminals.

## Config structure

Modular, one file per concern — new features get their own module:

```
sway/.config/sway/
├── config           # entry point: variables + includes
├── input.conf       # touchpad/mouse (Windows-style scrolling)
├── keybinds.conf    # apps + window controls + Spotlight
├── workspaces.conf  # swaysome per-monitor workspaces
├── appearance.conf  # borders + gaps (12px edges, matching the bar)
├── effects.conf     # SwayFX: rounded corners, shadows, dim, blur, layer glass
├── rules.conf       # window rules (floating glass TUI terminals)
├── autostart.conf   # waybar, swaync, walker service, swaybg wallpaper
└── scripts/         # move-workspace, wallpaper-pick

waybar/.config/waybar/
├── config.jsonc     # clock | workspaces | tray/bt/net/audio/brightness/battery/power
├── scripts/         # power-profile toggle
└── style.css        # glass pills on a transparent strip

walker/.config/
├── walker/          # Spotlight config + armoji glass theme
└── elephant/        # app history, /set + /power menu definitions
```
