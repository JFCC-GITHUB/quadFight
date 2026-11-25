"""Pixel kit v3: native-resolution canvas, contour-following shading (bands hugging the lit / shadow edge, jagged into
fur tufts), hue-shifted ramps, selective outlines, ASCII stamps for faces and details. Coordinates are real pixels."""
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

    def part(self, m, ramp, outline=True, fur=False, hi=True):
        """ramp = [highlight, light, mid, dark, deep], hue-shifted (warm lights, cool/purple shadows). Light from the
        upper left. Shading bands hug the edges; with fur=True their inner edge is jagged (pointed tufts).
        Selective outline: the lit (top) side gets the dark tone, the rest the deep tone."""
        col = [rgb(c) for c in ramp]
        if outline:
            g = m | shift(m, 1, 0) | shift(m, -1, 0) | shift(m, 0, 1) | shift(m, 0, -1)
            o = g & ~m
            self.px[o] = (*col[4], 255)
            self.px[o & shift(m, 0, -1) & (self.yy < self.cy(m))] = (*col[3], 255)
        dl = self.depth(m, lambda k: shift(m, 0, k) & shift(m, k, k))
        ds = self.depth(m, lambda k: shift(m, 0, -k) & shift(m, -k, -k))
        saw = np.array([0, 1, 2, 1])
        tl = saw[self.xx % 4] if fur else 0
        ts = saw[(self.xx + 2) % 4] if fur else 0
        self.px[m] = (*col[2], 255)
        self.px[m & (dl <= 2 + tl)] = (*col[1], 255)
        self.px[m & (ds <= 2 + ts)] = (*col[3], 255)
        if hi:
            self.px[m & (dl <= 1) & ~shift(m, 0, 1) & (self.xx < self.cx(m) + 2)] = (*col[0], 255)

    @staticmethod
    def depth(m, inner, K=6):
        d = np.full(m.shape, 99)
        for k in range(K, 0, -1):
            d[m & ~inner(k)] = k
        return d

    def cx(self, m):
        xs = np.nonzero(m)[1]
        return (xs.min() + xs.max()) / 2 if len(xs) else 0

    def cy(self, m):
        ys = np.nonzero(m)[0]
        return (ys.min() + ys.max()) / 2 if len(ys) else 0

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
