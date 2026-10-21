// Spotlight's own commands: one per settings page (/wifi /bluetooth /monitors
// /style /tone /colors /wallpaper /power /keys /update, /settings = the hub)
// plus /web, ported from the Python armoji-spotlight. Each returns a list of items:
//   { text, subtext, icon, kind: launch|cmd|fill|calc|noop|page, value, iconPx }
// kind page: value names a page shown inside Spotlight's box (Page*.qml, or
// term:<shell command> for SpotTerm)
// `ctx` = { home, style, packs: {name: {title, description, allowed_palettes, neutral}},
//           wallpapers: [file names] } — gathered by Spotlight.qml on open.
.pragma library

const PALETTES = ["wallpaper", "ruby", "orange", "dandelion", "emerald",
                  "cobalt", "bubblegum", "purpur", "b&w"]

// seed colors of the named palettes (mirrors theme.sh resolve()) — swatches
var SEEDS = { ruby: "#e35d6a", orange: "#f28744", dandelion: "#f2c94c", emerald: "#3ecf82",
  cobalt: "#5480f2", bubblegum: "#f06ec3", purpur: "#a06ef0", "b&w": "#e8eaef",
  red: "#D71921", green: "#4A9E5C", blue: "#5B9BF6", yellow: "#D4A843" }
function palettes(ctx) {
  const allowed = ((ctx.packs[ctx.style] || {}).allowed_palettes || "").split(/\s+/).filter(s => s)
  return allowed.length ? allowed : PALETTES
}

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
  // run inside Spotlight's box (SpotTerm.qml); Kernel Manager is its own GUI
  return [["Full System Update", "system-software-update", "page", "term:yay -Syu"],
          // pull the latest armojidots; stowed symlinks pick the new files up
          // (the shell reloads itself — open sidebar sessions restart)
          ["Dotfiles", "folder-git", "page", "term:cd ~/dotfiles && git pull --ff-only"],
          ["Pacman", "system-software-update", "page", "term:sudo pacman -Syu"],
          ["AUR (yay)", "system-software-update", "page", "term:yay -Sua"],
          ["Kernel", "org.cachyos.KernelManager", "cmd", "cachyos-kernel-manager"]]
    .filter(o => o[0].toLowerCase().includes(a))
    .map(o => item(o[0], "", o[1], o[2], o[3]))
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

function colors(ctx, filter) {
  const p = paths(ctx)
  return palettes(ctx).filter(x => x.toLowerCase().includes(filter))
    .map(x => item(x, "palette", "preferences-desktop-theme", "cmd", p.theme + " apply " + x))
}

function tones(ctx, filter) {
  const p = paths(ctx)
  return ["light", "heavy", "loud"].filter(t => t.includes(filter))
    .map(t => item(t[0].toUpperCase() + t.slice(1), "intensity", "preferences-desktop-display",
                   "cmd", p.theme + " tone " + t))
}

function web(arg) {
  const q = arg.trim()
  if (!q) return [item("Type a query to search the web…", "", "web-browser", "noop")]
  const url = "https://www.google.com/search?q=" + encodeURIComponent(q)
  return [item("Search the web for “" + q + "”", "google · zen", "web-browser", "cmd", 'zen-browser "' + url + '"')]
}

// keybind cheat-sheet — mirrors the sway config
const KEYBINDS = [
  ["Win + T", "Open terminal (kitty)"],
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

// command → its page ("" = /web, which is a list). Order matters for
// prefixes: /w → /wifi, /we → /web, /wa → /wallpaper.
const COMMANDS = [["/settings", "hub"], ["/wifi", "wifi"], ["/web", ""], ["/wallpaper", "wallpaper"],
  ["/bluetooth", "bluetooth"], ["/monitors", "monitors"], ["/displays", "monitors"], ["/style", "style"],
  ["/tone", "style"], ["/colors", "colors"], ["/power", "power"], ["/keys", "keys"], ["/update", "updates"]]
// the command a typed head means: exact or by prefix; "/" alone = /settings
function command(head) {
  head = head.toLowerCase()
  if (head === "/") return COMMANDS[0]
  return COMMANDS.find(c => c[0].startsWith(head)) ?? null
}
function split(text) {
  const t = text.trim(), i = t.indexOf(" ")
  return [i < 0 ? t : t.slice(0, i), i < 0 ? "" : t.slice(i + 1).trim().toLowerCase()]
}

// the page a "/" query shows; unknown commands land on the hub
function pageFor(text) {
  if (!text.trim().startsWith("/")) return ""
  const c = command(split(text)[0])
  return c ? c[1] : "hub"
}
// true when the query has an argument for Enter to act on (/colors ruby,
// /power reboot), not just the page's own command
function quickArg(text) { return split(text)[1] !== "" }

// a "/" query's quick items (what Enter runs; the list itself only for /web)
function run(ctx, text) {
  const [head, arg] = split(text)
  switch (command(head)?.[0]) {
    case "/power": return power(arg)
    case "/update": return update(arg)
    case "/style": return styles(ctx, arg)
    case "/tone": return tones(ctx, arg)
    case "/colors": return colors(ctx, arg)
    case "/wallpaper": return wallpapers(ctx, arg)
    case "/web": return web(arg)
    case "/keys": return keys(arg)
  }
  return []
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
