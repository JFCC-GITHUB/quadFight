#!/usr/bin/env python3
"""Generate QuadFight art assets (blocks, background, logo, icons).

Usage:  python3 tools/gen_assets.py      (needs Pillow + numpy)
Outputs into assets/. Re-run after tweaking colours/shapes here.
"""
import math
import os
import random

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
ASSETS = os.path.join(ROOT, "assets")
FONT_DISPLAY = os.path.join(ASSETS, "fonts", "RussoOne-Regular.ttf")

# Piece colours: I O T S Z J L  (keep in sync with scripts/style.gd)
PIECES = ["33e1ff", "ffd23f", "b45cff", "4be37a", "ff4d6d", "4d7dff", "ff9a3c"]


def hex_rgb(h):
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def mix(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))


def rounded_mask(size, box, radius):
    m = Image.new("L", size, 0)
    ImageDraw.Draw(m).rounded_rectangle(box, radius=radius, fill=255)
    return m


def vgradient(size, top, bottom, stops=None):
    w, h = size
    t = np.linspace(0, 1, h)[:, None]
    if stops is None:
        stops = [(0, top), (1, bottom)]
    out = np.zeros((h, w, 3))
    for (p0, c0), (p1, c1) in zip(stops, stops[1:]):
        seg = (t >= p0) & (t <= p1)
        k = np.clip((t - p0) / max(p1 - p0, 1e-6), 0, 1)
        col = np.array(c0)[None, None, :] * (1 - k[..., None]) + np.array(c1)[None, None, :] * k[..., None]
        out = np.where(seg[..., None], np.broadcast_to(col, (h, 1, 3)), out)
    return Image.fromarray(np.broadcast_to(out, (h, w, 3)).astype(np.uint8), "RGB")


# ------------------------------------------------------------------ blocks

def make_block(hex_color, size=96, ss=4):
    S = size * ss
    base = hex_rgb(hex_color)
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    r = int(S * 0.16)
    # Outer rim (darker)
    rim = Image.new("RGBA", (S, S), mix(base, (10, 10, 30), 0.55) + (255,))
    img.paste(rim, (0, 0), rounded_mask((S, S), (0, 0, S - 1, S - 1), r))
    # Body gradient
    inset = int(S * 0.06)
    body = vgradient((S, S), None, None, [
        (0.0, mix(base, (255, 255, 255), 0.45)),
        (0.45, base),
        (1.0, mix(base, (0, 0, 20), 0.25)),
    ]).convert("RGBA")
    img.paste(body, (0, 0), rounded_mask((S, S), (inset, inset, S - 1 - inset, S - 1 - inset), r - inset))
    # Inner bevel face
    face_in = int(S * 0.2)
    face = vgradient((S, S), None, None, [
        (0.0, mix(base, (255, 255, 255), 0.25)),
        (1.0, mix(base, (0, 0, 30), 0.12)),
    ]).convert("RGBA")
    img.paste(face, (0, 0), rounded_mask((S, S), (face_in, face_in, S - 1 - face_in, S - 1 - face_in), int(r * 0.6)))
    # Gloss highlight
    gloss = Image.new("L", (S, S), 0)
    gd = ImageDraw.Draw(gloss)
    gd.rounded_rectangle((inset * 2, inset * 2, S - inset * 2, int(S * 0.42)), radius=int(r * 0.8), fill=70)
    gloss = gloss.filter(ImageFilter.GaussianBlur(S * 0.02))
    white = Image.new("RGBA", (S, S), (255, 255, 255, 255))
    img = Image.composite(Image.alpha_composite(img, Image.merge("RGBA", (*white.split()[:3], gloss))), img, img.split()[3].point(lambda v: 255 if v > 0 else 0))
    return img.resize((size, size), Image.LANCZOS)


# ------------------------------------------------------------------ background

def make_background(w=1080, h=1920):
    img = vgradient((w, h), None, None, [
        (0.0, (14, 18, 52)), (0.5, (22, 12, 50)), (1.0, (8, 8, 26)),
    ]).convert("RGBA")
    glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    for (cx, cy, rad, col, a) in [
        (120, 260, 520, (40, 200, 255), 70),
        (980, 1400, 620, (255, 60, 190), 55),
        (560, 900, 700, (120, 70, 255), 40),
        (900, 120, 360, (255, 160, 60), 30),
    ]:
        gd.ellipse((cx - rad, cy - rad, cx + rad, cy + rad), fill=col + (a,))
    glow = glow.filter(ImageFilter.GaussianBlur(220))
    img = Image.alpha_composite(img, glow)
    # Faint diagonal lines
    lines = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    ld = ImageDraw.Draw(lines)
    for x in range(-h, w, 54):
        ld.line((x, 0, x + h, h), fill=(255, 255, 255, 6), width=2)
    img = Image.alpha_composite(img, lines)
    # Stars
    rnd = random.Random(7)
    st = ImageDraw.Draw(img)
    for _ in range(170):
        x, y = rnd.randrange(w), rnd.randrange(h)
        r = rnd.choice([1, 1, 1, 2, 2, 3])
        st.ellipse((x - r, y - r, x + r, y + r), fill=(255, 255, 255, rnd.randrange(30, 140)))
    # Dither noise against banding
    arr = np.asarray(img.convert("RGB")).astype(np.int16)
    arr += np.random.default_rng(3).integers(-3, 4, arr.shape, dtype=np.int16)
    return Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGB")


# ------------------------------------------------------------------ logo

def text_mask(text, font, pad):
    bbox = font.getbbox(text)
    w, h = bbox[2] - bbox[0] + pad * 2, bbox[3] - bbox[1] + pad * 2
    m = Image.new("L", (w, h), 0)
    ImageDraw.Draw(m).text((pad - bbox[0], pad - bbox[1]), text, font=font, fill=255)
    return m


def logo_word(text, size, stops, glow_col):
    font = ImageFont.truetype(FONT_DISPLAY, size)
    pad = int(size * 0.35)
    m = text_mask(text, font, pad)
    w, h = m.size
    stroke = m.filter(ImageFilter.MaxFilter(17))
    depth = 14
    out = Image.new("RGBA", (w, h + depth), (0, 0, 0, 0))
    # Glow
    g = Image.new("RGBA", out.size, glow_col + (0,))
    g.putalpha(stroke.filter(ImageFilter.GaussianBlur(26)).point(lambda v: int(v * 0.85)).resize(out.size))
    out = Image.alpha_composite(out, g)
    # Extrusion
    dark = Image.new("RGBA", out.size, (12, 6, 34, 255))
    for dy in range(depth, 0, -2):
        layer = Image.new("L", out.size, 0)
        layer.paste(stroke, (0, dy))
        out.paste(dark, (0, 0), layer)
    # Outline
    outline = Image.new("RGBA", out.size, (16, 10, 44, 255))
    ol = Image.new("L", out.size, 0)
    ol.paste(stroke, (0, 0))
    out.paste(outline, (0, 0), ol)
    # Gradient fill
    fill = vgradient((w, h), None, None, stops).convert("RGBA")
    fm = Image.new("L", out.size, 0)
    fm.paste(m, (0, 0))
    fill_full = Image.new("RGBA", out.size, (0, 0, 0, 0))
    fill_full.paste(fill, (0, 0))
    out.paste(fill_full, (0, 0), fm)
    # Shine on the upper half of the letters
    shine = Image.new("L", out.size, 0)
    bbox = m.getbbox()
    mid = bbox[1] + (bbox[3] - bbox[1]) * 0.42
    ImageDraw.Draw(shine).rectangle((0, 0, w, mid), fill=60)
    shine = Image.composite(shine, Image.new("L", out.size, 0), fm)
    out = Image.alpha_composite(out, Image.merge("RGBA", (*Image.new("RGB", out.size, (255, 255, 255)).split(), shine)))
    return out


def make_logo():
    top = logo_word("QUAD", 230, [(0, (255, 255, 255)), (0.5, (150, 240, 255)), (1, (40, 170, 255))], (40, 200, 255))
    bot = logo_word("FIGHT", 230, [(0, (255, 235, 120)), (0.5, (255, 120, 120)), (1, (255, 50, 170))], (255, 60, 170))
    w = max(top.width, bot.width)
    overlap = int(top.height * 0.42)
    canvas = Image.new("RGBA", (w, top.height + bot.height - overlap), (0, 0, 0, 0))
    canvas.alpha_composite(top, ((w - top.width) // 2, 0))
    canvas.alpha_composite(bot, ((w - bot.width) // 2, top.height - overlap))
    return canvas.crop(canvas.getbbox())


# ------------------------------------------------------------------ icons

class Icon:
    def __init__(self, size=128, ss=4):
        self.size, self.ss = size, ss
        self.S = size * ss
        self.img = Image.new("L", (self.S, self.S), 0)
        self.d = ImageDraw.Draw(self.img)
        self.w = int(self.S * 0.1)

    def p(self, x, y):
        return (x * self.S, y * self.S)

    def stroke(self, pts, w=None):
        w = w or self.w
        pts = [self.p(*q) for q in pts]
        self.d.line(pts, fill=255, width=w, joint="curve")
        for (x, y) in pts:
            self.d.ellipse((x - w / 2, y - w / 2, x + w / 2, y + w / 2), fill=255)

    def poly(self, pts, fill=255):
        self.d.polygon([self.p(*q) for q in pts], fill=fill)

    def arc(self, cx, cy, r, a0, a1, w=None):
        w = w or self.w
        S = self.S
        box = ((cx - r) * S, (cy - r) * S, (cx + r) * S, (cy + r) * S)
        self.d.arc(box, a0, a1, fill=255, width=w)
        for a in (a0, a1):
            x = (cx + (r - w / S / 2) * math.cos(math.radians(a))) * S
            y = (cy + (r - w / S / 2) * math.sin(math.radians(a))) * S
            self.d.ellipse((x - w / 2, y - w / 2, x + w / 2, y + w / 2), fill=255)

    def rrect(self, x0, y0, x1, y1, r, fill=True, w=None):
        box = (*self.p(x0, y0), *self.p(x1, y1))
        if fill:
            self.d.rounded_rectangle(box, radius=r * self.S, fill=255)
        else:
            self.d.rounded_rectangle(box, radius=r * self.S, outline=255, width=w or self.w)

    def erase_line(self, a, b, w):
        self.d.line((self.p(*a), self.p(*b)), fill=0, width=w)

    def save(self, name):
        a = self.img.resize((self.size, self.size), Image.LANCZOS)
        out = Image.new("RGBA", a.size, (255, 255, 255, 0))
        out.putalpha(a)
        out.save(os.path.join(ASSETS, "icons", name + ".png"))


def arrow_head(ic, tip, direction, size=0.16):
    ang = math.atan2(direction[1], direction[0])
    left = (tip[0] - size * math.cos(ang - 0.6), tip[1] - size * math.sin(ang - 0.6))
    right = (tip[0] - size * math.cos(ang + 0.6), tip[1] - size * math.sin(ang + 0.6))
    ic.poly([tip, left, right])
    ic.stroke([tip, left, right, tip], w=int(ic.S * 0.04))


def make_icons():
    ic = Icon(); ic.stroke([(0.62, 0.22), (0.36, 0.5), (0.62, 0.78)], w=int(ic.S * 0.12)); ic.save("left")
    ic = Icon(); ic.stroke([(0.38, 0.22), (0.64, 0.5), (0.38, 0.78)], w=int(ic.S * 0.12)); ic.save("right")
    ic = Icon(); ic.stroke([(0.22, 0.38), (0.5, 0.64), (0.78, 0.38)], w=int(ic.S * 0.12)); ic.save("down")
    ic = Icon(); ic.stroke([(0.22, 0.62), (0.5, 0.36), (0.78, 0.62)], w=int(ic.S * 0.12)); ic.save("up")
    ic = Icon()
    ic.stroke([(0.26, 0.18), (0.5, 0.38), (0.74, 0.18)])
    ic.stroke([(0.26, 0.42), (0.5, 0.62), (0.74, 0.42)])
    ic.stroke([(0.22, 0.82), (0.78, 0.82)])
    ic.save("drop")
    def rot_icon(name, cw):
        ic = Icon()
        cx, cy, r = 0.5, 0.54, 0.3
        a0, a1 = 292, 608  # arc with a gap at the top
        ic.arc(cx, cy, r, a0, a1)
        ang = math.radians(a1 if cw else a0)
        pt = (cx + r * math.cos(ang) - 0.05 * math.cos(ang), cy + r * math.sin(ang) - 0.05 * math.sin(ang))
        tan = (-math.sin(ang), math.cos(ang)) if cw else (math.sin(ang), -math.cos(ang))
        arrow_head(ic, (pt[0] + tan[0] * 0.1, pt[1] + tan[1] * 0.1), tan, 0.2)
        ic.save(name)
    rot_icon("rotate", True)
    rot_icon("rotate_ccw", False)
    rot_icon("retry", False)
    ic = Icon()
    ic.stroke([(0.2, 0.36), (0.72, 0.36)]); arrow_head(ic, (0.84, 0.36), (1, 0), 0.15)
    ic.stroke([(0.8, 0.66), (0.28, 0.66)]); arrow_head(ic, (0.16, 0.66), (-1, 0), 0.15)
    ic.save("hold")
    ic = Icon(); ic.rrect(0.26, 0.22, 0.42, 0.78, 0.04); ic.rrect(0.58, 0.22, 0.74, 0.78, 0.04); ic.save("pause")
    ic = Icon(); ic.poly([(0.32, 0.2), (0.32, 0.8), (0.8, 0.5)]); ic.stroke([(0.32, 0.2), (0.32, 0.8), (0.8, 0.5), (0.32, 0.2)], w=int(ic.S * 0.06)); ic.save("play")

    def speaker(ic):
        ic.poly([(0.14, 0.4), (0.3, 0.4), (0.5, 0.2), (0.5, 0.8), (0.3, 0.6), (0.14, 0.6)])
        ic.stroke([(0.14, 0.4), (0.14, 0.6)], w=int(ic.S * 0.05))
    ic = Icon(); speaker(ic); ic.arc(0.5, 0.5, 0.17, -50, 50, w=int(ic.S * 0.07)); ic.arc(0.5, 0.5, 0.32, -50, 50, w=int(ic.S * 0.07)); ic.save("sound_on")
    ic = Icon(); speaker(ic); ic.stroke([(0.62, 0.38), (0.86, 0.62)], w=int(ic.S * 0.07)); ic.stroke([(0.86, 0.38), (0.62, 0.62)], w=int(ic.S * 0.07)); ic.save("sound_off")

    def note(ic):
        ic.d.ellipse((*ic.p(0.18, 0.62), *ic.p(0.4, 0.82)), fill=255)
        ic.d.ellipse((*ic.p(0.56, 0.54), *ic.p(0.78, 0.74)), fill=255)
        ic.stroke([(0.37, 0.72), (0.37, 0.24)], w=int(ic.S * 0.07))
        ic.stroke([(0.75, 0.64), (0.75, 0.16)], w=int(ic.S * 0.07))
        ic.poly([(0.34, 0.2), (0.78, 0.1), (0.78, 0.24), (0.34, 0.34)])
    ic = Icon(); note(ic); ic.save("music_on")
    ic = Icon(); note(ic); ic.erase_line((0.1, 0.1), (0.9, 0.9), int(ic.S * 0.16)); ic.stroke([(0.14, 0.14), (0.86, 0.86)], w=int(ic.S * 0.07)); ic.save("music_off")

    ic = Icon()
    ic.d.pieslice((*ic.p(0.26, -0.06), *ic.p(0.74, 0.62)), 0, 180, fill=255)
    ic.rrect(0.26, 0.16, 0.74, 0.3, 0.0)
    ic.arc(0.27, 0.3, 0.12, 90, 270, w=int(ic.S * 0.06))
    ic.arc(0.73, 0.3, 0.12, -90, 90, w=int(ic.S * 0.06))
    ic.rrect(0.45, 0.58, 0.55, 0.74, 0.0)
    ic.rrect(0.3, 0.74, 0.7, 0.86, 0.03)
    ic.save("trophy")
    ic = Icon()
    ic.stroke([(0.16, 0.5), (0.5, 0.2), (0.84, 0.5)])
    ic.stroke([(0.26, 0.44), (0.26, 0.82), (0.74, 0.82), (0.74, 0.44)])
    ic.rrect(0.43, 0.6, 0.57, 0.82, 0.02)
    ic.save("home")


def main():
    for i, c in enumerate(PIECES):
        make_block(c).save(os.path.join(ASSETS, "blocks", f"block_{i}.png"))
    make_background().save(os.path.join(ASSETS, "bg.jpg"), quality=90)
    make_logo().save(os.path.join(ASSETS, "logo.png"))
    make_icons()
    print("assets written to", ASSETS)


if __name__ == "__main__":
    main()
