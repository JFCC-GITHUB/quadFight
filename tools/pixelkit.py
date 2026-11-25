"""A tiny pixel-art kit: 96x96 sprites built from curved parts (flat 4-tone cel shading, 1px ink outline per part)
plus hand-typed ASCII stamps for faces and details. Coordinates are in 48-unit space (1 unit = S pixels) so shapes stay
easy to place; `native=True` / the *1 helpers work in real pixels for fine detail. Output is enlarged 5x (480 px)."""
import numpy as np
from PIL import Image, ImageDraw

N, S, UP = 96, 2, 5
YY, XX = np.mgrid[0:N, 0:N]
UX, UY = (XX + 0.5) / S, (YY + 0.5) / S   # pixel centres in unit space


def rgb(h):
    h = h.lstrip("#")
    if len(h) == 3:
        h = "".join(ch * 2 for ch in h)
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def E(cx, cy, rx, ry):
    return ((UX - cx) / rx) ** 2 + ((UY - cy) / ry) ** 2 <= 1.0


def P(*pts):
    m = Image.new("L", (N, N), 0)
    ImageDraw.Draw(m).polygon([(x * S, y * S) for x, y in pts], fill=255)
    return np.array(m) > 0


def R(x0, y0, x1, y1):
    return (UX >= x0) & (UX <= x1 + 1) & (UY >= y0) & (UY <= y1 + 1)


def flip(mask):
    return mask[:, ::-1]


class Sprite:
    def __init__(self):
        self.px = np.zeros((N, N, 4), np.uint8)

    def part(self, mask, ramp, light=(-0.5, -0.8), outline=True, rim=True):
        """ramp: [highlight, light, mid, dark, ink] hex colours. Flat 4-tone shading lit from the upper left."""
        if not mask.any():
            return
        ys, xs = np.nonzero(mask)
        cx, cy = (xs.min() + xs.max()) / 2.0, (ys.min() + ys.max()) / 2.0
        rx, ry = max((xs.max() - xs.min()) / 2.0, 1.0), max((ys.max() - ys.min()) / 2.0, 1.0)
        nx, ny = (XX - cx) / rx, (YY - cy) / ry
        lx, ly = light
        b = 0.5 - 0.5 * (nx * lx + ny * ly)                 # 1 = facing the light (upper left)
        r2 = np.clip(nx ** 2 + ny ** 2, 0, 1.5)
        b = b - 0.22 * r2 ** 1.5                            # darker toward the rim
        col = [rgb(c) for c in ramp]
        tone = np.where(b > 0.72, 0, np.where(b > 0.5, 1, np.where(b > 0.25, 2, 3)))
        if outline:
            grown = mask.copy()
            grown[1:] |= mask[:-1]; grown[:-1] |= mask[1:]; grown[:, 1:] |= mask[:, :-1]; grown[:, :-1] |= mask[:, 1:]
            self.px[grown & ~mask] = (*col[4], 255)
        for t in range(4):
            self.px[mask & (tone == t)] = (*col[t], 255)
        if rim:  # a crisp 1px highlight on the lit upper edge
            up = np.zeros_like(mask)
            up[1:] = mask[1:] & ~mask[:-1]
            self.px[up & (XX < cx + rx * 0.5)] = (*col[0], 255)

    def stamp(self, x, y, rows, pal, native=False):
        k = 1 if native else S
        for j, row in enumerate(rows):
            for i, ch in enumerate(row):
                if ch == "." or ch not in pal:
                    continue
                px, py = int((x + i) * k), int((y + j) * k)
                for dy in range(k):
                    for dx in range(k):
                        if 0 <= px + dx < N and 0 <= py + dy < N:
                            self.px[py + dy, px + dx] = (*rgb(pal[ch]), 255)

    def mstamp(self, x, y, rows, pal, native=False):
        """Stamp at x and mirrored about the vertical centre of the sprite."""
        self.stamp(x, y, rows, pal, native)
        w = max(len(r) for r in rows)
        self.stamp((N if native else N / S) - x - w, y, [r[::-1] for r in rows], pal, native)

    def line(self, p0, p1, color, native=False):
        k = 1 if native else S
        n = int(max(abs(p1[0] - p0[0]), abs(p1[1] - p0[1]))) + 1
        self.dots([(round(p0[0] + (p1[0] - p0[0]) * i / max(n - 1, 1)), round(p0[1] + (p1[1] - p0[1]) * i / max(n - 1, 1))) for i in range(n)], color, native)

    def dots(self, pts, color, native=False):
        k = 1 if native else S
        for x, y in pts:
            for dy in range(k):
                for dx in range(k):
                    px, py = int(x * k) + dx, int(y * k) + dy
                    if 0 <= px < N and 0 <= py < N:
                        self.px[py, px] = (*rgb(color), 255)

    def fur(self, mask, color, n=70, seed=1, length=3):
        """Short fur strokes sprinkled inside `mask`, slanting down and to the right."""
        rng = np.random.default_rng(seed)
        ys, xs = np.nonzero(mask)
        for i in rng.integers(0, len(xs), n):
            x, y = int(xs[i]), int(ys[i])
            for j in range(length):
                px, py = x + j // 2, y + j
                if 0 <= px < N and 0 <= py < N and mask[py, px]:
                    self.px[py, px] = (*rgb(color), 255)

    def glow(self, color, strength=0.5):
        """A dithered halo around the figure (checker pattern), like the other busts."""
        a = self.px[..., 3] > 0
        g = a.copy()
        for _ in range(2):
            g2 = g.copy()
            g2[1:] |= g[:-1]; g2[:-1] |= g[1:]; g2[:, 1:] |= g[:, :-1]; g2[:, :-1] |= g[:, 1:]
            g = g2
        halo = g & ~a & ((XX + YY) % 2 == 0)
        self.px[halo] = (*rgb(color), 150)

    def image(self):
        return Image.fromarray(self.px, "RGBA")

    def done(self):
        return self.image().resize((N * UP, N * UP), Image.NEAREST)
