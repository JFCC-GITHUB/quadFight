#!/usr/bin/env python3
"""Draws the six VS-mode characters (busts), small portraits and skill icons into assets/chars/.

Run: python3 tools/gen_characters.py   (needs Pillow + numpy; re-run when a design changes).
Technique: every shape is drawn at 3x on its own layer -> gradient body, dark rim, top bevel, gloss.
"""
import math
import os
import sys

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_assets import ASSETS, Icon, mix  # noqa: E402
from gen_assets import hex_rgb as _hex  # noqa: E402


def hex_rgb(h):
    return _hex(h.lstrip("#"))

OUT = os.path.join(ASSETS, "chars")
SIZE, SS = 512, 3
S = SIZE * SS


def mir(pts):
    return [(1 - x, y) for x, y in pts]


class Canvas:
    def __init__(self):
        self.img = Image.new("RGBA", (S, S), (0, 0, 0, 0))

    def _mask(self, shape):
        m = Image.new("L", (S, S), 0)
        d = ImageDraw.Draw(m)
        if shape[0] == "e":
            x0, y0, x1, y1 = shape[1]
            d.ellipse((x0 * S, y0 * S, x1 * S, y1 * S), fill=255)
        else:
            d.polygon([(x * S, y * S) for x, y in shape[1]], fill=255)
        return m

    def shape(self, shape, top, bottom, rim=None, rim_w=3.0, shine=0.35, alpha=1.0):
        """Gradient-filled shape with dark rim, top bevel line and a soft gloss."""
        top, bottom = hex_rgb(top) if isinstance(top, str) else top, hex_rgb(bottom) if isinstance(bottom, str) else bottom
        m = self._mask(shape)
        bb = m.getbbox()
        if not bb:
            return
        x0, y0, x1, y1 = bb
        h = max(y1 - y0, 1)
        t = np.clip((np.arange(S)[:, None] - y0) / h, 0, 1)
        t = np.broadcast_to(t, (S, S))[..., None]
        col = np.array(top)[None, None, :] * (1 - t) + np.array(bottom)[None, None, :] * t
        body = Image.fromarray(col.astype(np.uint8), "RGB").convert("RGBA")
        rim_c = hex_rgb(rim) if isinstance(rim, str) else (rim or mix(bottom, (0, 0, 0), 0.6))
        r = int(rim_w * SS)
        inner = m.filter(ImageFilter.MinFilter(2 * r + 1))
        layer = Image.new("RGBA", (S, S), rim_c + (255,))
        layer.paste(body, (0, 0), inner)
        # top bevel: inner edge lit from above
        lit = ImageChops.subtract(inner, ImageChops.offset(inner, 0, int(r * 1.2)))
        lit = lit.filter(ImageFilter.GaussianBlur(SS * 0.8))
        hi = Image.new("RGBA", (S, S), mix(top, (255, 255, 255), 0.65) + (255,))
        layer.paste(hi, (0, 0), lit.point(lambda v: int(v * 0.75)))
        # gloss: blurred white band in the upper part
        if shine:
            g = Image.new("L", (S, S), 0)
            ImageDraw.Draw(g).ellipse((x0 + (x1 - x0) * 0.1, y0 + h * 0.04, x1 - (x1 - x0) * 0.1, y0 + h * 0.5), fill=int(255 * shine))
            g = g.filter(ImageFilter.GaussianBlur(h * 0.12))
            g = ImageChops.multiply(g, inner)
            layer.paste(Image.new("RGBA", (S, S), (255, 255, 255, 255)), (0, 0), g)
        a = m if alpha >= 1 else m.point(lambda v: int(v * alpha))
        out = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        out.paste(layer, (0, 0), a)
        self.img = Image.alpha_composite(self.img, out)

    def flat(self, shape, color, alpha=1.0):
        m = self._mask(shape)
        if alpha < 1:
            m = m.point(lambda v: int(v * alpha))
        c = hex_rgb(color) if isinstance(color, str) else color
        self.img = Image.alpha_composite(self.img, Image.composite(Image.new("RGBA", (S, S), c + (255,)), Image.new("RGBA", (S, S), (0, 0, 0, 0)), m))

    def glow(self, shape, color, blur=0.02, strength=1.0, core=None):
        m = self._mask(shape)
        c = hex_rgb(color) if isinstance(color, str) else color
        g = m.filter(ImageFilter.GaussianBlur(blur * S)).point(lambda v: min(255, int(v * 2 * strength)))
        self.img = Image.alpha_composite(self.img, Image.composite(Image.new("RGBA", (S, S), c + (255,)), Image.new("RGBA", (S, S), (0, 0, 0, 0)), g))
        cc = hex_rgb(core) if isinstance(core, str) else (core or mix(c, (255, 255, 255), 0.8))
        self.flat(shape, cc)

    def line(self, pts, color, w, alpha=1.0, glow=0.0):
        m = Image.new("L", (S, S), 0)
        d = ImageDraw.Draw(m)
        P = [(x * S, y * S) for x, y in pts]
        d.line(P, fill=255, width=int(w * SS), joint="curve")
        for x, y in P:
            d.ellipse((x - w * SS / 2, y - w * SS / 2, x + w * SS / 2, y + w * SS / 2), fill=255)
        c = hex_rgb(color) if isinstance(color, str) else color
        if glow:
            g = m.filter(ImageFilter.GaussianBlur(glow * S)).point(lambda v: min(255, v * 2))
            self.img = Image.alpha_composite(self.img, Image.composite(Image.new("RGBA", (S, S), c + (255,)), Image.new("RGBA", (S, S), (0, 0, 0, 0)), g))
        if alpha < 1:
            m = m.point(lambda v: int(v * alpha))
        self.img = Image.alpha_composite(self.img, Image.composite(Image.new("RGBA", (S, S), c + (255,)), Image.new("RGBA", (S, S), (0, 0, 0, 0)), m))

    def aura(self, color, cy=0.46, r=0.5):
        """Soft radial glow + faint rays behind the figure."""
        yy, xx = np.mgrid[0:S, 0:S] / S
        d = np.sqrt((xx - 0.5) ** 2 + (yy - cy) ** 2) / r
        a = np.clip(1 - d, 0, 1) ** 1.6
        ang = np.arctan2(yy - cy, xx - 0.5)
        a = a * (0.75 + 0.25 * np.cos(ang * 10))
        c = hex_rgb(color) if isinstance(color, str) else color
        lay = np.zeros((S, S, 4), np.uint8)
        lay[..., :3] = c
        lay[..., 3] = (a * 150).astype(np.uint8)
        self.img = Image.alpha_composite(Image.fromarray(lay, "RGBA"), self.img)

    def done(self):
        return self.img.resize((SIZE, SIZE), Image.LANCZOS)


def body(c, top, bottom, trim):
    """Shared shoulders + torso block."""
    c.shape(("p", [(0.08, 1.0), (0.12, 0.8), (0.28, 0.69), (0.72, 0.69), (0.88, 0.8), (0.92, 1.0)]), top, bottom)


# ------------------------------------------------------------------ characters

def bastion():
    c = Canvas(); c.aura("#3b8bff")
    # big armoured shoulders + chest
    c.shape(("p", [(0.1, 1.0), (0.16, 0.76), (0.3, 0.66), (0.7, 0.66), (0.84, 0.76), (0.9, 1.0)]), "#5a6c8e", "#232c45")
    for pts in ([(0.03, 0.8), (0.06, 0.62), (0.2, 0.55), (0.3, 0.64), (0.27, 0.86), (0.12, 0.92)],):
        c.shape(("p", pts), "#8fb0e8", "#2a4a96"); c.shape(("p", mir(pts)), "#8fb0e8", "#2a4a96")
    c.shape(("p", [(0.36, 1.0), (0.38, 0.74), (0.5, 0.7), (0.62, 0.74), (0.64, 1.0)]), "#9fc0f5", "#2c56b0")
    c.glow(("p", [(0.5, 0.8), (0.55, 0.86), (0.5, 0.95), (0.45, 0.86)]), "#4ab0ff")
    # helmet
    c.shape(("p", [(0.42, 0.12), (0.5, 0.0), (0.58, 0.12), (0.54, 0.2), (0.46, 0.2)]), "#ffd36a", "#c2641c")  # crest
    c.shape(("p", [(0.28, 0.5), (0.27, 0.3), (0.35, 0.15), (0.5, 0.1), (0.65, 0.15), (0.73, 0.3), (0.72, 0.5), (0.64, 0.64), (0.36, 0.64)]), "#c4d6f7", "#3a62b8")
    c.shape(("p", [(0.28, 0.5), (0.3, 0.38), (0.35, 0.4), (0.38, 0.62), (0.34, 0.62)]), "#6f93d6", "#27468c", shine=0)
    c.shape(("p", mir([(0.28, 0.5), (0.3, 0.38), (0.35, 0.4), (0.38, 0.62), (0.34, 0.62)])), "#6f93d6", "#27468c", shine=0)
    c.flat(("p", [(0.33, 0.33), (0.67, 0.33), (0.65, 0.4), (0.545, 0.4), (0.545, 0.56), (0.455, 0.56), (0.455, 0.4), (0.35, 0.4)]), "#0a1226")
    c.glow(("p", [(0.36, 0.345), (0.47, 0.345), (0.465, 0.385), (0.37, 0.385)]), "#38d0ff", 0.012)
    c.glow(("p", mir([(0.36, 0.345), (0.47, 0.345), (0.465, 0.385), (0.37, 0.385)])), "#38d0ff", 0.012)
    c.line([(0.5, 0.14), (0.5, 0.31)], "#ffe49a", 5)
    return c.done()


def blaze():
    c = Canvas(); c.aura("#ff7a2a")
    # scarf tail behind
    c.shape(("p", [(0.62, 0.7), (0.82, 0.62), (0.97, 0.7), (0.88, 0.76), (0.95, 0.88), (0.72, 0.8)]), "#ff8a4a", "#b81d1d")
    c.shape(("p", [(0.1, 1.0), (0.14, 0.78), (0.3, 0.68), (0.7, 0.68), (0.86, 0.78), (0.9, 1.0)]), "#3d3340", "#14111c")
    c.line([(0.2, 0.9), (0.34, 0.78), (0.5, 0.74), (0.66, 0.78), (0.8, 0.9)], "#ff7a2a", 6, glow=0.01)
    c.shape(("p", [(0.28, 0.72), (0.5, 0.82), (0.72, 0.72), (0.7, 0.8), (0.5, 0.9), (0.3, 0.8)]), "#ff6a3a", "#b81d1d")  # scarf front
    # flame hair
    flames = [[(0.3, 0.3), (0.2, 0.12), (0.34, 0.2), (0.3, 0.0), (0.44, 0.17), (0.5, -0.02), (0.56, 0.17), (0.7, 0.0), (0.66, 0.2), (0.8, 0.12), (0.7, 0.3)]]
    c.shape(("p", flames[0]), "#ffe27a", "#e63a1a", shine=0.1)
    c.shape(("p", [(0.34, 0.28), (0.3, 0.14), (0.4, 0.22), (0.5, 0.06), (0.6, 0.22), (0.7, 0.14), (0.66, 0.28)]), "#fff3b0", "#ff9a30", shine=0, rim="#ff9a30", rim_w=1)
    # hood / head
    c.shape(("e", (0.27, 0.2, 0.73, 0.66)), "#4a3a52", "#17121f")
    # eye band (skin) with white-hot eyes
    c.shape(("p", [(0.28, 0.36), (0.72, 0.36), (0.71, 0.48), (0.29, 0.48)]), "#f3b48a", "#c47a52", shine=0.2)
    c.glow(("p", [(0.33, 0.4), (0.46, 0.42), (0.45, 0.46), (0.33, 0.44)]), "#ff4a1a", 0.012, core="#fff6c0")
    c.glow(("p", mir([(0.33, 0.4), (0.46, 0.42), (0.45, 0.46), (0.33, 0.44)])), "#ff4a1a", 0.012, core="#fff6c0")
    # mask + headband plate
    c.shape(("p", [(0.29, 0.5), (0.71, 0.5), (0.66, 0.64), (0.5, 0.68), (0.34, 0.64)]), "#6b2030", "#2a0a14")
    c.shape(("p", [(0.27, 0.24), (0.73, 0.24), (0.73, 0.33), (0.27, 0.33)]), "#d44a2a", "#7a1414", shine=0.2)
    c.shape(("p", [(0.44, 0.235), (0.56, 0.235), (0.56, 0.335), (0.44, 0.335)]), "#e8ecf4", "#7a8499")
    c.glow(("p", [(0.5, 0.25), (0.53, 0.3), (0.5, 0.32), (0.47, 0.3)]), "#ff5a1a", 0.008)
    return c.done()


def frost():
    c = Canvas(); c.aura("#6fe0ff")
    # shoulders with crystal spikes
    c.shape(("p", [(0.08, 1.0), (0.12, 0.78), (0.28, 0.68), (0.72, 0.68), (0.88, 0.78), (0.92, 1.0)]), "#7ab8e8", "#1e3f78")
    for sp in ([(0.1, 0.8), (0.04, 0.5), (0.2, 0.7)], [(0.2, 0.74), (0.18, 0.5), (0.3, 0.68)], [(0.04, 0.84), (-0.01, 0.68), (0.1, 0.78)]):
        c.shape(("p", sp), "#e8fcff", "#58b8f0"); c.shape(("p", mir(sp)), "#e8fcff", "#58b8f0")
    # hood
    c.shape(("p", [(0.5, -0.02), (0.64, 0.12), (0.74, 0.34), (0.76, 0.62), (0.64, 0.74), (0.36, 0.74), (0.24, 0.62), (0.26, 0.34), (0.36, 0.12)]), "#8fd0ff", "#2556a8")
    c.shape(("p", [(0.5, 0.16), (0.64, 0.28), (0.68, 0.5), (0.6, 0.66), (0.4, 0.66), (0.32, 0.5), (0.36, 0.28)]), "#17284e", "#070b1c", shine=0, rim="#e8fcff", rim_w=2)
    # fur trim
    c.shape(("e", (0.26, 0.64, 0.74, 0.8)), "#ffffff", "#bfe0f5", shine=0.2)
    # eyes + frosty beard glow
    for pts in ([(0.38, 0.42), (0.47, 0.44), (0.46, 0.48), (0.38, 0.46)],):
        c.glow(("p", pts), "#46d8ff", 0.014); c.glow(("p", mir(pts)), "#46d8ff", 0.014)
    # crown crystals
    for cr in ([(0.5, -0.1), (0.55, 0.07), (0.5, 0.12), (0.45, 0.07)], [(0.4, -0.02), (0.44, 0.1), (0.38, 0.13)], [(0.6, -0.02), (0.62, 0.13), (0.56, 0.1)]):
        c.shape(("p", cr), "#f4ffff", "#50c0f8", rim="#2a78c0", rim_w=2)
    c.glow(("p", [(0.5, 0.74), (0.55, 0.82), (0.5, 0.92), (0.45, 0.82)]), "#8ae8ff", 0.012)
    return c.done()


def volt():
    c = Canvas(); c.aura("#ffd21a")
    # jacket
    c.shape(("p", [(0.1, 1.0), (0.14, 0.78), (0.3, 0.68), (0.7, 0.68), (0.86, 0.78), (0.9, 1.0)]), "#8a52d8", "#2e1066")
    c.shape(("p", [(0.3, 0.68), (0.5, 0.82), (0.7, 0.68), (0.74, 0.76), (0.5, 0.94), (0.26, 0.76)]), "#ffe65a", "#d49a00")
    c.flat(("p", [(0.5, 0.78), (0.42, 0.9), (0.49, 0.9), (0.46, 1.0), (0.58, 0.86), (0.51, 0.86), (0.55, 0.78)]), "#2e1066")
    # fists
    c.shape(("e", (0.0, 0.7, 0.24, 0.96)), "#ff6a6a", "#a31428"); c.shape(("e", (0.76, 0.7, 1.0, 0.96)), "#ff6a6a", "#a31428")
    # neck + head
    c.shape(("p", [(0.42, 0.56), (0.58, 0.56), (0.6, 0.72), (0.4, 0.72)]), "#d99a74", "#9a5a3c", shine=0)
    c.shape(("p", [(0.3, 0.3), (0.34, 0.2), (0.5, 0.17), (0.66, 0.2), (0.7, 0.3), (0.68, 0.5), (0.6, 0.62), (0.5, 0.66), (0.4, 0.62), (0.32, 0.5)]), "#ffd0a8", "#c47e58", shine=0.25)
    # spiky lightning hair
    hair = [(0.28, 0.32), (0.2, 0.2), (0.32, 0.22), (0.24, 0.04), (0.4, 0.14), (0.4, -0.04), (0.52, 0.1), (0.62, -0.06), (0.62, 0.14), (0.78, 0.02), (0.7, 0.22), (0.84, 0.2), (0.72, 0.32), (0.66, 0.22), (0.5, 0.2), (0.34, 0.22)]
    c.shape(("p", hair), "#fff08a", "#f0a800", shine=0.3)
    # goggles
    c.shape(("p", [(0.28, 0.33), (0.72, 0.33), (0.7, 0.44), (0.3, 0.44)]), "#4a3a90", "#1a0c4a", shine=0.1)
    c.glow(("e", (0.33, 0.35, 0.47, 0.43)), "#38e8ff", 0.012); c.glow(("e", (0.53, 0.35, 0.67, 0.43)), "#38e8ff", 0.012)
    # grin
    c.flat(("p", [(0.4, 0.52), (0.6, 0.52), (0.56, 0.58), (0.44, 0.58)]), "#3a0a22")
    c.flat(("p", [(0.42, 0.52), (0.58, 0.52), (0.57, 0.545), (0.43, 0.545)]), "#ffffff")
    # arcs
    c.line([(0.1, 0.44), (0.16, 0.38), (0.12, 0.3), (0.2, 0.22)], "#fff08a", 4, glow=0.01)
    c.line([(0.9, 0.5), (0.84, 0.42), (0.88, 0.34), (0.8, 0.28)], "#fff08a", 4, glow=0.01)
    return c.done()


def shade():
    c = Canvas(); c.aura("#b04aff")
    # crossed blades behind
    for sgn in (1, -1):
        x = lambda v: 0.5 + sgn * (v - 0.5)
        c.shape(("p", [(x(0.08), 0.18), (x(0.13), 0.14), (x(0.6), 0.78), (x(0.55), 0.84)]), "#f4f0ff", "#8a82b0", rim="#2a2050", rim_w=2)
        c.shape(("p", [(x(0.5), 0.74), (x(0.62), 0.7), (x(0.66), 0.8), (x(0.56), 0.88)]), "#6a3aa0", "#2a1050")
    c.shape(("p", [(0.1, 1.0), (0.14, 0.78), (0.3, 0.68), (0.7, 0.68), (0.86, 0.78), (0.9, 1.0)]), "#3a2a5a", "#0e0a1c")
    c.line([(0.3, 0.74), (0.5, 0.92), (0.7, 0.74)], "#c070ff", 5, glow=0.01)
    # hood
    c.shape(("p", [(0.5, 0.0), (0.62, 0.1), (0.72, 0.3), (0.74, 0.6), (0.64, 0.72), (0.36, 0.72), (0.26, 0.6), (0.28, 0.3), (0.38, 0.1)]), "#54407e", "#150d2a")
    c.shape(("p", [(0.5, 0.14), (0.64, 0.28), (0.66, 0.5), (0.58, 0.62), (0.42, 0.62), (0.34, 0.5), (0.36, 0.28)]), "#0b0716", "#030208", shine=0, rim="#7a50b8", rim_w=2)
    # mask bottom
    c.shape(("p", [(0.34, 0.5), (0.66, 0.5), (0.62, 0.62), (0.5, 0.66), (0.38, 0.62)]), "#2a1e48", "#0a0618", shine=0.1)
    # eyes
    e = [(0.36, 0.38), (0.48, 0.43), (0.47, 0.46), (0.36, 0.43)]
    c.glow(("p", e), "#ff3ad0", 0.016, core="#ffe0f8"); c.glow(("p", mir(e)), "#ff3ad0", 0.016, core="#ffe0f8")
    c.glow(("p", [(0.5, 0.06), (0.53, 0.12), (0.5, 0.16), (0.47, 0.12)]), "#c070ff", 0.008)
    return c.done()


def titan():
    c = Canvas(); c.aura("#9ed23a")
    # boulder shoulders
    c.shape(("p", [(0.0, 0.9), (0.02, 0.68), (0.14, 0.58), (0.3, 0.62), (0.36, 0.78), (0.3, 1.0), (0.04, 1.0)]), "#a89a78", "#4a4030")
    c.shape(("p", mir([(0.0, 0.9), (0.02, 0.68), (0.14, 0.58), (0.3, 0.62), (0.36, 0.78), (0.3, 1.0), (0.04, 1.0)])), "#a89a78", "#4a4030")
    c.shape(("p", [(0.26, 1.0), (0.26, 0.72), (0.74, 0.72), (0.74, 1.0)]), "#8a7c5c", "#3a3224")
    # core gem
    c.glow(("p", [(0.5, 0.78), (0.58, 0.86), (0.5, 0.97), (0.42, 0.86)]), "#a8ff3a", 0.02, core="#f4ffc0")
    # head: chunky blocks
    c.shape(("p", [(0.26, 0.44), (0.28, 0.2), (0.4, 0.1), (0.6, 0.1), (0.72, 0.2), (0.74, 0.44), (0.68, 0.66), (0.32, 0.66)]), "#c4b48c", "#5a4a34")
    c.shape(("p", [(0.34, 0.1), (0.42, 0.02), (0.58, 0.02), (0.66, 0.1), (0.6, 0.16), (0.4, 0.16)]), "#8ab050", "#3a5a20")  # moss crown
    c.shape(("p", [(0.3, 0.52), (0.7, 0.52), (0.66, 0.66), (0.34, 0.66)]), "#9a8a68", "#46382a", shine=0.1)  # jaw
    c.flat(("p", [(0.38, 0.54), (0.62, 0.54), (0.6, 0.58), (0.4, 0.58)]), "#1a1208")
    # brow + eyes
    c.shape(("p", [(0.28, 0.3), (0.72, 0.3), (0.7, 0.38), (0.3, 0.38)]), "#6a5c42", "#2a2218", shine=0)
    e = [(0.34, 0.34), (0.46, 0.34), (0.44, 0.4), (0.35, 0.4)]
    c.glow(("p", e), "#a8ff3a", 0.014, core="#f4ffc0"); c.glow(("p", mir(e)), "#a8ff3a", 0.014, core="#f4ffc0")
    # cracks
    c.line([(0.5, 0.1), (0.46, 0.2), (0.52, 0.28)], "#2a2218", 4); c.line([(0.68, 0.46), (0.62, 0.5), (0.64, 0.56)], "#2a2218", 3)
    c.line([(0.2, 0.7), (0.14, 0.78), (0.18, 0.86)], "#2a2218", 3)
    return c.done()


CHARS = {"bastion": bastion, "blaze": blaze, "frost": frost, "volt": volt, "shade": shade, "titan": titan}


# ------------------------------------------------------------------ skill icons (white line art, tinted in Godot)

def skill_icons():
    ic = Icon()  # wall: three brick rows
    for i, y in enumerate((0.22, 0.42, 0.62)):
        ic.rrect(0.14, y, 0.86, y + 0.16, 0.03, fill=False, w=int(ic.S * 0.05))
        ic.erase_line((0.5 if i % 2 == 0 else 0.32, y), (0.5 if i % 2 == 0 else 0.32, y + 0.16), int(ic.S * 0.06))
    ic.save("sk_wall")
    ic = Icon()  # fire rain: drops
    for x, y in ((0.28, 0.22), (0.62, 0.3), (0.45, 0.58), (0.78, 0.62), (0.2, 0.7)):
        ic.poly([(x, y - 0.1), (x + 0.07, y + 0.02), (x, y + 0.08), (x - 0.07, y + 0.02)])
    ic.save("sk_rain")
    ic = Icon()  # crystal
    ic.stroke([(0.5, 0.1), (0.72, 0.4), (0.5, 0.9), (0.28, 0.4), (0.5, 0.1)], w=int(ic.S * 0.07)); ic.stroke([(0.28, 0.4), (0.72, 0.4)], w=int(ic.S * 0.05)); ic.stroke([(0.5, 0.1), (0.5, 0.9)], w=int(ic.S * 0.04))
    ic.save("sk_ice")
    ic = Icon()  # bolt
    ic.poly([(0.58, 0.06), (0.24, 0.54), (0.46, 0.54), (0.38, 0.94), (0.76, 0.4), (0.54, 0.4)])
    ic.save("sk_bolt")
    ic = Icon()  # checker
    for r in range(3):
        for q in range(3):
            if (r + q) % 2 == 0:
                ic.rrect(0.14 + q * 0.24, 0.14 + r * 0.24, 0.14 + q * 0.24 + 0.24, 0.14 + r * 0.24 + 0.24, 0.02)
    ic.save("sk_checker")
    ic = Icon()  # boulder
    ic.poly([(0.2, 0.7), (0.16, 0.45), (0.34, 0.2), (0.62, 0.16), (0.84, 0.36), (0.82, 0.68), (0.6, 0.84), (0.36, 0.84)])
    ic.erase_line((0.4, 0.3), (0.5, 0.5), int(ic.S * 0.04)); ic.erase_line((0.5, 0.5), (0.7, 0.55), int(ic.S * 0.04))
    ic.save("sk_boulder")


def main():
    os.makedirs(OUT, exist_ok=True)
    sheet = Image.new("RGB", (3 * 400, 2 * 400), (18, 14, 34))
    for i, (cid, fn) in enumerate(CHARS.items()):
        im = fn()
        im.save(os.path.join(OUT, cid + ".png"))
        im.crop((64, 0, 448, 384)).resize((128, 128), Image.LANCZOS).save(os.path.join(OUT, cid + "_s.png"))
        sheet.paste(im.resize((400, 400), Image.LANCZOS), ((i % 3) * 400, (i // 3) * 400), im.resize((400, 400), Image.LANCZOS))
    sheet.save(os.path.join(os.environ.get("SHEET_DIR", "/tmp"), "chars_sheet.png"))
    skill_icons()
    print("characters written to", OUT)


if __name__ == "__main__":
    main()
