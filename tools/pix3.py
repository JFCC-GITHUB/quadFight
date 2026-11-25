"""Pixel kit v3: native-resolution canvas, contour-following shading (bands hugging the lit / shadow edge, like a
hand-pixeled sprite), 1px outline tinted per part, ASCII stamps for faces and details. Coordinates are real pixels."""
import numpy as np
from PIL import Image, ImageDraw


def rgb(h):
    h = h.lstrip("#")
    if len(h) == 3:
        h = "".join(c * 2 for c in h)
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def shift(m, dx, dy):
    out = np.zeros_like(m)
    h, w = m.shape
    ys, yd = (slice(dy, h), slice(0, h - dy)) if dy >= 0 else (slice(0, h + dy), slice(-dy, h))
    xs, xd = (slice(dx, w), slice(0, w - dx)) if dx >= 0 else (slice(0, w + dx), slice(-dx, w))
    out[ys, xs] = m[yd, xd]
    return out


class Cv:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.px = np.zeros((h, w, 4), np.uint8)
        self.yy, self.xx = np.mgrid[0:h, 0:w]

    def poly(self, *pts):
        m = Image.new("L", (self.w, self.h), 0)
        ImageDraw.Draw(m).polygon(list(pts), fill=255)
        return np.array(m) > 0

    def ell(self, cx, cy, rx, ry):
        return ((self.xx + 0.5 - cx) / rx) ** 2 + ((self.yy + 0.5 - cy) / ry) ** 2 <= 1.0

    def rect(self, x0, y0, x1, y1):
        return (self.xx >= x0) & (self.xx <= x1) & (self.yy >= y0) & (self.yy <= y1)

    def part(self, m, ramp, outline=True, dither=True, hi=True):
        """ramp = [highlight, light, mid, dark, deep]. Light comes from the upper left."""
        col = [rgb(c) for c in ramp]
        if outline:
            g = m.copy()
            g |= shift(m, 1, 0) | shift(m, -1, 0) | shift(m, 0, 1) | shift(m, 0, -1)
            self.px[g & ~m] = (*col[4], 255)
        self.px[m] = (*col[2], 255)
        lit = lambda k: m & ~shift(m, k, k)          # band of thickness k on the upper-left edge
        sha = lambda k: m & ~shift(m, -k, -k)        # band on the lower-right edge
        if dither:                                   # checker between mid and dark / light
            chk = ((self.xx + self.yy) % 2 == 0)
            self.px[sha(4) & chk] = (*col[3], 255)
            self.px[lit(4) & chk] = (*col[1], 255)
        self.px[lit(2)] = (*col[1], 255)
        self.px[sha(2)] = (*col[3], 255)
        if hi:
            self.px[lit(1) & ~shift(m, 0, 1) | (m & ~shift(m, 0, 1))] = (*col[0], 255)
        self.px[m & ~shift(m, -1, -1) & ~shift(m, 0, -1) & ~shift(m, -1, 0)] = (*col[3], 255)

    def stamp(self, x, y, rows, pal):
        for j, row in enumerate(rows):
            for i, ch in enumerate(row):
                if ch in pal and 0 <= x + i < self.w and 0 <= y + j < self.h:
                    self.px[y + j, x + i] = (*rgb(pal[ch]), 255)

    def dots(self, pts, color):
        for x, y in pts:
            if 0 <= x < self.w and 0 <= y < self.h:
                self.px[y, x] = (*rgb(color), 255)

    def line(self, p0, p1, color):
        n = int(max(abs(p1[0] - p0[0]), abs(p1[1] - p0[1]))) + 1
        self.dots([(round(p0[0] + (p1[0] - p0[0]) * i / max(n - 1, 1)),
                    round(p0[1] + (p1[1] - p0[1]) * i / max(n - 1, 1))) for i in range(n)], color)

    def fur(self, m, color, n=40, seed=1, length=2):
        rng = np.random.default_rng(seed)
        ys, xs = np.nonzero(m)
        for i in rng.integers(0, len(xs), n):
            x, y = int(xs[i]), int(ys[i])
            for j in range(length):
                if 0 <= x + j // 2 < self.w and 0 <= y + j < self.h and m[y + j, x + j // 2]:
                    self.px[y + j, x + j // 2] = (*rgb(color), 255)

    def image(self, up=6):
        return Image.fromarray(self.px, "RGBA").resize((self.w * up, self.h * up), Image.NEAREST)
