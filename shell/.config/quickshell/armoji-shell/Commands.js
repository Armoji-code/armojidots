// Spotlight's own command providers (/power /update /set /web /keys), ported
// from the Python armoji-spotlight. Each returns a list of items:
//   { text, subtext, icon, kind: launch|cmd|fill|calc|noop, value, iconPx }
// `ctx` = { home, style, packs: {name: {title, description, allowed_palettes, neutral}},
//           wallpapers: [file names] } — gathered by Spotlight.qml on open.
.pragma library

const PALETTES = ["wallpaper", "ruby", "orange", "dandelion", "emerald",
                  "cobalt", "bubblegum", "purpur", "b&w"]

function item(text, subtext, icon, kind, value, iconPx) {
  return { text: text, subtext: subtext || "", icon: icon || "", kind: kind,
           value: value || "", iconPx: iconPx || 0 }
}

function paths(ctx) {
  return {
    theme: ctx.home + "/.config/sway/scripts/theme.sh",
    wallDir: ctx.home + "/Pictures/Wallpapers",
    setWall: ctx.home + "/.config/sway/scripts/wallpaper-pick.sh",
    stylesDir: ctx.home + "/.config/armoji-styles",
  }
}

function power(arg) {
  const a = arg.trim().toLowerCase()
  return [["Lock", "system-lock-screen", "swaylock -f"],
          ["Logout", "system-log-out", "swaymsg exit"],
          ["Suspend", "system-suspend", "systemctl suspend"],
          ["Reboot", "system-reboot", "systemctl reboot"],
          ["Shutdown", "system-shutdown", "systemctl poweroff"]]
    .filter(o => o[0].toLowerCase().includes(a))
    .map(o => item(o[0], "", o[1], "cmd", o[2]))
}

function update(arg) {
  const a = arg.trim().toLowerCase()
  return [["Full System Update", "system-software-update", "foot --app-id=float-tui -e yay -Syu"],
          ["Pacman", "system-software-update", "foot --app-id=float-tui -e sudo pacman -Syu"],
          ["AUR (yay)", "system-software-update", "foot --app-id=float-tui -e yay -Sua"],
          ["Kernel", "org.cachyos.KernelManager", "cachyos-kernel-manager"]]
    .filter(o => o[0].toLowerCase().includes(a))
    .map(o => item(o[0], "", o[1], "cmd", o[2]))
}

function styles(ctx, filter) {
  const p = paths(ctx)
  const out = Object.keys(ctx.packs).sort()
    .filter(n => !filter || (n + " " + (ctx.packs[n].title || n)).toLowerCase().includes(filter))
    .map(n => {
      const info = ctx.packs[n]
      let sub = info.description || ""
      if (n === ctx.style) sub = sub ? "active · " + sub : "active"
      return item(info.title || n, sub, "applications-graphics", "cmd", p.theme + " style " + n)
    })
  return out.length ? out : [item("No style packs found", p.stylesDir, "image-missing", "noop")]
}

function wallpapers(ctx, filter) {
  const p = paths(ctx)
  const out = ctx.wallpapers
    .filter(f => /\.(jpe?g|png|webp)$/i.test(f) && (!filter || f.toLowerCase().includes(filter)))
    .map(f => {
      const path = p.wallDir + "/" + f
      return item(f.replace(/\.[^.]+$/, ""), f, path, "cmd", p.setWall + ' "' + path + '"', 56)
    })
  return out.length ? out : [item("No wallpapers found", p.wallDir, "image-missing", "noop")]
}

function set(ctx, arg) {
  // two-level: "/set" shows categories; Style/Colors/Tone/Wallpaper drill down
  // (fill), Wi-Fi/Bluetooth/Monitors run straight away
  const p = paths(ctx)
  const parts = arg.trim().split(/\s+/)
  const sub = (parts[0] || "").toLowerCase()
  const rest = parts.slice(1).join(" ").trim().toLowerCase()
  const info = ctx.packs[ctx.style] || {}
  let cats = [
    ["Style", "style", "applications-graphics", "", "fill", "/set style "],
    ["Colors", "color", "preferences-desktop-theme", "", "fill", "/set color "],
    ["Tone", "tone", "preferences-desktop-display", "", "fill", "/set tone "],
    ["Wallpaper", "wallpaper", "preferences-desktop-wallpaper", "~/Pictures/Wallpapers", "fill", "/set wallpaper "],
    ["Wi-Fi", "wifi", "network-wireless", "", "cmd", "foot --app-id=float-tui -e nmtui"],
    ["Bluetooth", "bluetooth", "bluetooth", "", "cmd", "foot --app-id=float-tui -e bluetuith"],
    ["Monitors", "monitors", "video-display", "", "cmd", "~/.config/sway/scripts/monitors.sh"],
  ]
  if (info.neutral === "1") cats = cats.filter(c => c[1] !== "tone")   // monochrome packs ignore tone
  const known = ["style", "styles", "color", "colors", "tone", "wallpaper", "wall",
                 "wifi", "bluetooth", "blue", "monitors", "monitor", "displays"]
  if (!known.includes(sub))
    return cats.filter(c => c[0].toLowerCase().includes(sub) || c[1].includes(sub))
               .map(c => item(c[0], c[3], c[2], c[4], c[5]))
  if (sub === "style" || sub === "styles") return styles(ctx, rest)
  if (sub === "color" || sub === "colors") {
    const allowed = (info.allowed_palettes || "").split(/\s+/).filter(s => s)
    return (allowed.length ? allowed : PALETTES).filter(x => x.toLowerCase().includes(rest))
      .map(x => item(x, "palette", "preferences-desktop-theme", "cmd", p.theme + " apply " + x))
  }
  if (sub === "tone")
    return ["light", "heavy", "loud"].filter(t => t.includes(rest))
      .map(t => item(t[0].toUpperCase() + t.slice(1), "intensity", "preferences-desktop-display",
                     "cmd", p.theme + " tone " + t))
  if (sub === "wallpaper" || sub === "wall") return wallpapers(ctx, rest)
  if (sub === "wifi") return [item("Wi-Fi (nmtui)", "", "network-wireless", "cmd", "foot --app-id=float-tui -e nmtui")]
  if (sub === "monitors" || sub === "monitor" || sub === "displays")
    return [item("Monitors (nwg-displays)", "", "video-display", "cmd", "~/.config/sway/scripts/monitors.sh")]
  return [item("Bluetooth (bluetuith)", "", "bluetooth", "cmd", "foot --app-id=float-tui -e bluetuith")]
}

function web(arg) {
  const q = arg.trim()
  if (!q) return [item("Type a query to search the web…", "", "web-browser", "noop")]
  const url = "https://www.google.com/search?q=" + encodeURIComponent(q)
  return [item("Search the web for “" + q + "”", "google · zen", "web-browser", "cmd", 'zen-browser "' + url + '"')]
}

// keybind cheat-sheet — mirrors the sway config
const KEYBINDS = [
  ["Win + T", "Open terminal (foot)"],
  ["Win + E", "Open file manager (Nemo)"],
  ["Win + W", "Open web browser (Zen)"],
  ["Win + D", "Toggle Spotlight launcher"],
  ["Win + Q", "Close focused window"],
  ["Win + Space", "Toggle floating"],
  ["Win + F", "Toggle fullscreen"],
  ["Win + L", "Lock screen"],
  ["Win + N", "Toggle notification center"],
  ["Win + R", "Toggle terminal sidebar"],
  ["Win + Shift + R", "Toggle Claude Code sidebar"],
  ["Win + Shift + S", "Screenshot region → clipboard"],
  ["Win + Ctrl + S", "Screenshot entire screen → clipboard"],
  ["Win + drag", "Move window (left-drag) / resize (right-drag)"],
  ["Win + 1…0", "Switch workspace (per-monitor)"],
  ["Win + Shift + 1…0", "Move window to workspace and follow"],
  ["Win + Alt + 1…0", "Move whole workspace to slot and follow"],
]

function keys(arg) {
  const a = arg.trim().toLowerCase()
  const hits = KEYBINDS.slice().sort((x, y) => x[0].toLowerCase().localeCompare(y[0].toLowerCase()))
    .filter(k => k[0].toLowerCase().includes(a) || k[1].toLowerCase().includes(a))
  return hits.length ? hits.map(k => item(k[0], k[1], "input-keyboard", "noop"))
                     : [item("No matching shortcut", "", "dialog-question", "noop")]
}

const COMMANDS = ["/power", "/set", "/web", "/keys", "/update"]

// text starting with "/": a command's items, or matching command suggestions
function run(ctx, text) {
  const i = text.indexOf(" ")
  const head = i < 0 ? text : text.slice(0, i)
  const arg = i < 0 ? "" : text.slice(i + 1)
  switch (head) {
    case "/power": return power(arg)
    case "/update": return update(arg)
    case "/set": return set(ctx, arg)
    case "/web": return web(arg)
    case "/keys": return keys(arg)
  }
  const sugg = COMMANDS.filter(c => c.startsWith(head)).map(c => item(c, "command", "utilities-terminal", "fill", c + " "))
  return sugg.length ? sugg : [item("No such command", "", "dialog-error", "noop")]
}

// parse `elephant query --json` output (one JSON object per line)
function elephant(out) {
  const items = []
  for (const line of out.split("\n")) {
    if (!line.trim()) continue
    let it
    try { it = JSON.parse(line).item } catch (e) { continue }
    if (!it) continue
    const calc = it.provider === "calc"
    items.push(item(it.text || "", it.subtext || "", it.icon || "",
                    calc ? "calc" : "launch", calc ? (it.text || "") : (it.identifier || "")))
  }
  return items
}

// pack.conf key=value lines → object
function packConf(text) {
  const info = {}
  for (let line of text.split("\n")) {
    line = line.split("#")[0].trim()
    const i = line.indexOf("=")
    if (i > 0) info[line.slice(0, i).trim()] = line.slice(i + 1).trim().replace(/^"|"$/g, "")
  }
  return info
}
