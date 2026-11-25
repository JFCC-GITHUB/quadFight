#!/usr/bin/env python3
"""Animal fighters as hand-built 48x48 pixel art (see pixelkit.py).

Writes assets/chars/<id>.png (480 px), <id>_s.png and <id>_dark.png. Run: python3 tools/gen_animals2.py [id ...]
"""
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pixelkit import E, N, P, R, UP, Sprite, flip  # noqa: E402
import gen_characters as gc  # noqa: E402

INK = "#1c1210"
FUR = ["#e0a868", "#b87c44", "#8a5a30", "#5a3418", "#24120a"]
CREAM = ["#fff0d8", "#f0d8b0", "#c8a478", "#8a6a48", "#24120a"]
IRON = ["#e8ecf4", "#b4bccc", "#7a849c", "#3e465e", "#14182a"]
CLOTH = ["#6a5a66", "#4a3e4e", "#32283a", "#1c1424", "#0c0810"]
PINK = ["#ffd0b0", "#f0a888", "#c8705a", "#8a4040", "#24120a"]


def both(s, mask, ramp, **kw):
    """The part and its mirror image."""
    s.part(mask, ramp, **kw)
    s.part(flip(mask), ramp, **kw)


# ------------------------------------------------------------------ IRONPAW: a scarred bear warrior
def ironpaw():
    s = Sprite()
    s.part(R(3, 38, 44, 47) | E(24, 47, 21, 8), CLOTH)
    s.part(P((15, 37), (32, 37), (30, 46), (24, 47), (17, 46)), IRON)                        # iron chest plate
    s.line((24, 38), (24, 46), "#3e465e")
    s.dots([(19, 40), (28, 40), (19, 44), (28, 44)], "#ffd27a")
    both(s, E(9, 42, 8, 6) | P((1, 47), (1, 40), (4, 43), (5, 37), (9, 42), (12, 37), (14, 43), (15, 47)), FUR)  # fur mantle
    both(s, E(11, 10, 5, 5), FUR)                                                            # ears
    both(s, E(11, 10, 2.5, 2.5), PINK, outline=False, rim=False)
    s.part(E(24, 21, 16, 13) | E(10, 24, 5, 6) | E(37, 24, 5, 6), FUR)                       # head and cheek ruff
    s.part(E(24, 28, 9, 6), CREAM)                                                           # muzzle
    s.stamp(20, 25, ["oooooooo", "okkkkkko", ".okkkko.", "..oooo.."], {"o": INK, "k": INK})  # nose
    s.line((24, 29), (24, 31), INK)
    s.stamp(19, 32, ["oo....oo", ".oooooo."], {"o": INK})                                     # frown
    eye = ["oEWEEo.", ".oEEEo."]
    pal = {"o": INK, "E": "#ffb02a", "W": "#fff0c0"}
    s.mstamp(13, 18, eye, pal)
    s.mstamp(12, 15, ["oooo...", ".oooooo"], {"o": "#3a2010"})                                 # heavy brow, slanted
    for k in range(3):                                                                       # three claw scars over the left eye
        s.line((11 + k * 2, 11 + k), (17 + k * 2, 26 + k), "#ff6a5a")
    return s.done()


# ------------------------------------------------------------------ MOONFANG: a silver lone wolf
FUR_W = ["#f4f8ff", "#c8d2e6", "#8a98b4", "#4a5670", "#10141f"]
SCARF = ["#8aaaff", "#5a7ae0", "#3a52b0", "#1e2c70", "#0a1034"]
NAVY = ["#4a5878", "#323e5c", "#222c46", "#141a2c", "#080a14"]


def moonfang():
    s = Sprite()
    s.part(R(3, 38, 44, 47) | E(24, 47, 21, 8), NAVY)
    s.part(P((13, 36), (34, 36), (38, 40), (46, 43), (40, 47), (33, 42), (15, 42)), SCARF)  # ragged scarf
    s.part(E(24, 44, 4, 4), ["#fff", "#f0f6ff", "#b8ccee", "#7a94c8", INK])                  # the moon
    s.part(E(26, 43, 4, 4), SCARF, outline=False, rim=False)
    both(s, P((4, 45), (7, 37), (10, 41), (13, 34), (16, 40), (18, 46)), FUR_W)               # neck fur
    both(s, P((9, 20), (8, 2), (21, 12)), FUR_W)                                              # tall ears
    both(s, P((11, 17), (11, 7), (18, 13)), ["#6a7a98", "#3a4660", "#242c40", "#161c2c", INK], outline=False, rim=False)
    s.part(P((10, 22), (15, 13), (24, 10), (33, 13), (38, 22), (43, 29), (34, 33), (24, 36), (14, 33), (5, 29)), FUR_W)  # head
    s.part(E(24, 29, 6, 8), ["#fff", "#f4f8ff", "#c8d2e6", "#8a98b4", INK])  # muzzle
    s.stamp(21, 27, ["oooooo", ".okko.", "..oo.."], {"o": INK, "k": "#2a3248"})               # nose
    s.line((24, 30), (24, 33), INK)
    s.dots([(21, 33), (21, 34), (27, 33), (27, 34)], "#ffffff")                                # fangs
    s.dots([(20, 33), (28, 33)], INK)
    pal = {"o": INK, "E": "#46c8ff", "W": "#e8faff"}
    s.mstamp(12, 19, [".ooooo", "oEWEEo", ".ooEo."], pal)
    s.mstamp(10, 23, ["o....", ".o..."], {"o": "#5a6478"})
    return s.done()


# ------------------------------------------------------------------ NIGHTOWL: a wise night owl in round glasses
PLUM = ["#d8c8b0", "#a89478", "#74604c", "#44362c", "#1c1410"]
WING = ["#6a7ad0", "#4a5ab0", "#2a3a80", "#161e50", "#080c24"]
FACE = ["#fffbe8", "#f4e8d0", "#d0bc98", "#a08c68", "#1c1410"]
GOLD = ["#fff2a8", "#ffd24a", "#e0a020", "#a06a10", "#4a2a08"]


def nightowl():
    s = Sprite()
    s.part(R(4, 38, 43, 47) | E(24, 47, 20, 8), WING)
    both(s, E(10, 42, 7, 6) | P((3, 47), (3, 38), (6, 36), (14, 38), (15, 47)), WING)
    for x in (6, 10, 14):
        s.line((x, 40), (x + 1, 46), "#8a9ae0")
        s.line((47 - x, 40), (46 - x, 46), "#8a9ae0")
    s.part(P((15, 37), (33, 37), (30, 46), (24, 47), (18, 46)), FACE)                         # belly
    for y in (40, 43):
        s.line((19, y), (24, y + 2), "#a08c68"); s.line((24, y + 2), (29, y), "#a08c68")
    both(s, P((11, 15), (7, 3), (20, 9)), PLUM)                                               # ear tufts
    s.part(E(24, 22, 16, 15), PLUM)
    both(s, E(15, 24, 8, 8), FACE)                                                            # facial discs
    for cx in (15, 33):
        s.part(E(cx, 24, 5, 5), GOLD)
        s.stamp(cx - 1, 22, ["oo", "oo", "oo"], {"o": INK})                                   # pupils
        s.dots([(cx - 3, 21), (cx - 3, 22)], "#fffbe8")
    ring = lambda cx: E(cx, 24, 7, 7) & ~E(cx, 24, 5.4, 5.4)                                  # glasses
    s.part(ring(15) | ring(33), GOLD, outline=False)
    s.line((21, 24), (27, 24), "#e0a020")
    s.mstamp(7, 14, [".....oo", "oooooo."], {"o": "#2a2018"})                                 # angry brows
    s.part(P((22, 28), (26, 28), (24, 36)), ["#ffd27a", "#ffb040", "#d07818", "#8a4a08", INK])  # beak
    return s.done()


# ------------------------------------------------------------------ OLDSHELL: an old turtle monk
SKIN = ["#c8f090", "#92c864", "#5a9a40", "#2a5a28", "#0c240c"]
SHELL = ["#c8a060", "#9a7a44", "#6a5028", "#3a2a14", "#140c04"]
ROBE = ["#8a7a52", "#6a5836", "#4a3a20", "#2a1e0c", "#100a04"]
STRAW = ["#fff0b0", "#f2d686", "#c89c48", "#8a6a28", "#3a280c"]
WHITE = ["#ffffff", "#f0f2f8", "#c4ccdc", "#8a94ac", "#2a3048"]


def oldshell():
    s = Sprite()
    s.part(E(24, 40, 23, 16), SHELL)                                                         # the shell behind
    for cx, cy in ((9, 38), (38, 38), (17, 45), (31, 45), (24, 36)):                         # hexagon plates
        pts = [(cx - 4, cy), (cx - 2, cy - 3), (cx + 2, cy - 3), (cx + 4, cy), (cx + 2, cy + 3), (cx - 2, cy + 3), (cx - 4, cy)]
        for a, b in zip(pts, pts[1:]):
            s.line(a, b, "#3a2a14")
    s.part(R(10, 37, 37, 47) | E(24, 47, 15, 8), ROBE)
    s.line((12, 42), (36, 42), "#58b048")                                                     # sash
    s.line((12, 43), (36, 43), "#2a7a28")
    s.part(E(24, 25, 12, 13), SKIN)                                                          # head
    s.line((17, 37), (31, 37), "#2a5a28")
    s.part(P((24, 2), (44, 14), (47, 18), (1, 18), (4, 14)), STRAW)                           # straw hat
    for x in (10, 17, 24, 31, 38):
        s.line((24, 3), (24 + (x - 24) * 1.3, 17), "#b8903c")
    pal = {"o": INK, "E": "#ffc23a"}
    s.mstamp(16, 24, ["ooooo.", ".oEEoo"], pal)                                              # sleepy, wise eyes
    s.mstamp(15, 21, ["ooooooo"], {"o": "#f0f2f8"})                                          # white brows
    s.line((20, 32), (28, 32), "#1c3a14")
    both(s, P((24, 30), (14, 31), (8, 38), (18, 34)), WHITE)                                  # long mustache
    s.part(P((17, 32), (31, 32), (28, 43), (24, 47), (20, 43)), WHITE)                        # beard
    return s.done()


# ------------------------------------------------------------------ LILYHOP: a ronin frog with a lily-pad hat
FROG = ["#c0f890", "#8ae060", "#4aa840", "#206a30", "#0a2a10"]
PAD = ["#a8f070", "#62cc4c", "#3a9a38", "#1a6a28", "#082a10"]
TEAL = ["#5aaab0", "#3a8a8a", "#22606e", "#0e3a4a", "#041820"]
BELLY = ["#fcffd0", "#ecf6b0", "#bcd880", "#8aa850", "#2a3a10"]


def lilyhop():
    s = Sprite()
    s.part(P((38, 27), (41, 26), (46, 44), (43, 45)), ["#fff", "#dce4f0", "#a8b4c8", "#6a7488", INK])  # sword behind the shoulder
    s.part(R(36, 24, 43, 27), GOLD)
    s.part(R(5, 38, 42, 47) | E(24, 47, 20, 8), TEAL)
    s.line((8, 41), (40, 41), "#ff9ab8")
    s.line((8, 42), (40, 42), "#d0608a")
    s.part(E(24, 38, 9, 7), BELLY)                                                           # throat pouch
    s.part(E(24, 28, 19, 10), FROG)                                                          # wide head
    for cx in (13, 35):                                                                      # bulging eyes
        s.part(E(cx, 17, 7, 7), FROG)
        s.part(E(cx, 17, 4, 4), GOLD)
        s.stamp(cx - 3, 17, ["oooooo"], {"o": INK})                                           # horizontal pupil
        s.dots([(cx - 3, 15), (cx - 2, 15)], "#fffbe8")
    s.line((9, 29), (16, 33), "#0a2a10"); s.line((16, 33), (32, 33), "#0a2a10"); s.line((32, 33), (39, 29), "#0a2a10")  # wide smile
    s.line((29, 33), (36, 37), "#c8f060"); s.line((36, 37), (42, 34), "#c8f060")             # blade of grass
    s.dots([(15, 28), (16, 28), (32, 28), (33, 28)], "#206a30")                              # nostrils
    s.part(E(24, 9, 18, 5), PAD)                                                             # lily-pad hat
    s.line((24, 9), (10, 7), "#1a6a28"); s.line((24, 9), (38, 7), "#1a6a28")
    s.part(P((24, 5), (21, 1), (23, 6)) | P((24, 5), (27, 1), (25, 6)), ["#ffe6f0", "#ffb0c8", "#e0608a", "#a03a60", INK])
    s.dots([(24, 4), (24, 5)], "#fff6a0")
    return s.done()


# ------------------------------------------------------------------ MASKCAT: a masked cat burglar
CAT = ["#ffffff", "#fffafe", "#e4d4ec", "#b4a0c8", "#3a2a4a"]
MASK = ["#c070f0", "#9a46d8", "#6a22a8", "#3a0a68", "#14022c"]
CAPE = ["#a060d8", "#7a3ab0", "#521a84", "#2a0a50", "#10021c"]


def maskcat():
    s = Sprite()
    tail = E(0, 0, 0.1, 0.1)
    for i in range(16):                                                                      # a curling tail behind the shoulder
        t = i / 15.0
        x, y = 41 + 5 * (t ** 0.5) * (1 - t * 0.2), 46 - 38 * t + 10 * t * t
        tail = tail | E(min(x, 45), y, 3.0, 3.0)
    s.part(tail, CAT)
    s.part(R(3, 38, 44, 47) | E(24, 47, 21, 8), CAPE)
    s.part(P((13, 37), (24, 44), (35, 37), (38, 41), (24, 47), (10, 41)), CAT)                # collar
    s.dots([(24, 44), (23, 44), (25, 44)], "#ff7ab8")
    both(s, P((9, 20), (8, 2), (19, 10)), CAT)                                                # ears
    both(s, P((11, 17), (11, 7), (16, 11)), PINK, outline=False, rim=False)
    s.part(P((9, 24), (13, 14), (24, 11), (35, 14), (39, 24), (41, 30), (33, 36), (24, 38), (15, 36), (7, 30)), CAT)
    s.part(P((8, 18), (24, 16), (40, 18), (39, 26), (31, 25), (24, 23), (17, 25), (9, 26)), MASK)  # half mask
    pal = {"o": INK, "E": "#a8ff3a", "W": "#f4ffc0"}
    s.mstamp(12, 19, ["oooooo", "oEWEEo", ".oEEo."], pal)
    s.stamp(22, 28, ["ooooo", ".ooo."], {"o": "#ff7ab8"})                                     # nose
    s.line((24, 30), (24, 32), "#7a3a68")
    s.line((18, 33), (24, 34), "#7a3a68"); s.line((24, 34), (30, 33), "#7a3a68"); s.line((30, 33), (31, 31), "#7a3a68")  # smirk
    s.dots([(28, 34), (28, 35)], "#ffffff")                                                  # one fang
    for dy in (0, 2):                                                                        # whiskers
        s.line((16, 29 + dy), (2, 27 + dy * 2), "#ffffff")
        s.line((32, 29 + dy), (46, 27 + dy * 2), "#ffffff")
    return s.done()


ANIMALS = {"ironpaw": ironpaw, "moonfang": moonfang, "nightowl": nightowl, "oldshell": oldshell, "lilyhop": lilyhop,
           "maskcat": maskcat}


def main(only=None):
    sheet = Image.new("RGB", (3 * N * UP, 2 * N * UP), (18, 14, 34))
    for i, (cid, fn) in enumerate(ANIMALS.items()):
        if only and cid not in only:
            continue
        im = fn()
        im.save(os.path.join(gc.OUT, cid + ".png"))
        im.crop((60, 0, 420, 360)).resize((128, 128), Image.NEAREST).save(os.path.join(gc.OUT, cid + "_s.png"))
        gc.dark_variant(im, strict=True).save(os.path.join(gc.OUT, cid + "_dark.png"))
        sheet.paste(im, ((i % 3) * N * UP, (i // 3) * N * UP), im)
    sheet.save(os.path.join(os.environ.get("SHEET_DIR", "/tmp"), "animals2_sheet.png"))
    print("animals written to", gc.OUT)


if __name__ == "__main__":
    main(sys.argv[1:] or None)
