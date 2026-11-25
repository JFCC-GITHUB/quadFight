#!/usr/bin/env python3
"""Animal fighters as hand-built 48x48 pixel art (see pixelkit.py).

Writes assets/chars/<id>.png (480 px), <id>_s.png and <id>_dark.png. Run: python3 tools/gen_animals2.py [id ...]
"""
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_assets import ASSETS, Icon  # noqa: E402
from pixelkit import E, N, P, R, S, UP, Sprite, flip  # noqa: E402

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
    head = E(24, 21, 16, 13) | E(10, 24, 5, 6) | E(37, 24, 5, 6)
    s.part(head, FUR)                                                                        # head and cheek ruff
    s.fur(head, "#5a3418", 110, seed=3); s.fur(head, "#e0a868", 60, seed=4, length=2)
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
    wolf_head = P((10, 22), (15, 13), (24, 10), (33, 13), (38, 22), (43, 29), (34, 33), (24, 36), (14, 33), (5, 29))
    s.part(wolf_head, FUR_W)                                                                 # head
    s.fur(wolf_head, "#4a5670", 90, seed=5); s.fur(wolf_head, "#ffffff", 40, seed=6, length=2)
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
TURTLE = ["#c8f090", "#92c864", "#5a9a40", "#2a5a28", "#0c240c"]
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
    s.part(E(24, 25, 12, 13), TURTLE)                                                        # head
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
    s.part(P((40, 28), (43, 27), (47, 47), (44, 47)), ["#fff", "#dce4f0", "#a8b4c8", "#6a7488", INK])  # katana blade behind the shoulder
    s.part(R(39, 16, 44, 27), ["#e86a6a", "#c03a3a", "#8a2028", "#5a1018", "#1a0408"])                 # wrapped hilt
    for y in (18, 21, 24):
        s.line((39, y), (44, y), "#fbd0d0")
    s.part(E(41.5, 28, 5, 2), GOLD)                                                                     # guard
    s.part(R(5, 38, 42, 47) | E(24, 47, 20, 8), TEAL)
    s.line((8, 41), (40, 41), "#ff9ab8")
    s.line((8, 42), (40, 42), "#d0608a")
    s.part(E(24, 38, 9, 7), BELLY)                                                           # throat pouch
    s.part(E(24, 29, 19, 10), FROG)                                                          # wide head
    s.part(E(24, 14, 17, 5), FROG)                                                           # top of the head under the hat
    for cx in (13, 35):                                                                      # bulging eyes
        s.part(E(cx, 19, 7, 7), FROG)
        s.part(E(cx, 19, 4, 4), GOLD)
        s.stamp(cx - 3, 19, ["oooooo"], {"o": INK})                                           # horizontal pupil
        s.dots([(cx - 3, 17), (cx - 2, 17)], "#fffbe8")
    s.line((9, 29), (16, 33), "#0a2a10"); s.line((16, 33), (32, 33), "#0a2a10"); s.line((32, 33), (39, 29), "#0a2a10")  # wide smile
    s.line((29, 33), (36, 37), "#c8f060"); s.line((36, 37), (42, 34), "#c8f060")             # blade of grass
    s.dots([(15, 28), (16, 28), (32, 28), (33, 28)], "#206a30")                              # nostrils
    s.part(E(24, 6.5, 18, 4.5), PAD)                                                             # lily-pad hat
    s.line((24, 6.5), (10, 5), "#1a6a28"); s.line((24, 6.5), (38, 5), "#1a6a28")
    s.part(P((24, 3), (21, 0), (23, 4)) | P((24, 3), (27, 0), (25, 4)), ["#ffe6f0", "#ffb0c8", "#e0608a", "#a03a60", INK])
    s.dots([(24, 2), (24, 3)], "#fff6a0")
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
    patch = P((9, 20), (15, 16), (23, 19), (23, 25), (16, 26), (11, 25))
    s.part(patch | flip(patch) | R(21, 19, 27, 21), MASK)                                    # mask: two eye patches and a bridge
    pal = {"o": INK, "E": "#a8ff3a", "W": "#f4ffc0"}
    s.mstamp(12, 20, ["oooooo", "oEWEEo", ".oEEo."], pal)
    s.stamp(22, 28, ["ooooo", ".ooo."], {"o": "#ff7ab8"})                                     # nose
    s.line((24, 30), (24, 32), "#7a3a68")
    s.line((18, 33), (24, 34), "#7a3a68"); s.line((24, 34), (30, 33), "#7a3a68"); s.line((30, 33), (31, 31), "#7a3a68")  # smirk
    s.dots([(28, 34), (28, 35)], "#ffffff")                                                  # one fang
    for dy in (0, 2):                                                                        # whiskers
        s.line((16, 29 + dy), (2, 27 + dy * 2), "#ffffff")
        s.line((32, 29 + dy), (46, 27 + dy * 2), "#ffffff")
    return s.done()


# ------------------------------------------------------------------ the first six fighters
STEEL = ["#f0f6ff", "#b4c8ee", "#6a88c8", "#2e468c", "#0a1030"]
DEEP = ["#44506c", "#303a54", "#202840", "#121830", "#060a18"]
GEM = ["#ffffff", "#c8f4ff", "#58d0ff", "#2090d0", "#0a3a6a"]
VISOR = ["#34406a", "#202a4a", "#121830", "#080c20", "#02040c"]
BLADE_EYE = [".ooooo.", "oEWEEEo", "..oEEo."]


def bastion():
    s = Sprite()
    s.part(R(3, 37, 44, 47) | E(24, 47, 21, 9), DEEP)
    both(s, P((17, 17), (2, 4), (9, 16), (0, 14), (10, 23), (4, 27), (18, 26)), STEEL)              # swept blades behind the helm
    both(s, P((0, 47), (0, 37), (5, 31), (14, 34), (17, 40), (16, 47)) | E(8, 40, 7, 6), STEEL)    # pauldrons
    s.part(P((16, 37), (32, 37), (30, 45), (24, 47), (18, 45)), STEEL)                            # chest plate
    s.part(P((24, 39), (27, 42), (24, 46), (21, 42)), GEM)
    s.part(E(24, 17, 12, 12) | R(12, 17, 35, 30) | P((12, 30), (35, 30), (30, 36), (17, 36)), STEEL)  # helm
    s.part(P((22, 11), (24, 0), (26, 11), (24, 17)), ["#fff2a8", "#ffd24a", "#d08a20", "#8a4a10", "#3a1a04"])  # crest
    s.part(P((12, 16), (24, 21), (36, 16), (35, 25), (24, 30), (13, 25)), VISOR)                   # V visor
    s.mstamp(13, 17, BLADE_EYE, {"o": INK, "E": "#38d0ff", "W": "#e0fcff"})
    s.line((24, 4), (24, 15), "#ffe49a", native=True)
    s.dots([(15, 31), (17, 33), (31, 31), (29, 33)], "#2e468c")                                    # cheek vents
    s.mstamp(12, 23, ["o..", ".o."], {"o": "#2e468c"})
    return s.done()


ICE = ["#f4ffff", "#a8e0ff", "#58a8f0", "#2a58b8", "#081850"]
ICE_DARK = ["#243a6a", "#162450", "#0c1638", "#060c24", "#02040e"]
WOOD = ["#c8a068", "#a07a44", "#6a4a24", "#3a2410", "#140a04"]


def frost():
    s = Sprite()
    s.part(R(40, 7, 42, 46), WOOD)                                                                  # staff behind
    s.part(E(41, 5, 3.4, 3.4), GEM)
    s.part(R(3, 37, 44, 47) | E(24, 47, 21, 9), ["#5a8ad0", "#3a62b0", "#244088", "#122660", "#060c28"])
    for xs, ys in (((2, 4, 10), (44, 24, 38)), ((8, 6, 14), (38, 28, 36))):
        both(s, P((xs[0], ys[0] + 10), (xs[1], ys[1]), (xs[2], ys[2])), ICE)                         # shoulder ice spikes
    s.part(P((24, 1), (33, 9), (39, 22), (42, 38), (34, 44), (14, 44), (6, 38), (9, 22), (15, 9)), ICE)  # hood
    s.part(P((24, 12), (32, 20), (33, 32), (24, 40), (15, 32), (16, 20)), ICE_DARK)                  # dark face
    s.mstamp(16, 24, BLADE_EYE, {"o": INK, "E": "#58d0ff", "W": "#f0ffff"})
    fur = E(0, 0, 0.1, 0.1)
    for i in range(7):
        fur = fur | E(10 + i * 4.7, 42, 3.2, 3.2)
    s.part(fur | R(9, 41, 39, 46), WHITE_FUR := ["#ffffff", "#f0f6ff", "#c0d8f0", "#8aa8d0", "#2a3a68"])   # fur collar
    for cx, h in ((24, 9), (17, 6), (31, 6)):                                                       # crown crystals
        s.part(P((cx, 2 - h // 3), (cx + 3, 8), (cx - 3, 8)), ICE)
    s.part(P((24, 44), (27, 47), (21, 47)), GEM)
    return s.done()


FLAME = ["#fffbd0", "#ffd24a", "#ff7a2a", "#c8281a", "#4a0a08"]
SKIN = ["#ffd8b0", "#f3b48a", "#c47a52", "#8a4a30", "#2a1008"]
CRIM = ["#c8484a", "#8a2030", "#5a1020", "#34080e", "#140204"]
HOOD = ["#5a4a62", "#3a2e44", "#241a2e", "#120c1a", "#06040a"]


def blaze():
    s = Sprite()
    s.part(P((30, 38), (47, 28), (42, 36), (47, 41), (40, 43), (45, 49), (33, 45)), FLAME)            # scarf tail
    s.part(R(5, 38, 42, 47) | E(24, 47, 20, 9), HOOD)
    s.line((10, 45), (17, 39), "#ff7a2a"); s.line((17, 39), (24, 44), "#ff7a2a"); s.line((24, 44), (31, 39), "#ff7a2a"); s.line((31, 39), (38, 45), "#ff7a2a")
    s.part(P((12, 17), (5, 6), (14, 11), (11, 0), (20, 8), (24, 0), (28, 8), (37, 0), (34, 11), (43, 6), (36, 17)), FLAME)  # flame hair
    s.part(P((16, 15), (14, 7), (21, 12), (24, 5), (27, 12), (34, 7), (32, 15)), ["#fffbe0", "#ffeb90", "#ffb030", "#e06818", "#6a1a08"], outline=False)
    s.part(E(24, 22, 12, 13), HOOD)                                                                 # hood
    s.part(R(12, 16, 35, 25), SKIN)                                                                 # eye band
    s.part(P((12, 26), (35, 26), (32, 33), (24, 38), (16, 33)), CRIM)                               # face mask
    s.part(R(11, 11, 36, 15), ["#e86850", "#c8404a", "#8a2030", "#5a1020", "#1a0408"])               # headband
    s.part(R(21, 10, 26, 16), STEEL_PLATE := ["#ffffff", "#e0e8f4", "#9aa8c4", "#5a6a88", "#1a2030"])
    s.dots([(23, 12), (24, 12), (24, 13)], "#ff5a1a")
    s.mstamp(13, 18, ["..oooooo", ".oEEEEEo", "oEWWEEEo", ".ooEEEo."], {"o": INK, "E": "#ff3a10", "W": "#fff6c0"})
    s.mstamp(13, 16, ["ooo....", ".ooooo."], {"o": "#3a1008"})                                         # fierce brows
    return s.done()


JACKET = ["#b080f0", "#8a52d8", "#5a2a9c", "#341664", "#12062c"]
YEL = ["#fffbd0", "#ffe65a", "#e0a000", "#9a6a00", "#3a2200"]
RED = ["#ff9a8a", "#ff6a6a", "#c82a3a", "#8a1428", "#34040c"]
HAIR = ["#fffbd0", "#ffe27a", "#f0a800", "#a86a00", "#3a2200"]


def volt():
    s = Sprite()
    s.line((3, 24), (7, 18), "#ffe65a"); s.line((7, 18), (4, 12), "#ffe65a"); s.line((4, 12), (9, 6), "#ffe65a")
    s.line((45, 26), (41, 20), "#ffe65a"); s.line((41, 20), (45, 14), "#ffe65a")
    s.part(R(6, 38, 41, 47) | E(24, 47, 19, 9), JACKET)
    s.part(P((14, 37), (24, 43), (34, 37), (37, 41), (24, 47), (11, 41)), YEL)                       # collar
    s.part(P((26, 40), (21, 45), (25, 45), (22, 49), (29, 43), (25, 43)), ["#fffbd0", "#ffe65a", "#e0a000", "#9a6a00", "#3a2200"], outline=False)
    s.part(E(5, 41, 5, 5), RED); s.part(R(1, 44, 9, 47), YEL)                                         # low glove
    s.part(E(43, 28, 5, 5), RED); s.part(R(39, 31, 47, 34), YEL)                                      # raised glove
    s.part(P((12, 22), (5, 12), (12, 14), (9, 3), (18, 10), (20, 0), (26, 8), (33, 1), (33, 10), (43, 4), (36, 15), (43, 22)), HAIR)  # spiky hair
    s.part(R(21, 31, 26, 38), SKIN)
    s.part(E(24, 24, 11, 12), SKIN)
    s.part(R(11, 12, 36, 17), ["#7a6ad8", "#4a3aa0", "#2a1a68", "#14083a", "#06021a"])                 # goggles pushed up
    for cx in (17, 31):
        s.part(E(cx, 14.5, 4.5, 2.6), GEM)
    s.mstamp(14, 21, ["oooooo.", "oEWEEEo", ".ooEEo."], {"o": INK, "E": "#38b0ff", "W": "#e0fcff"})  # eyes
    s.mstamp(14, 19, ["...ooo", "oooo.."], {"o": "#7a4a14"})                                         # brows
    s.line((24, 26), (24, 29), "#a8643a", native=True)
    s.line((18, 31), (30, 31), "#7a2a1a"); s.line((18, 31), (17, 29), "#7a2a1a"); s.line((30, 31), (31, 29), "#7a2a1a")
    s.dots([(20, 32), (22, 32), (24, 32), (26, 32), (28, 32)], "#ffffff")                            # grin
    return s.done()


VIOLET = ["#9a78d0", "#6a4aa0", "#40286a", "#221440", "#0a0618"]
BLACK = ["#1c1030", "#120a22", "#0a0614", "#05030a", "#010004"]
SILVER = ["#ffffff", "#e0d8f8", "#a89cd0", "#6a5c98", "#1a1030"]


def shade():
    s = Sprite()
    for sx in (1, -1):
        xs = lambda v: 24 + sx * (v - 24)
        s.part(P((xs(1), 2), (xs(6), 5), (xs(33), 40), (xs(29), 43)), SILVER)                        # crossed blades
    s.part(P((3, 47), (6, 40), (12, 36), (36, 36), (42, 40), (45, 47)), VIOLET)
    s.line((12, 42), (24, 47), "#d070ff"); s.line((24, 47), (36, 42), "#d070ff")
    s.part(P((24, 0), (33, 8), (39, 21), (42, 39), (33, 45), (15, 45), (6, 39), (9, 21), (15, 8)), VIOLET)  # hood
    s.part(P((24, 12), (32, 20), (33, 32), (24, 40), (15, 32), (16, 20)), BLACK)
    s.part(P((15, 26), (33, 26), (30, 37), (24, 42), (18, 37)), ["#322a50", "#221a3a", "#140e26", "#0a0616", "#020106"])
    s.mstamp(16, 21, BLADE_EYE, {"o": INK, "E": "#ff2ad0", "W": "#ffe0f8"})
    s.part(P((24, 3), (26, 8), (24, 13), (22, 8)), ["#ffe8ff", "#e090ff", "#a040d8", "#5a1a98", "#1a0638"])
    return s.done()


STONE = ["#e0d4b0", "#b8a888", "#7a6c50", "#463c2c", "#16100a"]
MOSS = ["#d0f090", "#90c850", "#5a9a30", "#2a5a18", "#0c240a"]
CRYS = ["#f0ffc0", "#c0f060", "#78c020", "#3a8a10", "#0c2a04"]


def titan():
    s = Sprite()
    both(s, P((1, 47), (0, 36), (6, 31), (14, 34), (17, 40), (16, 47)) | E(8, 40, 8, 7), STONE)   # boulder shoulders
    both(s, P((4, 33), (4, 23), (9, 31)) | P((12, 33), (14, 25), (16, 34)), CRYS)
    s.part(R(14, 37, 33, 47), ["#c8bc98", "#9a8c6c", "#665a40", "#3a3020", "#100c06"])              # chest block
    s.part(P((24, 39), (28, 43), (24, 47), (20, 43)), CRYS)
    s.part(P((10, 19), (13, 10), (35, 10), (38, 19), (37, 31), (31, 36), (17, 36), (11, 31)), STONE)  # head
    s.part(P((15, 9), (18, 3), (30, 3), (33, 9), (29, 13), (19, 13)), MOSS)                           # mossy crown
    for x in (18, 24, 30):
        s.part(P((x - 2, 4), (x, 0), (x + 2, 4)), CRYS)
    s.part(R(10, 21, 37, 24), ["#7a6c50", "#5a4e38", "#3a3020", "#241c10", "#0a0804"])              # heavy brow
    s.mstamp(13, 23, [".ooooo.", "oEWEEEo", "..oEEo."], {"o": INK, "E": "#a8ff3a", "W": "#f4ffc0"})
    s.part(P((13, 29), (34, 29), (31, 36), (17, 36)), ["#9a8c6c", "#7a6c50", "#4a3e2c", "#2a2014", "#0a0804"])  # jaw
    s.line((17, 31), (30, 31), "#0a0804")
    both(s, P((17, 32), (16, 27), (19, 31)), ["#fff", "#f0f0f0", "#c8c8c8", "#8a8a8a", "#2a2a2a"])      # tusks
    s.line((24, 11), (22, 16), "#8aff2a", native=True); s.line((22, 16), (25, 21), "#8aff2a", native=True)
    s.line((33, 26), (30, 29), "#8aff2a", native=True)
    return s.done()


HEROES = {"bastion": bastion, "blaze": blaze, "frost": frost, "volt": volt, "shade": shade, "titan": titan}


ANIMALS = {"ironpaw": ironpaw, "moonfang": moonfang, "nightowl": nightowl, "oldshell": oldshell, "lilyhop": lilyhop,
           "maskcat": maskcat}
FIGHTERS = {**HEROES, **ANIMALS}


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


def dark_variant(im):
    """The 'dark self': luminance mapped onto black / purple / crimson, glowing parts (eyes, gems) turned red."""
    import numpy as np
    a = np.array(im).astype(np.float32)
    rgb_, alpha = a[..., :3] / 255.0, a[..., 3]
    mx, mn = rgb_.max(axis=2), rgb_.min(axis=2)
    lum = rgb_[..., 0] * 0.3 + rgb_[..., 1] * 0.59 + rgb_[..., 2] * 0.11
    sat = (mx - mn) / np.maximum(mx, 1e-4)
    glow = (sat > 0.55) & (lum > 0.5)                    # only saturated light: eyes, gems, flames
    lo, mid, hi = np.array([8, 4, 16.0]), np.array([64, 18, 84.0]), np.array([170, 30, 70.0])
    t = np.clip(lum, 0, 1)[..., None]
    base = np.where(t < 0.5, lo + (mid - lo) * (t / 0.5), mid + (hi - mid) * ((t - 0.5) / 0.5))
    red = np.stack([np.full_like(lum, 255), 40 + 140 * np.clip(lum - 0.5, 0, 1), np.full_like(lum, 56)], axis=2)
    out = np.where(glow[..., None], red, base)
    return Image.fromarray(np.dstack([out, alpha]).astype(np.uint8), "RGBA")


def main(only=None):
    out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "chars")
    os.makedirs(out, exist_ok=True)
    sheet = Image.new("RGB", (4 * N * UP // 2, 3 * N * UP // 2), (18, 14, 34))
    for i, (cid, fn) in enumerate(FIGHTERS.items()):
        if only and cid not in only:
            continue
        im = fn()
        im.save(os.path.join(out, cid + ".png"))
        im.crop((16 * UP, 0, 80 * UP, 64 * UP)).resize((128, 128), Image.NEAREST).save(os.path.join(out, cid + "_s.png"))
        dark_variant(im).save(os.path.join(out, cid + "_dark.png"))
        half = im.resize((N * UP // 2, N * UP // 2), Image.NEAREST)
        sheet.paste(half, ((i % 4) * N * UP // 2, (i // 4) * N * UP // 2), half)
    sheet.save(os.path.join(os.environ.get("SHEET_DIR", "/tmp"), "fighters_sheet.png"))
    skill_icons()
    print("fighters written to", out)


if __name__ == "__main__":
    main(sys.argv[1:] or None)
