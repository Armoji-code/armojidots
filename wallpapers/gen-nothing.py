#!/usr/bin/env python3
"""Nothing-style dot-matrix wallpapers (landscape 2560x1440).

usage: gen-nothing.py [ACCENT_HEX] [OUT_DIR]
  ACCENT_HEX  default #D71921 (red); the RGBY accents: #4A9E5C #5B9BF6 #D4A843
  OUT_DIR     default ~/Pictures/Wallpapers   (files: nothing-<n>-<name>[-<color>].png)
"""
import math, os, sys
from PIL import Image, ImageDraw, ImageFont

W, H, SS = 2560, 1440, 2          # output size, supersample factor (anti-aliasing)
BG = (10, 10, 10)
ACC = sys.argv[1] if len(sys.argv) > 1 else "#D71921"
OUT = os.path.expanduser(sys.argv[2] if len(sys.argv) > 2 else "~/Pictures/Wallpapers")
DOTO = os.path.expanduser("~/.local/share/fonts/nothing-design/Doto.ttf")
ACC_RGB = tuple(int(ACC[i:i + 2], 16) for i in (1, 3, 5))
TAG = {"#D71921": "", "#4A9E5C": "-green", "#5B9BF6": "-blue", "#D4A843": "-yellow"}.get(ACC.upper(), "-" + ACC[1:].lower())


def canvas():
    im = Image.new("RGB", (W * SS, H * SS), BG)
    return im, ImageDraw.Draw(im)


def mix(a, b, t):
    t = max(0.0, min(1.0, t))
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))


def dot(d, x, y, r, c):
    x, y, r = x * SS, y * SS, r * SS
    d.ellipse((x - r, y - r, x + r, y + r), fill=c)


def save(im, name):
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, f"nothing-{name}{TAG}.png")
    im.resize((W, H), Image.LANCZOS).save(path, optimize=True)
    print(path)


def grid(d, pitch, r, c, ox=0, oy=0):
    for gy in range(oy, H + pitch, pitch):
        for gx in range(ox, W + pitch, pitch):
            dot(d, gx, gy, r, c)


# 1 — dot grid with an accent glow: dots near a focus point light up and swell
def n1():
    im, d = canvas()
    pitch, fx, fy, R = 40, 0.68 * W, 0.42 * H, 330
    for gy in range(20, H, pitch):
        for gx in range(20, W, pitch):
            t = 1 - math.hypot(gx - fx, gy - fy) / R
            if t > 0:
                dot(d, gx, gy, 2.4 + 4.5 * t * t, mix((38, 38, 38), ACC_RGB, t ** 0.8))
            else:
                dot(d, gx, gy, 2.4, (34, 34, 34))
    save(im, "01-glow")


# 2 — halftone: staggered grid, dot size follows a smooth diagonal gradient
def n2():
    im, d = canvas()
    pitch = 28
    for row, gy in enumerate(range(0, H + pitch, pitch)):
        for gx in range(-pitch, W + pitch, pitch):
            x = gx + (pitch / 2 if row % 2 else 0)
            v = 1 - math.hypot(x - 0.05 * W, gy - 1.05 * H) / (0.95 * W)
            v = max(0.0, v)
            dot(d, x, gy, 0.8 + 11 * v ** 1.6, mix((32, 32, 32), (214, 214, 214), v ** 1.2))
    dot(d, 0.86 * W, 0.2 * H, 15, ACC_RGB)
    save(im, "02-halftone")


# 3 — rings made of dots, one accent ring, centred right
def n3():
    im, d = canvas()
    cx, cy, step = 0.72 * W, 0.5 * H, 58
    dot(d, cx, cy, 10, ACC_RGB)
    for i in range(1, 22):
        rad = i * step
        n = max(6, round(2 * math.pi * rad / 34))
        fade = max(0.0, 1 - i / 22)
        col = ACC_RGB if i == 7 else mix((28, 28, 28), (150, 150, 150), fade)
        for k in range(n):
            a = 2 * math.pi * k / n
            dot(d, cx + rad * math.cos(a), cy + rad * math.sin(a), 3.4 if i == 7 else 2.6, col)
    save(im, "03-rings")


# 4 — ridge plot: rows of dots displaced by a travelling wave, middle row accent
def n4():
    im, d = canvas()
    rows, pitch = 27, 26
    for r in range(rows):
        y0 = 0.14 * H + r * (0.72 * H / (rows - 1))
        for gx in range(0, W + pitch, pitch):
            u = gx / W
            env = math.exp(-((u - 0.55) ** 2) / 0.05)
            dy = -70 * env * math.sin(u * 22 + r * 0.42) * (0.4 + 0.6 * math.sin(r / rows * math.pi))
            accent = r == rows // 2
            dot(d, gx, y0 + dy, 3.4 if accent else 2.4,
                ACC_RGB if accent else mix((30, 30, 30), (120, 120, 120), env + 0.15))
    save(im, "04-ridge")


# 5 — big dot-matrix word over a faint grid
def n5():
    im, d = canvas()
    grid(d, 40, 1.8, (22, 22, 22), 20, 20)
    f = ImageFont.truetype(DOTO, 470 * SS)
    f.set_variation_by_axes([100, 900])
    d.text((150 * SS, 700 * SS), "ARMOJI", font=f, fill=(70, 70, 70))
    dot(d, 2360, 1250, 18, ACC_RGB)
    save(im, "05-word")


# 6 — glyph equalizer: columns of dots rising from the bottom, accent caps
def n6():
    im, d = canvas()
    pitch = 34
    cols = W // pitch
    for c in range(cols):
        gx = c * pitch + pitch / 2
        u = c / cols
        h = 5 + 34 * (0.5 + 0.5 * math.sin(u * 9 + 1.3)) * (0.35 + 0.65 * math.sin(u * 3.1 + 0.5) ** 2)
        n = int(h)
        for k in range(n + 1):
            gy = H - 60 - k * pitch
            if gy < 0:
                break
            top = k == n
            dot(d, gx, gy, 3.6 if top else 2.6,
                ACC_RGB if top else mix((40, 40, 40), (190, 190, 190), (k / max(n, 1)) ** 1.5))
    save(im, "06-glyph")



# ───────── series 2: shapes, gradients, blur (greys + accent) ─────────
import random
import numpy as np
from PIL import ImageFilter


def gradient_bg(top=(9, 9, 9), bottom=(26, 26, 26), diag=0.0):
    y = np.linspace(0, 1, H)[:, None]
    x = np.linspace(0, 1, W)[None, :]
    t = np.clip(y * (1 - diag) + x * diag, 0, 1)
    arr = np.zeros((H, W, 3), np.float32)
    for i in range(3):
        arr[..., i] = top[i] + (bottom[i] - top[i]) * t
    return arr


def to_img(arr):
    return Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGB")


def finish2(arr, name, grain=2.4, vignette=0.35):
    rng = np.random.default_rng(7)
    y, x = np.mgrid[0:H, 0:W].astype(np.float32)
    v = 1 - vignette * (((x - W / 2) / (W / 2)) ** 2 + ((y - H / 2) / (H / 2)) ** 2) / 2
    arr = arr * v[..., None] + rng.normal(0, grain, arr.shape).astype(np.float32)
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, f"nothing-{name}{TAG}.png")
    to_img(arr).save(path, optimize=True)
    print(path)


def over(arr, layer_rgba):
    """alpha-composite a PIL RGBA layer onto the float array"""
    a = np.asarray(layer_rgba, np.float32)
    al = a[..., 3:4] / 255.0
    return arr * (1 - al) + a[..., :3] * al


def blur_layer(draw_fn, radius, size=None):
    layer = Image.new("RGBA", size or (W, H), (0, 0, 0, 0))
    draw_fn(ImageDraw.Draw(layer))
    return layer.filter(ImageFilter.GaussianBlur(radius)) if radius else layer


def sphere(arr, cx, cy, r, base, light=(-0.55, -0.6), ambient=0.18, rim=None):
    x0, x1 = int(max(0, cx - r - 2)), int(min(W, cx + r + 2))
    y0, y1 = int(max(0, cy - r - 2)), int(min(H, cy + r + 2))
    yy, xx = np.mgrid[y0:y1, x0:x1].astype(np.float32)
    nx, ny = (xx - cx) / r, (yy - cy) / r
    d2 = nx * nx + ny * ny
    cov = np.clip((1 - np.sqrt(d2)) * r, 0, 1)[..., None]          # anti-aliased edge
    nz = np.sqrt(np.clip(1 - d2, 0, 1))
    lz = math.sqrt(max(0.0, 1 - light[0] ** 2 - light[1] ** 2))
    lam = np.clip(nx * light[0] + ny * light[1] + nz * lz, 0, 1)
    col = np.array(base, np.float32)[None, None, :] * (ambient + (1 - ambient) * lam[..., None] ** 1.5)
    if rim:
        edge = np.clip(1 - nz, 0, 1)[..., None] ** 3
        col = col + np.array(rim, np.float32)[None, None, :] * edge
    arr[y0:y1, x0:x1] = arr[y0:y1, x0:x1] * (1 - cov) + col * cov
    return arr


def glow(arr, cx, cy, r, color, strength=0.5):
    y, x = np.mgrid[0:H, 0:W].astype(np.float32)
    g = np.exp(-(((x - cx) ** 2 + (y - cy) ** 2) / (2 * r * r)))[..., None] * strength
    return arr + np.array(color, np.float32)[None, None, :] * g


# 7 — soft spheres: shaded greys, one red sphere with a halo
def n7():
    arr = gradient_bg((10, 10, 10), (24, 24, 24), diag=0.35)
    arr = glow(arr, 0.78 * W, 0.62 * H, 420, ACC_RGB, 0.16)
    sh = blur_layer(lambda d: d.ellipse((0.12 * W, 0.62 * H, 0.52 * W, 0.98 * H), fill=(0, 0, 0, 150)), 90)
    arr = over(arr, sh)
    arr = sphere(arr, 0.30 * W, 0.62 * H, 470, (190, 190, 190))
    arr = sphere(arr, 0.62 * W, 0.28 * H, 230, (120, 120, 120))
    arr = sphere(arr, 0.83 * W, 0.60 * H, 110, ACC_RGB, rim=(60, 20, 20))
    arr = sphere(arr, 0.50 * W, 0.80 * H, 54, (150, 150, 150))
    arr = sphere(arr, 0.92 * W, 0.20 * H, 34, (90, 90, 90))
    finish2(arr, "07-orbs")


# 8 — frosted glass: rounded cards that really blur what is behind them
def n8():
    arr = gradient_bg((10, 10, 10), (22, 22, 22), diag=0.6)
    bl = blur_layer(lambda d: (
        d.ellipse((0.50 * W, 0.18 * H, 0.82 * W, 0.78 * H), fill=ACC_RGB + (255,)),
        d.ellipse((0.10 * W, 0.40 * H, 0.38 * W, 0.95 * H), fill=(170, 170, 170, 255)),
        d.ellipse((0.28 * W, -0.10 * H, 0.52 * W, 0.34 * H), fill=(90, 90, 90, 255))), 36)
    arr = over(arr, bl)
    base = to_img(arr)
    blurred = base.filter(ImageFilter.GaussianBlur(46))
    cards = [(0.14, 0.18, 0.46, 0.62, 70), (0.40, 0.34, 0.80, 0.86, 90), (0.62, 0.10, 0.90, 0.40, 60)]
    out = base.copy()
    for (a, b, c, d_, rad) in cards:
        box = (int(a * W), int(b * H), int(c * W), int(d_ * H))
        mask = Image.new("L", (W * SS, H * SS), 0)
        ImageDraw.Draw(mask).rounded_rectangle([v * SS for v in box], rad * SS, fill=255)
        mask = mask.resize((W, H), Image.LANCZOS)
        out = Image.composite(blurred, out, mask)
        tint = Image.new("RGB", (W, H), (255, 255, 255))
        out = Image.composite(Image.blend(out, tint, 0.05), out, mask)
        line = Image.new("L", (W * SS, H * SS), 0)
        ImageDraw.Draw(line).rounded_rectangle([v * SS for v in box], rad * SS, outline=255, width=2 * SS)
        line = line.resize((W, H), Image.LANCZOS).point(lambda v: int(v * 0.18))
        out = Image.composite(Image.new("RGB", (W, H), (255, 255, 255)), out, line)
    finish2(np.asarray(out, np.float32), "08-glass", grain=1.8)


# 9 — eclipse: a black disc on a soft grey field with a crescent rim light
def n9():
    arr = gradient_bg((12, 12, 12), (12, 12, 12))
    y, x = np.mgrid[0:H, 0:W].astype(np.float32)
    cx, cy, R = 0.62 * W, 0.50 * H, 430
    d = np.sqrt((x - cx) ** 2 + (y - cy) ** 2)
    arr += (np.exp(-((d - R) ** 2) / (2 * 520 ** 2)) * 26)[..., None]          # soft field behind
    big = Image.new("L", (W * SS, H * SS), 0)
    ImageDraw.Draw(big).ellipse(((cx - R - 22) * SS, (cy - R - 22) * SS, (cx + R + 22) * SS, (cy + R + 22) * SS), fill=255)
    ImageDraw.Draw(big).ellipse(((cx - R + 26) * SS, (cy - R + 34) * SS, (cx + R + 70) * SS, (cy + R + 78) * SS), fill=0)
    rim = big.resize((W, H), Image.LANCZOS)
    for rad, a in ((70, 0.55), (22, 0.7), (4, 1.0)):
        m = np.asarray(rim.filter(ImageFilter.GaussianBlur(rad)), np.float32)[..., None] / 255 * a
        arr = arr + np.array(ACC_RGB, np.float32)[None, None, :] * m
    disc = np.clip((R - d), 0, 1)[..., None]
    arr = arr * (1 - disc) + np.array((5, 5, 5), np.float32) * disc
    finish2(arr, "09-eclipse", vignette=0.45)


# 10 — ribbons: layered flowing bands, one thin accent line
def n10():
    arr = gradient_bg((10, 10, 10), (20, 20, 20), diag=0.5)
    xs = np.linspace(0, W, 400)
    layer_specs = [(0.36, 190, 0.0, 0.0030, 210, 0.07), (0.46, 230, 0.8, 0.0024, 260, 0.09),
                   (0.57, 160, 1.7, 0.0034, 190, 0.11), (0.67, 210, 2.6, 0.0028, 240, 0.14),
                   (0.78, 140, 3.4, 0.0036, 170, 0.18)]
    for (c, amp, ph, f, th, a) in layer_specs:
        top = [(float(x), c * H + amp * math.sin(x * f + ph)) for x in xs]
        bot = [(float(x), c * H + amp * math.sin(x * f + ph) + th) for x in xs[::-1]]

        def draw(d, top=top, bot=bot, a=a):
            d.polygon(top + bot, fill=(255, 255, 255, int(255 * a)))
        arr = over(arr, blur_layer(draw, 5))
    line = [(float(x), 0.62 * H + 205 * math.sin(x * 0.0028 + 2.6) + 4) for x in xs]
    arr = over(arr, blur_layer(lambda d: d.line(line, fill=ACC_RGB + (255,), width=5), 22))
    arr = over(arr, blur_layer(lambda d: d.line(line, fill=ACC_RGB + (255,), width=3), 0))
    finish2(arr, "10-ribbons")


# 11 — mesh wash: huge blurred blobs, greys and one deep accent
def n11():
    arr = gradient_bg((8, 8, 8), (14, 14, 14))
    blobs = [(0.15, 0.20, 520, (120, 120, 120, 230)), (0.45, 0.80, 600, (70, 70, 70, 230)),
             (0.85, 0.25, 460, (150, 150, 150, 200)), (0.72, 0.82, 520, ACC_RGB + (235,)),
             (0.05, 0.92, 380, (40, 40, 40, 255)), (0.55, 0.10, 330, (60, 60, 60, 255))]
    for (bx, by, br, col) in blobs:
        arr = over(arr, blur_layer(lambda d, bx=bx, by=by, br=br, col=col:
                                   d.ellipse((bx * W - br, by * H - br, bx * W + br, by * H + br), fill=col), 230))
    finish2(arr * 0.82, "11-mesh", grain=3.0, vignette=0.4)


# 12 — glyph bars: vertical capsules with glow, one accent
def n12():
    arr = gradient_bg((9, 9, 9), (17, 17, 17))
    heights = [0.34, 0.52, 0.78, 0.46, 0.64, 0.30, 0.58, 0.40]
    bw, gap = 118, 62
    total = len(heights) * bw + (len(heights) - 1) * gap
    x0 = (W - total) / 2
    for i, hf in enumerate(heights):
        hh = hf * H * 0.8
        x = x0 + i * (bw + gap)
        y1 = H * 0.88
        col = ACC_RGB if i == 2 else (205, 205, 205)
        rect = (x, y1 - hh, x + bw, y1)
        arr = over(arr, blur_layer(lambda d, r=rect, c=col: d.rounded_rectangle(r, bw // 2, fill=c + (110,)), 55))
        base = Image.new("RGBA", (W * SS, H * SS), (0, 0, 0, 0))
        dr = ImageDraw.Draw(base)
        dr.rounded_rectangle([v * SS for v in rect], bw // 2 * SS, fill=mix((34, 34, 34), col, 0.82 if i == 2 else 0.14) + (255,))
        arr = over(arr, base.resize((W, H), Image.LANCZOS))
    finish2(arr, "12-bars")


# 13 — the UI's own shapes: circle, pill, rounded square, drifting over a soft field
def n13():
    arr = gradient_bg((12, 12, 12), (25, 25, 25), diag=0.5)
    arr = glow(arr, 0.5 * W, 0.5 * H, 700, (120, 120, 120), 0.10)

    def shape(kind, cx, cy, w, h, angle, c1, c2, alpha=255, outline=None):
        pad = 260
        sz = (int(w + 2 * pad), int(h + 2 * pad)) if kind != "circle" else (int(w + 2 * pad),) * 2
        lay = Image.new("RGBA", (sz[0] * SS, sz[1] * SS), (0, 0, 0, 0))
        grad = Image.new("RGBA", lay.size)
        g = np.linspace(0, 1, lay.size[1])[:, None, None]
        garr = np.array(c1, np.float32) * (1 - g) + np.array(c2, np.float32) * g
        grad = Image.fromarray(np.dstack([np.broadcast_to(garr, (lay.size[1], lay.size[0], 3)).astype(np.uint8),
                                          np.full((lay.size[1], lay.size[0]), alpha, np.uint8)]), "RGBA")
        m = Image.new("L", lay.size, 0)
        box = [pad * SS, pad * SS, (pad + w) * SS, (pad + h) * SS]
        md = ImageDraw.Draw(m)
        if kind == "circle":
            md.ellipse(box, fill=255)
        elif kind == "pill":
            md.rounded_rectangle(box, h * SS / 2, fill=255)
        else:
            md.rounded_rectangle(box, 70 * SS, fill=255)
        lay.paste(grad, (0, 0), m)
        if outline:
            ImageDraw.Draw(lay).rounded_rectangle(box, (h / 2 if kind == "pill" else 70) * SS, outline=outline, width=2 * SS) \
                if kind != "circle" else ImageDraw.Draw(lay).ellipse(box, outline=outline, width=2 * SS)
        lay = lay.resize((lay.width // SS, lay.height // SS), Image.LANCZOS).rotate(angle, resample=Image.BICUBIC, expand=True)
        shadow = lay.copy()
        shadow.putalpha(lay.getchannel("A").point(lambda v: int(v * 0.55)))
        shadow = Image.merge("RGBA", (Image.new("L", lay.size, 0),) * 3 + (shadow.getchannel("A"),)).filter(ImageFilter.GaussianBlur(40))
        full = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        pos = (int(cx - lay.width / 2), int(cy - lay.height / 2))
        full.alpha_composite(shadow, (pos[0], pos[1] + 36)) if 0 <= pos[0] and 0 <= pos[1] else None
        return full, lay, pos

    def put(a, spec):
        full, lay, pos = spec
        sh = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        sh_l = Image.merge("RGBA", (Image.new("L", lay.size, 0),) * 3 + (lay.getchannel("A").point(lambda v: int(v * 0.6)),)).filter(ImageFilter.GaussianBlur(38))
        sh.alpha_composite(sh_l, (pos[0], pos[1] + 40)) if True else None
        a = over(a, sh)
        top = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        top.alpha_composite(lay, pos)
        return over(a, top)

    arr = put(arr, shape("circle", 0.30 * W, 0.56 * H, 640, 640, 0, (88, 88, 88), (30, 30, 30), outline=(255, 255, 255, 40)))
    arr = put(arr, shape("pill", 0.66 * W, 0.40 * H, 1000, 300, -16, (120, 120, 120), (46, 46, 46), outline=(255, 255, 255, 46)))
    arr = put(arr, shape("square", 0.74 * W, 0.74 * H, 400, 400, 14, (62, 62, 62), (22, 22, 22), outline=(255, 255, 255, 36)))
    arr = put(arr, shape("circle", 0.50 * W, 0.80 * H, 150, 150, 0, ACC_RGB, tuple(int(c * 0.55) for c in ACC_RGB)))
    arr = put(arr, shape("pill", 0.20 * W, 0.18 * H, 340, 100, 0, (200, 200, 200), (140, 140, 140)))
    finish2(arr, "13-shapes")


# 14 — dial: broken concentric arcs with glow, one accent arc
def n14():
    arr = gradient_bg((9, 9, 9), (18, 18, 18), diag=0.4)
    cx, cy = 0.64 * W, 0.52 * H
    rnd = random.Random(11)
    lay = Image.new("RGBA", (W * SS, H * SS), (0, 0, 0, 0))
    d = ImageDraw.Draw(lay)
    acc_ring = 5
    for i, rad in enumerate(range(150, 760, 78)):
        start = rnd.uniform(0, 360)
        for seg in range(rnd.randint(1, 3)):
            a0 = start + seg * rnd.uniform(110, 170)
            span = rnd.uniform(40, 120)
            col = ACC_RGB if (i == acc_ring and seg == 0) else mix((46, 46, 46), (190, 190, 190), 1 - i / 8)
            w = 26 if i == acc_ring and seg == 0 else 18
            d.arc((cx - rad, cy - rad, cx + rad, cy + rad), a0, a0 + span, fill=col + (255,), width=w) if SS == 1 else \
                d.arc(((cx - rad) * SS, (cy - rad) * SS, (cx + rad) * SS, (cy + rad) * SS), a0, a0 + span, fill=col + (255,), width=w * SS)
    crisp = lay.resize((W, H), Image.LANCZOS)
    arr = over(arr, crisp.filter(ImageFilter.GaussianBlur(26)))
    arr = over(arr, crisp)
    arr = glow(arr, cx, cy, 160, (255, 255, 255), 0.06)
    finish2(arr, "14-dial")


for fn in (n1, n2, n3, n4, n5, n6, n7, n8, n9, n10, n11, n12, n13, n14):
    fn()
