#!/usr/bin/env python3
"""Pixel-art special-attack animations for the six VS characters -> assets/fx/<char>_<cast|hit>.png

Each file is a horizontal strip of FR frames, every frame N x N pixel-grid cells enlarged UP x (nearest).
  cast: charge-up at the caster (particles converge, glyph flash, ring)
  hit:  the attack landing on the opponent's board (wall, fire rain, ice spikes, lightning, slashes, boulder)
Run: python3 tools/gen_fx.py   (needs Pillow). Everything is code-drawn and deterministic.
"""
import math
import os
import random

from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
OUT = os.path.join(ROOT, "assets", "fx")
N, UP, FR = 64, 3, 8
INK = (22, 16, 34, 255)
GROUND = 56

# ramps: brightest -> darkest
RAMPS = {
    "bastion": ["#ffffff", "#bfe3ff", "#4ab0ff", "#2a5ac8"],
    "blaze": ["#fff6c0", "#ffcd4a", "#ef6a2a", "#a8141a"],
    "frost": ["#ffffff", "#c8f4ff", "#58c8f8", "#2a6ac8"],
    "volt": ["#ffffff", "#fff08a", "#ffc21a", "#8a52d8"],
    "shade": ["#ffffff", "#ff8ae8", "#c040ff", "#4a1a8a"],
    "titan": ["#f4ffc0", "#a8e83a", "#7a6a48", "#3a3024"],
}


def rgb(h):
    return tuple(int(h[i:i + 2], 16) for i in (1, 3, 5)) + (255,)


def ramp(name):
    return [rgb(c) for c in RAMPS[name]]


def canvas():
    im = Image.new("RGBA", (N, N), (0, 0, 0, 0))
    return im, ImageDraw.Draw(im)


def outline(im):
    a = im.getchannel("A")
    ring = Image.eval(a.filter(ImageFilter.MaxFilter(3)), lambda v: 255 if v > 0 else 0)
    edge = Image.composite(Image.new("RGBA", im.size, INK), Image.new("RGBA", im.size, (0, 0, 0, 0)), ring)
    return Image.alpha_composite(edge, im)


def clamp(v, a=0.0, b=1.0):
    return max(a, min(b, v))


def disc(d, x, y, r, c):
    if r >= 0.5:
        d.ellipse((x - r, y - r, x + r - 0.01, y + r - 0.01), fill=c)


def ring(d, x, y, r, w, c):
    if r >= 1:
        d.ellipse((x - r, y - r, x + r, y + r), outline=c, width=max(1, int(round(w))))


def star(d, x, y, r, c):
    d.line((x - r, y, x + r, y), fill=c); d.line((x, y - r, x, y + r), fill=c)
    d.point((x, y), fill=c)


def thick(d, pts, w, c):
    d.line(pts, fill=c, width=w, joint="curve")


# ------------------------------------------------------------------ cast (charge-up) for every character

GLYPHS = {  # polygons around (0,0), radius ~ 1
    "bastion": [(-.8, -.8), (.8, -.8), (.8, .3), (0, 1), (-.8, .3)],        # shield
    "blaze": [(0, -1), (.7, 0), (.3, .9), (-.3, .9), (-.7, 0)],              # flame
    "frost": [(0, -1), (.6, 0), (0, 1), (-.6, 0)],                           # crystal
    "volt": [(.3, -1), (-.6, .1), (0, .1), (-.3, 1), (.7, -.2), (.1, -.2)],  # bolt
    "shade": [(0, -1), (.9, 0), (0, 1), (-.9, 0)],                           # diamond
    "titan": [(-.7, -.7), (.7, -.7), (.7, .7), (-.7, .7)],                   # block
}


def cast(name, i):
    t = i / (FR - 1)
    c = ramp(name)
    im, d = canvas()
    cx, cy = 32, 32
    rnd = random.Random(11)
    if t < 0.62:
        k = t / 0.62
        for j in range(16):
            a = rnd.random() * math.tau
            r0 = 27 + rnd.random() * 5
            r = r0 * (1 - k) ** 1.2 + 3
            x, y = cx + math.cos(a) * r, cy + math.sin(a) * r
            disc(d, x + 1, y + 1, 1.5, c[1])
            d.point((x + math.cos(a) * 4, y + math.sin(a) * 4), fill=c[2])
        disc(d, cx, cy, 2 + k * 6, c[2])
        disc(d, cx, cy, 1 + k * 3, c[0])
    elif t < 0.86:
        k = (t - 0.62) / 0.24
        disc(d, cx, cy, 15 - k * 4, c[0])
        gl = [(cx + x * 11, cy + y * 11) for x, y in GLYPHS[name]]
        d.polygon(gl, fill=c[1], outline=c[2])
        ring(d, cx, cy, 8 + k * 20, 3 - k * 2, c[1])
        for j in range(8):
            a = j * math.tau / 8
            star(d, cx + math.cos(a) * (10 + k * 14), cy + math.sin(a) * (10 + k * 14), 1, c[0])
    else:
        k = (t - 0.86) / 0.14
        ring(d, cx, cy, 24 + k * 6, max(1, 2 - k * 2), c[2])
        for j in range(6):
            a = j * math.tau / 6 + 0.4
            d.point((cx + math.cos(a) * (22 + k * 8), cy + math.sin(a) * (22 + k * 8)), fill=c[1])
    return im


# ------------------------------------------------------------------ hit (landing) effects

SAND = [rgb(h) for h in ("#fff3d0", "#e8c880", "#b88a4a", "#6a4a2a")]  # the wall is stone and sand, not water


def hit_bastion(i):
    """A heavy slab falls, bursts into sand and settles as a mound over the stack."""
    t = i / (FR - 1)
    c = SAND
    im, d = canvas()
    rnd = random.Random(9)
    if t < 0.3:
        y = -12 + (t / 0.3) ** 2 * (GROUND - 24)
        d.rectangle((12, y, 52, y + 12), fill=c[2])
        d.rectangle((12, y, 52, y + 2), fill=c[0])
        d.line((32, y + 2, 32, y + 12), fill=c[3])
        d.line((12, y + 7, 52, y + 7), fill=c[3])
        im = outline(im)
        return im
    k = (t - 0.3) / 0.7
    for j in range(46):                                   # grains in flight, then at rest
        tx = 32 + rnd.uniform(-26, 26)
        h = rnd.uniform(0, 1)
        land = GROUND - 1 - 9 * (1 - abs(tx - 32) / 26) * h
        fall = clamp(k * 1.6 - rnd.random() * 0.5)
        x = 32 + (tx - 32) * clamp(k * 2.2)
        y = (GROUND - 30 - rnd.random() * 10) + (land - (GROUND - 30)) * fall ** 1.5 - 14 * math.sin(clamp(k * 2.2) * math.pi) * (1 - fall)
        d.rectangle((x, y, x + 1, y + 1), fill=c[1] if j % 3 else c[0])
    mound = 9 * clamp(k * 1.4)
    d.polygon([(8, GROUND), (22, GROUND - mound * 0.8), (32, GROUND - mound), (42, GROUND - mound * 0.8), (56, GROUND)], fill=c[2])
    d.polygon([(14, GROUND), (26, GROUND - mound * 0.6), (32, GROUND - mound * 0.8), (40, GROUND - mound * 0.6), (50, GROUND)], fill=c[3])
    im = outline(im)
    d = ImageDraw.Draw(im)
    if k < 0.7:                                           # dust
        for sdir in (-1, 1):
            for j in range(3):
                disc(d, 32 + sdir * (14 + k * 24 + j * 3), GROUND - 2 - j * 3, max(0, 4 + j - k * 6), c[1])
    return im


def hit_blaze(i):
    t = i / (FR - 1)
    c = ramp("blaze")
    im, d = canvas()
    xs = [12, 24, 34, 44, 54]
    delays = [0.0, 0.18, 0.08, 0.3, 0.2]
    for x0, dl in zip(xs, delays):
        p = (t - dl) / 0.42
        tx, ty = x0 - 8, GROUND
        if 0 <= p < 1:
            x, y = x0 - 8 * p, -6 + (GROUND + 6) * p
            thick(d, [(x + 8, y - 14), (x, y)], 3, c[2])
            thick(d, [(x + 4, y - 7), (x, y)], 1, c[1])
            disc(d, x, y, 3.5, c[1]); disc(d, x, y, 1.8, c[0])
        elif p >= 1:
            k = clamp((p - 1) / 0.9)
            if k < 1:
                disc(d, tx, ty - 2, 7 * (1 - k * 0.4), c[2] if k > 0.4 else c[1])
                disc(d, tx, ty - 3, 4 * (1 - k), c[0])
                for a in (-1, 0, 1):
                    d.point((tx + a * (6 + k * 8), ty - 6 - k * 10 + abs(a) * 4), fill=c[1])
    return outline(im)


def hit_frost(i):
    t = i / (FR - 1)
    c = ramp("frost")
    im, d = canvas()
    for x0, h, dl in ((18, 30, 0.0), (32, 44, 0.12), (46, 28, 0.24)):
        g = clamp((t - dl) / 0.38) ** 0.7
        if g <= 0:
            continue
        tip = GROUND - h * g
        d.polygon([(x0 - 6, GROUND), (x0, tip), (x0 + 6, GROUND)], fill=c[2])
        d.polygon([(x0 - 6, GROUND), (x0, tip), (x0 - 1, GROUND)], fill=c[1])
        d.polygon([(x0 + 2, GROUND), (x0 + 4, GROUND - (GROUND - tip) * 0.45), (x0 + 6, GROUND)], fill=c[3])
        d.line((x0, tip + 2, x0, tip + 6), fill=c[0])
    ice = outline(im)
    d = ImageDraw.Draw(ice)
    d.ellipse((6, GROUND - 3, 58, GROUND + 4), outline=c[1])
    if t > 0.55:
        for (sx, sy, ph) in ((18, 28, 0), (32, 14, 1), (46, 30, 2)):
            if (i + ph) % 2 == 0:
                star(d, sx, sy, 3, c[0])
    return ice


def bolt(rnd, x0, y0, x1, y1, seg=7, jit=7):
    pts = [(x0, y0)]
    n = max(2, int(abs(y1 - y0) / seg))
    for k in range(1, n):
        f = k / n
        pts.append((x0 + (x1 - x0) * f + rnd.uniform(-jit, jit), y0 + (y1 - y0) * f))
    pts.append((x1, y1))
    return pts


def strike(d, c, x, li, rnd):
    """One lightning bolt at column x, li = frames since it started (0 spark ... 6 afterglow)."""
    if li < 0:
        return False
    thick_bolt = li in (2, 3)
    if li == 0:
        star(d, x, 4, 3, c[0]); disc(d, x, 3, 2, c[1])
    elif li <= 4:
        bot = 28 if li == 1 else GROUND
        pts = bolt(rnd, x, 0, x + rnd.randint(-3, 3), bot, seg=7, jit=6)
        w = 5 if thick_bolt else 3
        thick(d, pts, w + 2, c[3]); thick(d, pts, w, c[2]); thick(d, pts, max(1, w - 3), c[0])
        if li >= 3:
            for bx in (-1, 1):
                k = rnd.randint(2, 3)
                br = bolt(rnd, pts[k][0], pts[k][1], pts[k][0] + bx * 9, pts[k][1] + 14, seg=5, jit=2)
                thick(d, br, 3, c[2]); thick(d, br, 1, c[0])
        if li >= 2:
            disc(d, x, GROUND, 9 - (li - 2) * 2, c[0] if li == 2 else c[1])
            ring(d, x, GROUND, 4 + (li - 2) * 5, 2, c[2])
    elif li <= 6:
        k = (li - 5) / 1.5
        for sdir in (-1, 1):
            for j in range(2):
                bx = x + sdir * (5 + j * 6 + k * 4)
                pts = bolt(rnd, bx, GROUND, bx + sdir * 4, GROUND - 5 - j * 3, seg=3, jit=2)
                thick(d, pts, 1 if k > 0.5 else 2, c[1])
    else:
        for j in range(5):
            d.point((x + rnd.randint(-10, 10), rnd.randint(40, 56)), fill=c[0])
    return thick_bolt


def hit_volt(i, x=16):
    """One bolt strikes the left (x=16) or right (x=48) side of the board."""
    c = ramp("volt")
    im, d = canvas()
    strike(d, c, x, i, random.Random(40 + i))
    return outline(im) if 1 <= i <= 5 else im


def hit_shade(i):
    t = i / (FR - 1)
    c = ramp("shade")
    im, d = canvas()

    def slash(x0, y0, x1, y1, p):
        if p <= 0:
            return
        ex, ey = x0 + (x1 - x0) * p, y0 + (y1 - y0) * p
        nx, ny = -(y1 - y0) / 68, (x1 - x0) / 68
        w = 5 * math.sin(clamp(p) * math.pi) + 1
        d.polygon([(x0, y0), (x0 + (ex - x0) / 2 + nx * w * 2, y0 + (ey - y0) / 2 + ny * w * 2), (ex, ey),
                   (x0 + (ex - x0) / 2 - nx * w, y0 + (ey - y0) / 2 - ny * w)], fill=c[2])
        thick(d, [(x0, y0), (ex, ey)], 1, c[0])

    slash(6, 8, 58, 56, clamp(t / 0.28))
    slash(58, 8, 6, 56, clamp((t - 0.12) / 0.28))
    if t > 0.4:
        k = (t - 0.4) / 0.6
        for r in range(6):
            for q in range(6):
                if (r + q) % 2 == 0 and ((r * 7 + q * 3 + i) % 5 != 0 or k < 0.5):
                    s = 7 * (1 - clamp((k - 0.55) * 2.2))
                    if s >= 1:
                        x, y = 11 + q * 8, 11 + r * 8
                        d.rectangle((x, y, x + s - 1, y + s - 1), fill=c[2] if (r + q + i) % 4 else c[1])
    return outline(im)


def hit_titan(i):
    t = i / (FR - 1)
    c = ramp("titan")
    im, d = canvas()
    p = clamp(t / 0.4)
    size = 32  # 5 board cells (a cell is 6.4 sprite pixels)
    y0 = -size + p * p * (GROUND - size + size) if t < 0.4 else GROUND - size
    sh = 0 if t < 0.4 else (1 if i in (3, 5) else 0)
    x0 = 32 - size // 2 + sh
    y0 = int(y0)
    d.rectangle((x0, y0, x0 + size, y0 + size), fill=c[2])
    for k in range(1, 5):
        d.line((x0 + k * size // 5, y0, x0 + k * size // 5, y0 + size), fill=c[3])
        d.line((x0, y0 + k * size // 5, x0 + size, y0 + k * size // 5), fill=c[3])
    d.line((x0, y0, x0 + size, y0), fill=c[0]); d.line((x0, y0, x0, y0 + size), fill=c[1])
    d.line((x0 + 3, y0 + 3, x0 + 8, y0 + 9), fill=c[0]) if t > 0.4 else None
    im = outline(im)
    d = ImageDraw.Draw(im)
    if t >= 0.4:
        k = (t - 0.4) / 0.6
        d.ellipse((32 - 8 - k * 28, GROUND - 3 - k * 3, 32 + 8 + k * 28, GROUND + 3 + k * 3), outline=c[0] if k < 0.5 else c[1])
        rnd = random.Random(5)
        for j in range(10):
            a = -math.pi * (0.1 + 0.8 * rnd.random())
            sp = 20 + rnd.random() * 22
            x = 32 + math.cos(a) * sp * k * 1.4
            y = GROUND + math.sin(a) * sp * k * 1.8 + 60 * k * k
            if y < GROUND + 2:
                disc(d, x, y, 2 - k, c[1] if j % 2 else c[2])
    return im


HITS = {"bastion": hit_bastion, "blaze": hit_blaze, "frost": hit_frost, "volt": hit_volt, "shade": hit_shade, "titan": hit_titan}


def strip(frames):
    s = Image.new("RGBA", (N * FR, N), (0, 0, 0, 0))
    for k, f in enumerate(frames):
        s.paste(f, (k * N, 0))
    return s.resize((N * FR * UP, N * UP), Image.NEAREST)


def main():
    os.makedirs(OUT, exist_ok=True)
    prev = Image.new("RGB", (FR * 96, 12 * 96), (26, 20, 46))
    row = 0
    for name in RAMPS:
        for kind, fn in (("cast", lambda i, n=name: cast(n, i)), ("hit", HITS[name])):
            frames = [fn(i) for i in range(FR)]
            strip(frames).save(os.path.join(OUT, f"{name}_{kind}.png"))
            for k, f in enumerate(frames):
                g = f.resize((96, 96), Image.NEAREST)
                prev.paste(g, (k * 96, row * 96), g)
            row += 1
    strip([hit_volt(i, 48) for i in range(FR)]).save(os.path.join(OUT, "volt_hit_r.png"))  # the bolt on the right side
    prev.save(os.path.join(os.environ.get("SHEET_DIR", "/tmp"), "fx_sheet.png"))
    print("fx written to", OUT)


if __name__ == "__main__":
    main()
