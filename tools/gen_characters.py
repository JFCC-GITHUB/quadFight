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
BANDS = 5


def mir(pts):
    return [(1 - x, y) for x, y in pts]


def col(c):
    return np.array(hex_rgb(c) if isinstance(c, str) else c, np.uint8)


class Canvas:
    """Pixel-art canvas: aliased shapes, banded + dithered shading, 1px dark outline, 1px top highlight."""

    def __init__(self):
        self.px = np.zeros((W, W, 4), np.uint8)
        self.rim = None  # coloured back light, set by aura()

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
        t1 = (t1 * 0.72).astype(np.uint8)  # deeper shadows = more contrast
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
            if self.rim is not None:  # 1-2px back light on the right-hand edge
                edge = mk.copy()
                edge[:, :-1] &= ~mk[:, 1:]
                edge2 = mk.copy()
                edge2[:, :-2] &= ~mk[:, 2:]
                self._put(edge2 & ~edge & (YY > y0 + 1), np.clip((t0.astype(int) + self.rim) // 2, 0, 255).astype(np.uint8))
                self._put(edge & (YY > y0), np.clip(self.rim.astype(int) + 60, 0, 255).astype(np.uint8))

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
        self.rim = c
        lay = np.zeros((W, W, 4), np.uint8)
        lay[..., :3] = c
        lay[..., 3] = np.where(v + BAYER * 0.25 > 0.5, 150, np.where(v + BAYER * 0.25 > 0.22, 80, 0))
        lay[..., 3] = np.where(lay[..., 3] > 0, np.where(CHECK | (v > 0.5), lay[..., 3], 0), 0)
        self.px = lay

    def done(self):
        return Image.fromarray(self.px, "RGBA").resize((W * UP, W * UP), Image.NEAREST)


# ------------------------------------------------------------------ characters

def eye(x0, x1, y, h=0.035):
    """Sharp, angry blade-shaped eye for the left side (mirror for the right): slopes down toward the nose."""
    return [(x0, y), (x1, y + h * 1.5), (x1, y + h * 2.0), (x0 + 0.01, y + h * 2.1)]  # flat bottom, thick outer edge


def eyes(c, x0, x1, y, color, core=None, h=0.035):
    c.glow(("p", eye(x0, x1, y, h)), color, 0.012, core=core)
    c.glow(("p", mir(eye(x0, x1, y, h))), color, 0.012, core=core)


def pair(c, pts, top, bottom, **kw):
    c.shape(("p", pts), top, bottom, **kw)
    c.shape(("p", mir(pts)), top, bottom, **kw)


TORSO = [(0.1, 1.0), (0.15, 0.78), (0.3, 0.68), (0.7, 0.68), (0.85, 0.78), (0.9, 1.0)]


def bastion():
    c = Canvas(); c.aura("#3b8bff")
    pair(c, [(0.32, 0.3), (0.06, 0.1), (0.16, 0.22), (0.04, 0.24), (0.18, 0.32), (0.08, 0.38), (0.32, 0.42)], "#e8f0ff", "#4a68a8")  # swept wings
    c.shape(("p", TORSO), "#5a6c8e", "#1c2238")
    pair(c, [(0.03, 0.92), (0.03, 0.68), (0.0, 0.5), (0.16, 0.58), (0.31, 0.64), (0.29, 0.88), (0.14, 0.95)], "#9cbcf0", "#24448e")
    c.shape(("p", [(0.34, 0.7), (0.66, 0.7), (0.62, 0.88), (0.5, 1.0), (0.38, 0.88)]), "#a8c8ff", "#24448e")
    c.glow(("p", [(0.5, 0.76), (0.55, 0.83), (0.5, 0.92), (0.45, 0.83)]), "#4ab0ff")
    c.shape(("p", [(0.5, 0.07), (0.66, 0.13), (0.73, 0.3), (0.71, 0.5), (0.61, 0.65), (0.5, 0.7), (0.39, 0.65), (0.29, 0.5), (0.27, 0.3), (0.34, 0.13)]), "#d4e2ff", "#2e52a8")
    c.shape(("p", [(0.47, 0.16), (0.5, -0.06), (0.53, 0.16), (0.5, 0.32)]), "#ffe27a", "#c2641c")  # crest blade
    c.flat(("p", [(0.29, 0.31), (0.5, 0.41), (0.71, 0.31), (0.7, 0.42), (0.5, 0.52), (0.3, 0.42)]), "#060c1e")  # V visor
    eyes(c, 0.33, 0.46, 0.345, "#38d0ff")
    for x in (0.45, 0.5, 0.55):
        c.line([(x, 0.55), (x, 0.63)], "#0d1a3a", 5)
    return c.done()


def blaze():
    c = Canvas(); c.aura("#ff5a1a")
    c.shape(("p", [(0.6, 0.68), (1.0, 0.54), (0.86, 0.64), (1.0, 0.72), (0.84, 0.75), (0.95, 0.86), (0.68, 0.79)]), "#ff8a4a", "#a8141a")
    c.line([(0.3, 0.27), (0.12, 0.22), (0.02, 0.3)], "#d4302a", 8); c.line([(0.3, 0.3), (0.1, 0.32), (0.04, 0.42)], "#a8141a", 7)
    c.shape(("p", TORSO), "#3d3340", "#100c16")
    c.line([(0.18, 0.92), (0.34, 0.76), (0.5, 0.9), (0.66, 0.76), (0.82, 0.92)], "#ff7a2a", 6, glow=0.01)
    c.shape(("p", [(0.3, 0.3), (0.14, 0.12), (0.3, 0.2), (0.25, -0.04), (0.42, 0.13), (0.5, -0.1), (0.58, 0.1), (0.78, -0.06), (0.68, 0.17), (0.92, 0.08), (0.72, 0.32)]), "#ffe27a", "#e02a10", shine=0.1)
    c.shape(("p", [(0.36, 0.28), (0.32, 0.14), (0.42, 0.22), (0.5, 0.04), (0.58, 0.2), (0.72, 0.06), (0.64, 0.28)]), "#fff6c0", "#ff9a30", shine=0)
    c.shape(("p", [(0.28, 0.3), (0.36, 0.21), (0.64, 0.21), (0.72, 0.3), (0.72, 0.5), (0.62, 0.66), (0.5, 0.7), (0.38, 0.66), (0.28, 0.5)]), "#4a3a52", "#120e18")
    c.shape(("p", [(0.28, 0.36), (0.72, 0.36), (0.72, 0.47), (0.28, 0.47)]), "#f3b48a", "#b8683e", shine=0)
    c.flat(("p", [(0.28, 0.36), (0.72, 0.36), (0.72, 0.385), (0.5, 0.425), (0.28, 0.385)]), "#2a0e10")  # brow shadow
    eyes(c, 0.33, 0.46, 0.39, "#ff3a10", core="#fff6c0", h=0.028)
    c.shape(("p", [(0.28, 0.47), (0.72, 0.47), (0.7, 0.56), (0.5, 0.74), (0.3, 0.56)]), "#7a2030", "#1e060c")
    c.shape(("p", [(0.27, 0.24), (0.73, 0.24), (0.73, 0.33), (0.27, 0.33)]), "#e04a2a", "#6a1010", shine=0.2)
    c.shape(("p", [(0.44, 0.23), (0.56, 0.23), (0.56, 0.34), (0.44, 0.34)]), "#f0f4ff", "#6a7490")
    c.glow(("p", [(0.5, 0.25), (0.53, 0.29), (0.5, 0.32), (0.47, 0.29)]), "#ff5a1a", 0.008)
    return c.done()


def frost():
    c = Canvas(); c.aura("#5ad8ff")
    c.shape(("p", TORSO), "#7ab8e8", "#163266")
    for sp in ([(0.12, 0.8), (0.02, 0.44), (0.22, 0.7)], [(0.21, 0.73), (0.2, 0.46), (0.3, 0.68)], [(0.05, 0.86), (-0.02, 0.62), (0.12, 0.78)]):
        pair(c, sp, "#f4ffff", "#3a9ae0")
    c.shape(("p", [(0.5, 0.04), (0.61, 0.14), (0.73, 0.32), (0.76, 0.62), (0.62, 0.74), (0.38, 0.74), (0.24, 0.62), (0.27, 0.32), (0.39, 0.14)]), "#9ad8ff", "#1c4a98")
    c.shape(("p", [(0.5, 0.2), (0.64, 0.31), (0.66, 0.5), (0.5, 0.7), (0.34, 0.5), (0.36, 0.31)]), "#121e40", "#03050e", shine=0, rim="#e8fcff")
    eyes(c, 0.37, 0.48, 0.4, "#46d8ff", h=0.028)
    c.shape(("p", [(0.22, 0.64), (0.3, 0.72), (0.36, 0.66), (0.43, 0.75), (0.5, 0.68), (0.57, 0.75), (0.64, 0.66), (0.7, 0.72), (0.78, 0.64), (0.8, 0.8), (0.2, 0.8)]), "#ffffff", "#8ccaf0")
    for cr in ([(0.5, 0.0), (0.545, 0.1), (0.5, 0.17), (0.455, 0.1)], [(0.38, 0.05), (0.44, 0.15), (0.37, 0.17)], [(0.62, 0.05), (0.63, 0.17), (0.56, 0.15)]):
        c.shape(("p", cr), "#ffffff", "#40b0f8", rim="#1a5aa0")
    c.glow(("p", [(0.5, 0.76), (0.55, 0.84), (0.5, 0.94), (0.45, 0.84)]), "#8ae8ff", 0.012)
    return c.done()


def volt():
    c = Canvas(); c.aura("#ffd21a")
    c.shape(("p", TORSO), "#8a52d8", "#240c58")
    c.shape(("p", [(0.3, 0.68), (0.5, 0.82), (0.7, 0.68), (0.74, 0.76), (0.5, 0.94), (0.26, 0.76)]), "#ffe65a", "#c08a00")
    c.flat(("p", [(0.52, 0.78), (0.43, 0.9), (0.5, 0.9), (0.46, 1.0), (0.59, 0.86), (0.52, 0.86), (0.57, 0.78)]), "#240c58")
    for g in ((0.0, 0.66, 0.26, 0.9), (0.74, 0.66, 1.0, 0.9)):
        c.shape(("e", g), "#ff6a6a", "#a31428")
        c.shape(("p", [(g[0] + 0.02, 0.88), (g[2] - 0.02, 0.88), (g[2] - 0.02, 1.0), (g[0] + 0.02, 1.0)]), "#ffe65a", "#c08a00", shine=0)
        for fx in (0.38, 0.5, 0.62):
            c.line([(g[0] + (g[2] - g[0]) * fx, 0.7), (g[0] + (g[2] - g[0]) * fx, 0.78)], "#7a0c1c", 5)
    c.shape(("p", [(0.42, 0.56), (0.58, 0.56), (0.6, 0.72), (0.4, 0.72)]), "#d99a74", "#8a4a2c", shine=0)
    c.shape(("p", [(0.32, 0.3), (0.36, 0.21), (0.64, 0.21), (0.68, 0.3), (0.67, 0.5), (0.58, 0.62), (0.5, 0.66), (0.42, 0.62), (0.33, 0.5)]), "#ffd0a8", "#b86e48", shine=0.25)
    c.shape(("p", [(0.3, 0.32), (0.16, 0.24), (0.3, 0.22), (0.18, 0.06), (0.38, 0.14), (0.36, -0.04), (0.52, 0.1), (0.66, -0.08), (0.66, 0.12), (0.88, 0.0), (0.74, 0.2), (0.92, 0.22), (0.72, 0.3), (0.62, 0.22), (0.46, 0.2), (0.36, 0.24)]), "#fff3a0", "#e89a00", shine=0.3)
    c.shape(("p", [(0.28, 0.34), (0.72, 0.31), (0.71, 0.41), (0.56, 0.44), (0.5, 0.41), (0.44, 0.44), (0.29, 0.43)]), "#4a3a90", "#140838", shine=0.1)
    eyes(c, 0.33, 0.46, 0.355, "#38e8ff", h=0.026)
    c.line([(0.44, 0.56), (0.53, 0.565), (0.58, 0.535)], "#3a0a0a", 7)  # smirk
    c.line([(0.06, 0.46), (0.14, 0.36), (0.09, 0.3), (0.2, 0.18)], "#fff08a", 4, glow=0.01)
    c.line([(0.94, 0.52), (0.86, 0.42), (0.92, 0.34), (0.82, 0.24)], "#fff08a", 4, glow=0.01)
    return c.done()


def shade():
    c = Canvas(); c.aura("#a83aff")
    for sgn in (1, -1):
        x = lambda v: 0.5 + sgn * (v - 0.5)
        c.shape(("p", [(x(0.02), 0.04), (x(0.1), 0.1), (x(0.6), 0.78), (x(0.55), 0.83)]), "#ffffff", "#7a72a8", rim="#1a1040")
        c.shape(("p", [(x(0.5), 0.74), (x(0.63), 0.69), (x(0.67), 0.8), (x(0.56), 0.88)]), "#6a3aa0", "#1e0a40")
    c.shape(("p", [(0.08, 1.0), (0.12, 0.8), (0.2, 0.74), (0.16, 0.86), (0.3, 0.68), (0.7, 0.68), (0.84, 0.86), (0.8, 0.74), (0.88, 0.8), (0.92, 1.0)]), "#3a2a5a", "#0a0614")
    c.line([(0.3, 0.74), (0.5, 0.94), (0.7, 0.74)], "#c070ff", 5, glow=0.01)
    c.shape(("p", [(0.5, -0.02), (0.6, 0.1), (0.72, 0.3), (0.75, 0.6), (0.64, 0.72), (0.36, 0.72), (0.25, 0.6), (0.28, 0.3), (0.4, 0.1)]), "#5a4488", "#120a24")
    c.shape(("p", [(0.5, 0.14), (0.64, 0.28), (0.66, 0.5), (0.5, 0.66), (0.34, 0.5), (0.36, 0.28)]), "#0b0716", "#030208", shine=0, rim="#8a5ac8")
    c.shape(("p", [(0.35, 0.49), (0.65, 0.49), (0.6, 0.58), (0.5, 0.68), (0.4, 0.58)]), "#2a1e48", "#08040f", shine=0.1)
    eyes(c, 0.36, 0.48, 0.385, "#ff2ad0", core="#ffe0f8", h=0.026)
    c.glow(("p", [(0.5, 0.06), (0.53, 0.11), (0.5, 0.16), (0.47, 0.11)]), "#c070ff", 0.008)
    return c.done()


def titan():
    c = Canvas(); c.aura("#8ad22a")
    sh = [(0.0, 0.92), (0.02, 0.66), (0.12, 0.56), (0.22, 0.58), (0.3, 0.62), (0.36, 0.78), (0.3, 1.0), (0.04, 1.0)]
    pair(c, sh, "#b0a07c", "#3a3024")
    pair(c, [(0.08, 0.6), (0.06, 0.44), (0.14, 0.56)], "#e8ffb0", "#4a9a10")  # shoulder crystals
    pair(c, [(0.16, 0.58), (0.2, 0.42), (0.24, 0.58)], "#e8ffb0", "#4a9a10")
    c.shape(("p", [(0.26, 1.0), (0.26, 0.72), (0.74, 0.72), (0.74, 1.0)]), "#8a7c5c", "#2e281c")
    c.glow(("p", [(0.5, 0.77), (0.58, 0.86), (0.5, 0.97), (0.42, 0.86)]), "#a8ff3a", 0.02, core="#f4ffc0")
    for cr in ([(0.4, 0.18), (0.36, 0.0), (0.46, 0.14)], [(0.47, 0.16), (0.52, -0.04), (0.56, 0.16)], [(0.58, 0.18), (0.66, 0.04), (0.64, 0.2)]):
        c.shape(("p", cr), "#f0ffc0", "#3a8a10", rim="#1a3a08")
    c.shape(("p", [(0.26, 0.44), (0.28, 0.2), (0.4, 0.12), (0.6, 0.12), (0.72, 0.2), (0.74, 0.44), (0.68, 0.66), (0.32, 0.66)]), "#c4b48c", "#4a3c2a")
    c.shape(("p", [(0.3, 0.52), (0.7, 0.52), (0.66, 0.67), (0.34, 0.67)]), "#9a8a68", "#36291c", shine=0.1)
    c.flat(("p", [(0.38, 0.555), (0.62, 0.555), (0.6, 0.59), (0.4, 0.59)]), "#140e06")
    pair(c, [(0.35, 0.6), (0.33, 0.46), (0.39, 0.56)], "#ffffff", "#b8b0a0")  # tusks
    c.shape(("p", [(0.26, 0.27), (0.5, 0.35), (0.74, 0.27), (0.73, 0.35), (0.5, 0.42), (0.27, 0.35)]), "#6a5c42", "#221a10", shine=0)
    eyes(c, 0.33, 0.46, 0.36, "#a8ff3a", core="#f4ffc0", h=0.026)
    c.line([(0.5, 0.13), (0.46, 0.2), (0.52, 0.27)], "#8aff2a", 3, glow=0.01)
    c.line([(0.68, 0.44), (0.62, 0.48), (0.64, 0.54)], "#8aff2a", 3)
    c.line([(0.2, 0.68), (0.14, 0.76), (0.18, 0.86)], "#8aff2a", 3, glow=0.01)
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
