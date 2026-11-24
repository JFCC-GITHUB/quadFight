#!/usr/bin/env python3
"""Draws the six VS-mode characters as 16-bit style pixel art (busts, portraits, skill icons) into assets/chars/.

Run: python3 tools/gen_characters.py   (needs Pillow + numpy; re-run when a design changes).
Technique: aliased shapes on a 96px grid, 4-band dithered shading, 1px outline, top highlight, nearest-neighbour 5x.
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
W, UP = 96, 5  # drawn on a 96px grid, enlarged 5x with nearest neighbour -> 480px pixel art
BAYER = np.array([[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]) / 16.0 - 0.5
YY, XX = np.mgrid[0:W, 0:W]
BAYER = np.tile(BAYER, (W // 4, W // 4))
CHECK = ((XX + YY) % 2 == 0)
BANDS = 4


def mir(pts):
    return [(1 - x, y) for x, y in pts]


def col(c):
    return np.array(hex_rgb(c) if isinstance(c, str) else c, np.uint8)


class Canvas:
    """Pixel-art canvas: aliased shapes, banded + dithered shading, 1px dark outline, 1px top highlight."""

    def __init__(self):
        self.px = np.zeros((W, W, 4), np.uint8)

    def _mask(self, shape):
        m = Image.new("L", (W, W), 0)
        d = ImageDraw.Draw(m)
        if shape[0] == "e":
            x0, y0, x1, y1 = shape[1]
            d.ellipse((x0 * W, y0 * W, x1 * W - 1, y1 * W - 1), fill=255)
        else:
            d.polygon([(x * W, y * W) for x, y in shape[1]], fill=255)
        return m

    @staticmethod
    def _arr(m):
        return np.array(m) > 127

    def _put(self, mask, rgb, alpha=255):
        self.px[mask] = (*rgb, alpha)

    def shape(self, shape, top, bottom, rim=None, rim_w=0, shine=0.35, alpha=1.0):
        t0, t1 = col(top), col(bottom)
        m = self._mask(shape)
        mk = self._arr(m)
        if not mk.any():
            return
        ys, xs = np.nonzero(mk)
        y0, y1, x0, x1 = ys.min(), ys.max(), xs.min(), xs.max()
        t = (YY - y0) / max(y1 - y0, 1) * 0.85 + (XX - x0) / max(x1 - x0, 1) * 0.25
        band = np.clip(np.floor(t * BANDS + BAYER * 0.9), 0, BANDS - 1).astype(int)
        ramp = np.array([t0 + (t1.astype(int) - t0.astype(int)) * i / (BANDS - 1) for i in range(BANDS)]).astype(np.uint8)
        outline = self._arr(m.filter(ImageFilter.MaxFilter(3))) & ~mk
        rim_c = col(rim) if rim is not None else (t1 * 0.35).astype(np.uint8)
        self._put(outline, rim_c)
        self.px[mk] = np.concatenate([ramp[band[mk]], np.full((mk.sum(), 1), 255, np.uint8)], axis=1)
        if shine:
            up = np.zeros_like(mk)
            up[1:] = mk[1:] & ~mk[:-1]
            hi = np.clip(t0.astype(int) + 90, 0, 255).astype(np.uint8)
            self._put(up & (XX < x0 + (x1 - x0) * 0.75), hi)

    def flat(self, shape, color, alpha=1.0):
        self._put(self._arr(self._mask(shape)), col(color))

    def glow(self, shape, color, blur=0.02, strength=1.0, core=None):
        m = self._mask(shape)
        mk = self._arr(m)
        k = max(1, round(blur * W * 1.2))
        halo = self._arr(m.filter(ImageFilter.MaxFilter(2 * k + 1))) & ~mk & CHECK
        c = col(color)
        self._put(halo, c)
        self._put(mk, c)
        inner = self._arr(m.filter(ImageFilter.MinFilter(3)))
        cc = col(core) if core else np.clip(c.astype(int) + 150, 0, 255).astype(np.uint8)
        self._put(inner if inner.any() else mk, cc)

    def line(self, pts, color, w, alpha=1.0, glow=0.0):
        m = Image.new("L", (W, W), 0)
        wp = max(1, round(w * W / 512 * 1.3))
        ImageDraw.Draw(m).line([(x * W, y * W) for x, y in pts], fill=255, width=wp, joint="curve")
        mk = self._arr(m)
        c = col(color)
        if glow:
            self._put(self._arr(m.filter(ImageFilter.MaxFilter(5))) & ~mk & CHECK, c)
        self._put(mk, c)

    def aura(self, color, cy=0.46, r=0.5):
        d = np.sqrt((XX / W - 0.5) ** 2 + (YY / W - cy) ** 2) / r
        ang = np.arctan2(YY / W - cy, XX / W - 0.5)
        v = np.clip(1 - d, 0, 1) * (0.8 + 0.2 * np.cos(ang * 10))
        c = col(color)
        lay = np.zeros((W, W, 4), np.uint8)
        lay[..., :3] = c
        lay[..., 3] = np.where(v + BAYER * 0.25 > 0.5, 150, np.where(v + BAYER * 0.25 > 0.22, 80, 0))
        lay[..., 3] = np.where(lay[..., 3] > 0, np.where(CHECK | (v > 0.5), lay[..., 3], 0), 0)
        self.px = lay

    def done(self):
        return Image.fromarray(self.px, "RGBA").resize((W * UP, W * UP), Image.NEAREST)


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
    for g in ((0.0, 0.66, 0.26, 0.9), (0.74, 0.66, 1.0, 0.9)):
        c.shape(("e", g), "#ff6a6a", "#a31428")
        c.shape(("p", [(g[0] + 0.02, 0.88), (g[2] - 0.02, 0.88), (g[2] - 0.02, 1.0), (g[0] + 0.02, 1.0)]), "#ffe65a", "#d49a00", shine=0)
        for fx in (0.38, 0.5, 0.62):
            c.line([(g[0] + (g[2] - g[0]) * fx, 0.7), (g[0] + (g[2] - g[0]) * fx, 0.78)], "#7a0c1c", 5)
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
    ic = Icon()  # wall: offset brick rows
    for y, gaps in ((0.2, (0.5,)), (0.42, (0.33, 0.67)), (0.64, (0.5,))):
        ic.rrect(0.12, y, 0.88, y + 0.17, 0.02)
        for g in gaps:
            ic.erase_line((g, y - 0.01), (g, y + 0.18), int(ic.S * 0.05))
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
    ic = Icon()  # boulder: the 3x3 block that falls
    ic.rrect(0.14, 0.14, 0.86, 0.86, 0.05)
    for v in (0.38, 0.62):
        ic.erase_line((v, 0.12), (v, 0.88), int(ic.S * 0.035)); ic.erase_line((0.12, v), (0.88, v), int(ic.S * 0.035))
    ic.save("sk_boulder")


def main():
    os.makedirs(OUT, exist_ok=True)
    cell = W * UP
    sheet = Image.new("RGB", (3 * cell, 2 * cell), (18, 14, 34))
    for i, (cid, fn) in enumerate(CHARS.items()):
        im = fn()
        im.save(os.path.join(OUT, cid + ".png"))
        im.crop((16 * UP, 0, 80 * UP, 64 * UP)).resize((128, 128), Image.NEAREST).save(os.path.join(OUT, cid + "_s.png"))
        sheet.paste(im, ((i % 3) * cell, (i // 3) * cell), im)
    sheet.save(os.path.join(os.environ.get("SHEET_DIR", "/tmp"), "chars_sheet.png"))
    skill_icons()
    print("characters written to", OUT)


if __name__ == "__main__":
    main()
