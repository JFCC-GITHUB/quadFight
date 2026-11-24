#!/usr/bin/env python3
"""The six animal fighters as 16-bit pixel busts -> assets/chars/<id>.png (+ _s and _dark), same style as gen_characters.py.

Run: python3 tools/gen_animals.py [id ...]
"""
import math
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen_characters as gc  # noqa: E402
from gen_characters import TORSO, UP, W, Canvas, dark_variant, eyes, mir, pair  # noqa: E402


def ring(cx, cy, r, n=18):
    return [(cx + r * math.cos(i * math.tau / n), cy + r * math.sin(i * math.tau / n)) for i in range(n + 1)]


# ------------------------------------------------------------------ IRONPAW: a scarred bear warrior
def ironpaw():
    c = Canvas(); c.aura("#ff8a2a")
    c.shape(("p", TORSO), "#5a4a52", "#1c1620")
    c.shape(("p", [(0.32, 0.72), (0.68, 0.72), (0.64, 0.9), (0.5, 1.0), (0.36, 0.9)]), "#b4bacb", "#3a4256")  # iron chest plate
    for x, y in ((0.38, 0.77), (0.62, 0.77), (0.5, 0.93)):
        c.flat(("e", (x - 0.012, y - 0.012, x + 0.012, y + 0.012)), "#ffd27a")
    pair(c, [(0.0, 0.98), (0.02, 0.74), (0.09, 0.78), (0.1, 0.64), (0.19, 0.7), (0.22, 0.6), (0.31, 0.68), (0.32, 0.92)], "#d09a5c", "#4a2c18")  # fur mantle
    c.off = (0.02, 0.01)
    pair(c, [(0.22, 0.14), (0.3, 0.1), (0.4, 0.14), (0.42, 0.28), (0.26, 0.3)], "#b07a44", "#4a2c18")  # ears
    pair(c, [(0.27, 0.17), (0.31, 0.15), (0.37, 0.2), (0.35, 0.26), (0.28, 0.27)], "#f0b888", "#a86a3c", shine=0)
    c.shape(("p", [(0.26, 0.34), (0.3, 0.2), (0.4, 0.14), (0.6, 0.14), (0.7, 0.2), (0.74, 0.34), (0.74, 0.52), (0.66, 0.66), (0.34, 0.66), (0.26, 0.52)]), "#cc975c", "#5a3418")
    c.shape(("e", (0.36, 0.44, 0.64, 0.68)), "#f4d8b0", "#b08a60")  # muzzle
    c.shape(("p", [(0.44, 0.47), (0.56, 0.47), (0.5, 0.54)]), "#2a1a1a", "#0a0606", shine=0)
    c.line([(0.5, 0.54), (0.5, 0.6)], "#2a1a1a", 5)
    c.line([(0.42, 0.63), (0.5, 0.6), (0.58, 0.63)], "#2a1a1a", 5)
    for k in range(3):  # claw scar across the left eye
        c.line([(0.28 + k * 0.035, 0.2), (0.4 + k * 0.035, 0.52)], "#ff6a5a", 5)
    eyes(c, 0.34, 0.46, 0.33, "#ffb02a", core="#fff0c0", h=0.024)
    c.flat(("p", [(0.3, 0.3), (0.48, 0.35), (0.3, 0.33)]), "#4a2810")  # heavy brow
    c.flat(("p", mir([(0.3, 0.3), (0.48, 0.35), (0.3, 0.33)])), "#4a2810")
    return c.done()


# ------------------------------------------------------------------ MOONFANG: a silver lone wolf
def moonfang():
    c = Canvas(); c.aura("#6aa8ff")
    c.shape(("p", TORSO), "#3a4258", "#10141f")
    c.shape(("p", [(0.3, 0.68), (0.7, 0.68), (0.74, 0.8), (0.92, 0.86), (0.8, 0.96), (0.66, 0.84), (0.34, 0.84)]), "#5a7ae0", "#1a2a68")  # ragged scarf
    c.shape(("e", (0.44, 0.84, 0.58, 0.98)), "#f0f6ff", "#9ab4e0")  # crescent moon
    c.flat(("e", (0.49, 0.83, 0.62, 0.97)), "#27345f")
    pair(c, [(0.12, 0.8), (0.18, 0.62), (0.24, 0.7), (0.3, 0.56), (0.34, 0.76)], "#dce4f4", "#6a7488")  # neck fur
    c.off = (-0.02, 0.0)
    pair(c, [(0.28, 0.32), (0.25, 0.0), (0.44, 0.2)], "#b4bdd0", "#4a5468")
    pair(c, [(0.31, 0.26), (0.29, 0.08), (0.39, 0.2)], "#2a3248", "#161c2c", shine=0)
    c.shape(("p", [(0.3, 0.36), (0.38, 0.2), (0.5, 0.16), (0.62, 0.2), (0.7, 0.36), (0.78, 0.52), (0.66, 0.58), (0.5, 0.62), (0.34, 0.58), (0.22, 0.52)]), "#d6deee", "#5a6478")
    c.shape(("p", [(0.4, 0.46), (0.6, 0.46), (0.58, 0.62), (0.5, 0.68), (0.42, 0.62)]), "#f4f8ff", "#9aa4b8")
    c.shape(("p", [(0.46, 0.5), (0.54, 0.5), (0.5, 0.57)]), "#2a3248", "#0a0e18", shine=0)  # nose
    c.line([(0.5, 0.57), (0.5, 0.62)], "#2a3248", 3)
    for x in (0.44, 0.555):
        c.flat(("p", [(x, 0.6), (x + 0.025, 0.6), (x + 0.012, 0.67)]), "#ffffff")  # fangs
    eyes(c, 0.34, 0.46, 0.34, "#46c8ff", core="#e0f8ff", h=0.026)
    c.line([(0.34, 0.45), (0.29, 0.55)], "#5a6478", 4)
    c.line([(0.66, 0.45), (0.71, 0.55)], "#5a6478", 4)
    return c.done()


# ------------------------------------------------------------------ NIGHTOWL: a wise night owl in round glasses
def nightowl():
    c = Canvas(); c.aura("#ffd24a")
    c.shape(("p", TORSO), "#2a3a78", "#0a1030")
    pair(c, [(0.02, 0.98), (0.04, 0.68), (0.14, 0.6), (0.3, 0.66), (0.3, 0.94)], "#4a5ab0", "#10184a")  # folded wings
    for x in (0.1, 0.16, 0.22):
        c.line([(x, 0.7), (x + 0.02, 0.92)], "#8a9ae0", 3)
        c.line([(1 - x, 0.7), (1 - x - 0.02, 0.92)], "#8a9ae0", 3)
    c.shape(("p", [(0.34, 0.7), (0.66, 0.7), (0.62, 0.9), (0.5, 1.0), (0.38, 0.9)]), "#eadcc0", "#a8987a")  # belly
    for y in (0.78, 0.86, 0.94):
        c.line([(0.42, y), (0.5, y + 0.04), (0.58, y)], "#8a7858", 3)
    c.off = (0.0, 0.01)
    pair(c, [(0.3, 0.28), (0.2, 0.0), (0.44, 0.16)], "#8a7a6a", "#3a2e2a")  # ear tufts
    c.shape(("e", (0.22, 0.14, 0.78, 0.68)), "#9a8a78", "#3a2e2a")
    for box in ((0.27, 0.27, 0.5, 0.56), (0.5, 0.27, 0.73, 0.56)):  # facial discs
        c.shape(("e", box), "#f4e8d0", "#b8a888", shine=0.2)
    for cx in (0.385, 0.615):
        c.glow(("e", (cx - 0.075, 0.32, cx + 0.075, 0.48)), "#ffc21a", 0.012, core="#fff2a8")
        c.flat(("e", (cx - 0.02, 0.37, cx + 0.02, 0.45)), "#1a1020")
        c.line(ring(cx, 0.4, 0.1), "#e0a820", 6)  # glasses
    c.line([(0.485, 0.4), (0.515, 0.4)], "#e0a820", 6)
    c.flat(("p", [(0.28, 0.27), (0.48, 0.34), (0.28, 0.32)]), "#3a2e2a")
    c.flat(("p", mir([(0.28, 0.27), (0.48, 0.34), (0.28, 0.32)])), "#3a2e2a")
    c.shape(("p", [(0.46, 0.5), (0.54, 0.5), (0.5, 0.63)]), "#ffb040", "#c86a10")  # beak
    return c.done()


# ------------------------------------------------------------------ OLDSHELL: an old turtle monk
def oldshell():
    c = Canvas(); c.aura("#8ac040")
    c.shape(("e", (-0.02, 0.28, 1.02, 1.2)), "#9a7a44", "#2a1c0c")  # the shell behind
    for cx, cy in ((0.14, 0.62), (0.86, 0.62), (0.3, 0.88), (0.7, 0.88), (0.5, 0.97), (0.08, 0.92), (0.92, 0.92)):
        c.line(ring(cx, cy, 0.1, 6), "#5a4020", 5)
    c.shape(("p", TORSO), "#6a5836", "#241a0c")
    c.line([(0.3, 0.8), (0.7, 0.8)], "#58b048", 8)  # green sash
    c.off = (0.015, 0.02)
    c.shape(("e", (0.26, 0.22, 0.74, 0.72)), "#92c864", "#2a5a28")
    c.line([(0.38, 0.66), (0.62, 0.66)], "#2a5a28", 3)  # neck fold
    c.shape(("p", [(0.5, -0.02), (0.74, 0.2), (0.92, 0.3), (0.08, 0.3), (0.26, 0.2)]), "#f2d686", "#9c7430")  # straw hat
    for x in (0.3, 0.4, 0.5, 0.6, 0.7):
        c.line([(0.5, 0.0), (x + (x - 0.5) * 0.7, 0.29)], "#b8903c", 2)
    eyes(c, 0.36, 0.46, 0.4, "#ffc23a", h=0.012)
    c.line([(0.4, 0.58), (0.6, 0.58)], "#2a3a18", 4)
    pair(c, [(0.5, 0.56), (0.36, 0.57), (0.26, 0.7), (0.42, 0.62)], "#ffffff", "#b0b8c8")  # mustache
    c.shape(("p", [(0.42, 0.6), (0.58, 0.6), (0.55, 0.84), (0.5, 0.98), (0.45, 0.84)]), "#ffffff", "#b0b8c8")  # beard
    pair(c, [(0.34, 0.36), (0.48, 0.38), (0.34, 0.4)], "#ffffff", "#b0b8c8", shine=0)
    return c.done()


# ------------------------------------------------------------------ LILYHOP: a ronin frog with a lily-pad hat
def lilyhop():
    c = Canvas(); c.aura("#6aff8a")
    c.shape(("p", [(0.78, 0.46), (0.83, 0.46), (0.92, 0.84), (0.87, 0.86)]), "#dce4f0", "#7a8498")  # sword behind the shoulder
    c.shape(("p", [(0.74, 0.44), (0.88, 0.44), (0.88, 0.48), (0.74, 0.48)]), "#ffd27a", "#a87a28")
    c.shape(("p", TORSO), "#3a8a8a", "#0a3a4a")
    c.line([(0.3, 0.78), (0.7, 0.78)], "#ff9ab8", 8)  # pink sash
    c.off = (0.0, 0.07)
    c.shape(("e", (0.36, 0.58, 0.64, 0.8)), "#ecf6b0", "#9ab860")  # throat pouch
    c.shape(("p", [(0.14, 0.34), (0.28, 0.28), (0.5, 0.26), (0.72, 0.28), (0.86, 0.34), (0.84, 0.52), (0.7, 0.62), (0.3, 0.62), (0.16, 0.52)]), "#92e668", "#2a7a38")
    for box in ((0.18, 0.12, 0.4, 0.36), (0.6, 0.12, 0.82, 0.36)):  # bulging eyes
        c.shape(("e", box), "#9aee70", "#2a8a3a")
    for cx in (0.29, 0.71):
        c.glow(("e", (cx - 0.06, 0.18, cx + 0.06, 0.3)), "#ffc21a", 0.01, core="#fff2a8")
        c.flat(("p", [(cx - 0.05, 0.236), (cx + 0.05, 0.236), (cx + 0.05, 0.256), (cx - 0.05, 0.256)]), "#1a1020")
    c.line([(0.22, 0.52), (0.4, 0.58), (0.6, 0.58), (0.78, 0.5)], "#1a4a20", 4)
    c.line([(0.6, 0.58), (0.74, 0.67), (0.88, 0.6)], "#c8f060", 4)  # a blade of grass
    c.shape(("e", (0.14, -0.08, 0.86, 0.12)), "#62cc4c", "#1a6a28")  # lily-pad hat
    c.line([(0.5, 0.02), (0.26, -0.02)], "#2a8a38", 3)
    c.line([(0.5, 0.02), (0.74, -0.02)], "#2a8a38", 3)
    pair(c, [(0.5, -0.02), (0.43, -0.08), (0.47, 0.04)], "#ffb0c8", "#e0608a", shine=0)
    c.flat(("e", (0.475, -0.07, 0.525, -0.01)), "#ffe6f0")
    return c.done()


# ------------------------------------------------------------------ MASKCAT: a masked cat burglar
def maskcat():
    c = Canvas(); c.aura("#c070ff")
    c.line([(0.78, 0.98), (0.95, 0.82), (0.93, 0.62), (0.82, 0.54)], "#2a1a3a", 22)  # tail curling behind
    c.line([(0.78, 0.98), (0.95, 0.82), (0.93, 0.62), (0.82, 0.54)], "#f6eef6", 14)
    c.shape(("p", TORSO), "#7a3ab0", "#2a0a50")
    c.shape(("p", [(0.3, 0.7), (0.5, 0.82), (0.7, 0.7), (0.74, 0.78), (0.5, 0.96), (0.26, 0.78)]), "#fff0fa", "#c8a0d8")  # collar
    c.flat(("e", (0.46, 0.86, 0.54, 0.94)), "#ff7ab8")
    c.off = (0.02, 0.0)
    pair(c, [(0.26, 0.32), (0.23, 0.02), (0.43, 0.2)], "#f8f0f8", "#b8a8c0")
    pair(c, [(0.28, 0.26), (0.27, 0.1), (0.38, 0.2)], "#ff9ac8", "#d0508a", shine=0)
    c.shape(("p", [(0.26, 0.36), (0.34, 0.2), (0.5, 0.16), (0.66, 0.2), (0.74, 0.36), (0.78, 0.5), (0.64, 0.64), (0.36, 0.64), (0.22, 0.5)]), "#fffafe", "#d8c8e0")
    c.shape(("p", [(0.25, 0.34), (0.5, 0.31), (0.75, 0.34), (0.73, 0.46), (0.6, 0.45), (0.5, 0.42), (0.4, 0.45), (0.27, 0.46)]), "#9a46d8", "#3a0a68")  # half mask
    eyes(c, 0.33, 0.46, 0.365, "#a8ff3a", core="#f4ffc0", h=0.022)
    c.flat(("p", [(0.47, 0.52), (0.53, 0.52), (0.5, 0.56)]), "#ff7ab8")
    c.line([(0.4, 0.6), (0.5, 0.58), (0.6, 0.6)], "#7a3a68", 4)
    c.flat(("p", [(0.57, 0.6), (0.6, 0.6), (0.585, 0.66)]), "#ffffff")  # one fang
    for dy in (-0.02, 0.02):  # whiskers
        c.line([(0.36, 0.55 + dy), (0.12, 0.52 + dy * 2)], "#ffffff", 3)
        c.line([(0.64, 0.55 + dy), (0.88, 0.52 + dy * 2)], "#ffffff", 3)
    return c.done()


ANIMALS = {"ironpaw": ironpaw, "moonfang": moonfang, "nightowl": nightowl, "oldshell": oldshell, "lilyhop": lilyhop,
           "maskcat": maskcat}


def main(only=None):
    os.makedirs(gc.OUT, exist_ok=True)
    cell = W * UP
    sheet = Image.new("RGB", (3 * cell, 2 * cell), (18, 14, 34))
    for i, (cid, fn) in enumerate(ANIMALS.items()):
        if only and cid not in only:
            continue
        im = fn()
        im.save(os.path.join(gc.OUT, cid + ".png"))
        im.crop((16 * UP, 0, 80 * UP, 64 * UP)).resize((128, 128), Image.NEAREST).save(os.path.join(gc.OUT, cid + "_s.png"))
        dark_variant(im).save(os.path.join(gc.OUT, cid + "_dark.png"))
        sheet.paste(im, ((i % 3) * cell, (i // 3) * cell), im)
    sheet.save(os.path.join(os.environ.get("SHEET_DIR", "/tmp"), "animals_sheet.png"))
    print("animals written to", gc.OUT)


if __name__ == "__main__":
    main(sys.argv[1:] or None)
