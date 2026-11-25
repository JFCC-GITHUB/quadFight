#!/usr/bin/env python3
"""The 12 fighters as 64x64 pixel-art busts in 3/4 view (facing right), built with pix3.py: curved parts with
contour-following shading, hue-shifted ramps, selective outlines, jagged fur bands and typed face stamps.

Writes assets/chars/<id>.png (512 px, 8x nearest) and <id>_dark.png, plus the skill icons.
Run: python3 tools/gen_fighters.py [id ...]   (contact sheet -> $SHEET_DIR/fighters_sheet.png)
"""
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_assets import Icon  # noqa: E402
from pix3 import Cv  # noqa: E402

UP = 8
# ramps are [highlight, light, mid, dark, deep]: highlights lean warm, shadows lean purple
GOLD = ["#fff8c0", "#ffd450", "#e09a28", "#a0602a", "#4a2418"]
STEEL = ["#f4fbff", "#b4c8ee", "#6a88c8", "#2e468c", "#120c3a"]
IRON = ["#f4fbff", "#b6c8dc", "#7486a8", "#454c74", "#1c1834"]
GEM = ["#ffffff", "#c8f4ff", "#58d0ff", "#2090d0", "#0a2a6a"]
RED = ["#ffb08a", "#ee5a48", "#b42c3a", "#6e1834", "#2c0a1e"]
LEATHER = ["#c89a60", "#946238", "#623c28", "#3e2222", "#1a0c14"]
SKIN = ["#ffe0c0", "#f6b890", "#d0805e", "#8e4a48", "#341428"]
WHITE = ["#ffffff", "#f0f4fc", "#c4cce4", "#8a90b8", "#2e2a4c"]
PINK = ["#ffd6c8", "#f2a0a0", "#c46a74", "#7c3448", "#2e1422"]


def torso(c, ramp, fur=False):
    c.part(c.poly((10, 44), (46, 40), (56, 48), (60, 64), (2, 64), (4, 52)), ramp, fur=fur)


def bolt(c, pts, color):
    for a, b in zip(pts, pts[1:]):
        c.line(a, b, color)


def claws(c, roots, light="#eef6ff", dark="#7486a8"):
    for (x0, y0), (x1, y1) in roots:
        c.line((x0, y0), (x1, y1), light)
        c.line((x0 + 1, y0 + 1), (x1 + 1, y1 + 1), dark)
        c.dots([(x1, y1)], "#ffffff")


# ------------------------------------------------------------------ BASTION: a knight in blue plate, sword on his back
DEEP = ["#6a74a0", "#454c78", "#2c3054", "#1a1a38", "#0a081c"]
VISOR = ["#34406a", "#202a4a", "#121830", "#080c20", "#02040c"]


def bastion():
    c = Cv(64, 64)
    c.part(c.rect(53, 1, 57, 42), STEEL); c.line((54, 2), (54, 40), "#ffffff")                      # sword behind
    c.part(c.rect(49, 40, 61, 43), GOLD); c.part(c.rect(53, 44, 57, 52), LEATHER)
    c.part(c.poly((24, 7), (14, 2), (3, 6), (10, 9), (1, 14), (12, 13), (6, 20), (21, 12)), RED, fur=True)  # plume
    torso(c, DEEP)
    c.part(c.poly((18, 46), (44, 43), (50, 54), (50, 64), (14, 64), (14, 54)), STEEL)              # breastplate
    c.part(c.poly((32, 49), (36, 54), (32, 60), (28, 54)), GEM)
    c.part(c.ell(11, 46, 11, 8) | c.poly((2, 41), (0, 32), (9, 39)) | c.poly((10, 39), (12, 30), (17, 39)), STEEL)
    c.part(c.ell(51, 48, 10, 7), STEEL)
    c.part(c.ell(29, 23, 15, 16) | c.poly((15, 28), (45, 23), (47, 33), (37, 42), (19, 40)), STEEL)  # helm
    c.part(c.poly((19, 11), (28, 1), (37, 5), (31, 9), (24, 12)), GOLD)                             # crest fin
    c.part(c.poly((17, 18), (46, 15), (46, 23), (19, 26)), VISOR, hi=False)                          # visor slit
    c.stamp(22, 19, [".EEEEE", "EEWWEE", ".EEEE."], {"E": "#38d0ff", "W": "#e8feff"})
    c.stamp(38, 18, ["EEEE", "EWWE", ".EE."], {"E": "#38d0ff", "W": "#e8feff"})
    for x in (34, 37, 40, 43):                                                                     # breathing vents
        c.line((x, 30), (x - 1, 34), "#2e468c")
    c.dots([(20, 47), (44, 46), (18, 58), (46, 58)], "#ffd450")
    return c


# ------------------------------------------------------------------ BLAZE: a fire ninja holding a fireball
FLAME = ["#fffbd0", "#ffd24a", "#ff7a2a", "#c8281a", "#4a0a14"]
CORE = ["#ffffff", "#fffbd0", "#ffe680", "#ffb030", "#ff7a2a"]
CRIM = ["#e8645a", "#b8303e", "#7a1830", "#480c22", "#1a0410"]
HOOD = ["#6a5a7a", "#463a58", "#2c2440", "#18122a", "#080414"]


def blaze():
    c = Cv(64, 64)
    c.part(c.poly((16, 40), (3, 35), (7, 41), (0, 47), (10, 45), (6, 52), (18, 46)), CRIM, fur=True)  # scarf tail
    c.part(c.poly((34, 8), (24, 0), (24, 6), (12, 0), (15, 8), (1, 6), (9, 14), (0, 19), (11, 21), (5, 29),
                  (18, 24)), FLAME, fur=True)                                                          # flame hair
    torso(c, HOOD)
    bolt(c, [(8, 56), (16, 50), (24, 56), (32, 50), (40, 56), (48, 50)], "#ff7a2a")
    c.part(c.ell(31, 26, 13, 14), SKIN)
    c.part(c.ell(29, 15, 14, 7) | c.poly((20, 12), (24, 4), (30, 10), (36, 3), (40, 12)), FLAME, fur=True)
    c.part(c.poly((18, 15), (44, 14), (44, 18), (18, 19)), CRIM)                                     # headband
    c.part(c.poly((19, 15), (8, 11), (4, 15), (10, 17), (5, 22), (18, 19)), CRIM, fur=True)
    c.part(c.rect(34, 13, 39, 19), IRON)
    c.dots([(36, 15), (37, 15), (37, 16)], "#ff5a1a")
    c.part(c.poly((18, 28), (44, 26), (45, 32), (37, 40), (24, 40), (18, 34)), CRIM)                 # face mask
    c.stamp(22, 20, ["oooooo.", "oEWWEEo", ".oEEEo."], {"o": "#3a0a14", "E": "#ff3a10", "W": "#fff6c0"})
    c.stamp(37, 20, ["ooooo", "oWEEo", ".oEo."], {"o": "#3a0a14", "E": "#ff3a10", "W": "#fff6c0"})
    c.line((21, 18), (28, 20), "#3a0a14"); c.line((37, 19), (42, 18), "#3a0a14")
    c.part(c.poly((44, 64), (47, 52), (58, 50), (62, 64)), HOOD)                                     # sleeve
    c.part(c.ell(53, 51, 6, 5), SKIN)                                                              # fist
    c.part(c.ell(53, 38, 8, 8) | c.poly((47, 34), (50, 24), (53, 31), (57, 23), (59, 34)), FLAME, fur=True)  # fireball
    c.part(c.ell(53, 39, 4, 4), CORE, outline=False)
    return c


# ------------------------------------------------------------------ FROST: an ice mage with a crystal staff
ICE = ["#f4ffff", "#a8e0ff", "#58a8f0", "#2a58b8", "#10104a"]
ICE_DARK = ["#243a6a", "#162450", "#0c1638", "#060c24", "#02040e"]
ROBE_B = ["#7aa8e8", "#4a78c8", "#2c4c98", "#1a2a68", "#0a0c30"]
WOOD = ["#d8b078", "#a87c48", "#704c2c", "#442a22", "#1a0c10"]


def frost():
    c = Cv(64, 64)
    c.part(c.rect(54, 8, 57, 64), WOOD)                                                             # staff
    c.part(c.ell(55, 7, 5, 5), GEM)
    for x0, y0, x1, y1 in ((51, 6, 48, 0), (59, 6, 62, 0), (55, 2, 55, -2)):
        c.part(c.poly((x0 - 1, y0), (x1, y1), (x0 + 1, y0)), ICE)
    torso(c, ROBE_B)
    c.part(c.poly((2, 46), (4, 30), (11, 43)) | c.poly((9, 44), (13, 33), (16, 43)), ICE)            # shoulder ice
    c.part(c.poly((22, 1), (34, 6), (44, 16), (48, 32), (43, 44), (12, 44), (6, 34), (8, 18), (14, 8)), ICE)  # hood
    for cx in (20, 26, 32):
        c.part(c.poly((cx - 2, 7), (cx, 0 + abs(cx - 26) // 2), (cx + 2, 7)), ICE)
    c.part(c.poly((29, 13), (42, 17), (45, 31), (37, 40), (26, 38), (22, 25)), ICE_DARK, hi=False)   # face in shadow
    c.stamp(25, 24, [".EEEE", "EEWWE", ".EEE."], {"E": "#58d0ff", "W": "#f0ffff"})
    c.stamp(37, 23, ["EEE", "EWE", ".E."], {"E": "#58d0ff", "W": "#f0ffff"})
    fur = c.rect(8, 41, 48, 46)
    for i in range(9):
        fur |= c.ell(9 + i * 4.8, 43, 3.2, 3.2)
    c.part(fur, WHITE, fur=True)                                                                   # fur collar
    c.part(c.poly((28, 47), (31, 51), (28, 55), (25, 51)), GEM)
    c.part(c.ell(55, 46, 4.5, 4), WHITE)                                                           # gloved hand
    return c


# ------------------------------------------------------------------ VOLT: a spiky-haired boxer, goggles pushed up
JACKET = ["#c090f8", "#9058e0", "#5e2ca4", "#36166c", "#14062e"]
YEL = ["#fffbd0", "#ffe65a", "#e0a000", "#9a5a10", "#3a1a14"]
GLOVE = ["#ffb0a0", "#ff6a6a", "#c82a3a", "#801438", "#30041a"]
HAIR = ["#fffbd0", "#ffe27a", "#f0a800", "#a8601a", "#3a1a14"]
LENS = ["#4a3aa0", "#2a1a68", "#1a1048", "#0e0830", "#06021a"]


def volt():
    c = Cv(64, 64)
    bolt(c, [(4, 34), (9, 28), (5, 23), (10, 16)], "#ffe65a")
    bolt(c, [(60, 22), (56, 16), (61, 11), (57, 4)], "#ffe65a")
    torso(c, JACKET)
    c.part(c.poly((16, 42), (30, 48), (44, 41), (48, 46), (30, 54), (12, 47)), YEL)                 # collar
    c.part(c.poly((40, 13), (36, 2), (31, 8), (26, 0), (22, 8), (11, 2), (15, 10), (1, 9), (11, 16), (3, 23),
                  (17, 22)), HAIR, fur=True)                                                           # hair
    c.part(c.rect(26, 36, 32, 42), SKIN)                                                            # neck
    c.part(c.ell(30, 26, 12, 13) | c.poly((38, 30), (45, 27), (43, 36), (36, 38)), SKIN)
    c.part(c.ell(19, 27, 3, 4), SKIN)                                                              # ear
    c.part(c.ell(28, 13, 12, 5) | c.poly((17, 14), (14, 7), (22, 10), (24, 4), (30, 9), (36, 3), (38, 10)), HAIR, fur=True)
    c.part(c.poly((18, 14), (43, 12), (43, 17), (18, 19)), LENS)                                     # goggle strap
    c.part(c.ell(28, 15, 4, 3), GEM); c.part(c.ell(38, 14.5, 3, 2.6), GEM)
    c.stamp(23, 21, ["oooooo", "oEWEEo", ".oEEo."], {"o": "#341428", "E": "#38b0ff", "W": "#e0fcff"})
    c.stamp(36, 21, ["oooo", "oWEo", ".oo."], {"o": "#341428", "E": "#38b0ff", "W": "#e0fcff"})
    c.line((22, 19), (28, 19), "#a8601a"); c.line((36, 19), (40, 18), "#a8601a")
    c.line((41, 25), (42, 28), "#8e4a48")                                                          # nose
    c.line((29, 32), (40, 31), "#5a1a2a"); c.line((29, 32), (28, 30), "#5a1a2a")
    c.dots([(31, 33), (33, 33), (35, 33), (37, 32)], "#ffffff")                                     # grin
    c.part(c.ell(54, 44, 8, 7), GLOVE)                                                             # raised glove
    c.part(c.rect(48, 50, 60, 55), YEL)
    bolt(c, [(52, 41), (55, 44), (53, 46), (57, 49)], "#fffbd0")
    return c


# ------------------------------------------------------------------ SHADE: a hooded shadow with a dagger
VIOLET = ["#a888e0", "#7454b0", "#482c7a", "#281648", "#0c0620"]
BLACK = ["#2a1c44", "#1a1030", "#0e081e", "#06030e", "#020006"]
SILVER = ["#ffffff", "#e0d8f8", "#a89cd0", "#6a5c98", "#1a1030"]
AMETH = ["#ffe8ff", "#e090ff", "#a040d8", "#5a1a98", "#1a0638"]


def shade():
    c = Cv(64, 64)
    c.part(c.poly((50, 34), (59, 8), (61, 10), (55, 36)), SILVER)                                   # dagger blade
    torso(c, VIOLET)
    bolt(c, [(14, 52), (30, 60), (46, 50)], "#d070ff")
    c.part(c.poly((24, 2), (36, 6), (46, 18), (48, 36), (42, 44), (14, 44), (8, 37), (1, 31), (8, 28), (1, 21),
                  (10, 19), (14, 8)), VIOLET, fur=True)                                               # tattered hood
    c.part(c.poly((29, 13), (42, 17), (45, 31), (37, 40), (26, 38), (22, 25)), BLACK, hi=False)
    c.part(c.poly((24, 30), (45, 28), (40, 40), (28, 40)), ["#322a50", "#221a3a", "#140e26", "#0a0616", "#020106"], hi=False)
    c.stamp(25, 23, [".EEEE", "EEWWE", ".EEE."], {"E": "#ff2ad0", "W": "#ffe0f8"})
    c.stamp(37, 22, ["EEE", "EWE", ".E."], {"E": "#ff2ad0", "W": "#ffe0f8"})
    c.part(c.poly((22, 2), (25, 8), (22, 13), (19, 8)), AMETH)
    c.part(c.rect(50, 34, 57, 37), GOLD)                                                            # guard
    c.part(c.ell(54, 44, 6, 5.5), BLACK)                                                           # gloved fist
    return c


# ------------------------------------------------------------------ TITAN: a mossy stone golem
STONE = ["#ece0bc", "#c0b090", "#827458", "#4c3e3a", "#1a1020"]
STONE_D = ["#b0a07e", "#857658", "#58483c", "#342630", "#140a18"]
MOSS = ["#d8f8a0", "#94d054", "#5a9a30", "#2a5a2a", "#0c2418"]
CRYS = ["#f4ffc8", "#c0f060", "#78c020", "#3a8a20", "#0c2a14"]


def titan():
    c = Cv(64, 64)
    torso(c, STONE_D)
    c.part(c.poly((32, 50), (37, 56), (32, 63), (27, 56)), CRYS)
    c.part(c.ell(11, 46, 13, 10), STONE)
    c.part(c.poly((2, 40), (3, 28), (8, 38)) | c.poly((9, 38), (12, 30), (15, 38)), CRYS)
    c.part(c.ell(53, 48, 12, 9), STONE)
    c.part(c.poly((15, 14), (19, 6), (43, 6), (49, 14), (49, 32), (41, 41), (21, 41), (15, 32)), STONE)   # head
    c.part(c.poly((17, 9), (21, 2), (41, 2), (46, 9), (39, 12), (23, 12)), MOSS, fur=True)
    for x in (23, 30, 37):
        c.part(c.poly((x - 2, 4), (x, -1), (x + 2, 4)), CRYS)
    c.part(c.rect(16, 17, 49, 20), STONE_D, hi=False)                                              # heavy brow
    c.stamp(24, 21, ["oooooo", "oEWWEo", ".oEEo."], {"o": "#1a1020", "E": "#a8ff3a", "W": "#f4ffc0"})
    c.stamp(40, 21, ["oooo", "oWEo", ".oo."], {"o": "#1a1020", "E": "#a8ff3a", "W": "#f4ffc0"})
    c.part(c.poly((20, 31), (49, 29), (47, 38), (40, 42), (22, 41)), STONE_D)                       # jaw
    c.line((24, 34), (46, 32), "#1a1020")
    c.part(c.poly((26, 34), (25, 28), (29, 33)), WHITE); c.part(c.poly((42, 33), (43, 27), (45, 32)), WHITE)  # tusks
    bolt(c, [(31, 7), (28, 12), (31, 16)], "#8aff2a")
    bolt(c, [(17, 26), (19, 30), (17, 33)], "#8aff2a")
    return c


# ------------------------------------------------------------------ IRONPAW: a scarred brown bear with iron claws
FUR = ["#f8d890", "#d29a52", "#9c5e30", "#623226", "#2e1422"]
FUR_D = ["#c88a50", "#9a5c32", "#6c3a24", "#46221e", "#22101a"]
CREAM = ["#fff6dc", "#f0d6a0", "#cca070", "#8c5e48", "#3a1c22"]
CAPE_R = ["#e47060", "#b23a44", "#7a2240", "#4a1434", "#1e0818"]
INK_B = "#2e1422"
EYE_B = {"o": INK_B, "E": "#ffb02a", "W": "#fff6dc", "b": "#5a2a14"}


def ironpaw():
    c = Cv(64, 64)
    c.part(c.poly((8, 42), (22, 40), (19, 56), (21, 64), (0, 64), (1, 52)), CAPE_R)
    torso(c, FUR_D, fur=True)
    c.part(c.poly((20, 46), (44, 44), (50, 55), (50, 64), (15, 64), (15, 55)), IRON)                # chest plate
    c.line((33, 46), (33, 63), "#454c74")
    c.dots([(22, 50), (43, 49), (20, 59), (45, 59)], "#ffd450")
    c.part(c.ell(12, 38, 12, 9) | c.poly((1, 38), (8, 30), (6, 42), (1, 46)), FUR, fur=True)        # shoulder hump
    c.part(c.ell(52, 48, 10, 7) | c.poly((44, 41), (58, 42), (63, 51), (57, 53), (55, 57), (49, 51)), FUR, fur=True)
    c.part(c.ell(14, 8, 5.5, 5.5), FUR)                                                             # small round ears
    c.part(c.ell(14, 9, 2.5, 2.5), PINK, outline=False, hi=False)
    c.part(c.ell(42, 7, 4.5, 4.5), FUR_D)
    head = c.ell(28, 23, 19, 16) | c.poly((12, 26), (8, 32), (13, 31), (10, 37), (16, 35), (16, 40), (21, 36)) \
        | c.poly((44, 36), (40, 44), (34, 38))
    c.part(head, FUR, fur=True)
    c.part(c.ell(47, 30, 11, 7.5), CREAM)                                                           # long muzzle
    c.stamp(52, 23, ["oooooo", "oWWkko", "okkkko", ".oooo."], {"o": INK_B, "k": "#5a3a48", "W": "#a88a98"})
    c.line((57, 35), (44, 35), INK_B); c.line((44, 35), (42, 33), INK_B)
    c.dots([(47, 36), (48, 36), (52, 36), (53, 36)], "#fff6dc")
    c.stamp(24, 15, ["bbbbbbbb", ".bbbbbb.", ".oooooo.", ".oEWWEo.", ".oEEEEo.", "..oooo.."], EYE_B)
    c.stamp(40, 15, ["bbbbb", "ooooo", "oEWEo", ".ooo."], EYE_B)
    for k in range(3):                                                                            # claw scars
        c.line((16 + k * 3, 9 + k), (17 + k * 3, 21 + k), "#ff7060")
    c.part(c.poly((47, 52), (60, 50), (63, 64), (46, 64)), IRON)                                    # gauntlet
    c.part(c.ell(55, 52, 7, 6), FUR)                                                                # raised fist
    claws(c, [((51, 47), (48, 38)), ((55, 46), (55, 36)), ((59, 47), (62, 39))])
    return c


# ------------------------------------------------------------------ MOONFANG: a silver lone wolf, moon scarf
FUR_W = ["#ffffff", "#d4dcee", "#96a2c0", "#565c80", "#1c1838"]
MUZ_W = ["#ffffff", "#f6f8ff", "#d0d8ec", "#9aa2c4", "#1c1838"]
SCARF = ["#9ab4ff", "#5a7ae0", "#3a4cb0", "#222870", "#0c0a34"]
NAVY = ["#56628a", "#3a4468", "#262c4a", "#161834", "#08061a"]
MOON = ["#ffffff", "#fff8d0", "#f0d880", "#b89a50", "#3a2a20"]


def moonfang():
    c = Cv(64, 64)
    c.part(c.poly((18, 40), (3, 33), (7, 40), (0, 46), (10, 45), (4, 53), (20, 46)), SCARF, fur=True)   # scarf tail
    torso(c, NAVY)
    c.part(c.ell(30, 44, 18, 5.5), SCARF)                                                          # scarf wrap
    c.part(c.ell(36, 45, 3.5, 3.5), MOON)
    c.part(c.ell(37.5, 44, 2.5, 2.5), SCARF, outline=False, hi=False)
    c.part(c.poly((37, 16), (44, 0), (48, 18)), FUR_W)                                              # far ear
    c.part(c.poly((40, 14), (44, 5), (45, 15)), NAVY, outline=False, hi=False)
    c.part(c.poly((14, 18), (18, 0), (30, 11)), FUR_W)                                              # near ear
    c.part(c.poly((18, 14), (19, 5), (26, 11)), NAVY, outline=False, hi=False)
    head = c.ell(28, 24, 15, 13) | c.poly((14, 22), (7, 29), (13, 30), (9, 36), (17, 34), (17, 41), (24, 37))
    c.part(head, FUR_W, fur=True)
    c.part(c.poly((33, 22), (54, 26), (57, 30), (53, 35), (36, 37)), MUZ_W)                          # long snout
    c.stamp(53, 25, ["oooo", "oWko", ".oo."], {"o": "#1c1838", "k": "#3a3858", "W": "#8a8aa8"})
    c.line((55, 34), (40, 36), "#1c1838")
    c.dots([(43, 37), (49, 36)], "#ffffff")
    c.stamp(24, 19, ["oooooo", "oEWEEo", ".oooo."], {"o": "#1c1838", "E": "#46c8ff", "W": "#e8faff"})
    c.stamp(37, 19, ["oooo", "oWEo", ".oo."], {"o": "#1c1838", "E": "#46c8ff", "W": "#e8faff"})
    c.line((23, 17), (30, 18), "#565c80"); c.line((36, 17), (41, 17), "#565c80")
    for x in (20, 23, 26):                                                                         # fur stripes
        c.line((x, 30), (x - 2, 34), "#96a2c0")
    return c


# ------------------------------------------------------------------ NIGHTOWL: a scholar owl in round gold glasses
PLUM = ["#f0dcc0", "#c0a080", "#86684e", "#4e3a3a", "#1e1220"]
WING = ["#8a9ae8", "#5a6ac0", "#36428e", "#1e2258", "#0a0a2a"]
FACE = ["#fffbe8", "#f4e8d0", "#d4bc9c", "#a08878", "#2e1a20"]
BEAK = ["#fff0a0", "#ffc048", "#e08a20", "#a0502a", "#3a1414"]


def nightowl():
    c = Cv(64, 64)
    torso(c, PLUM, fur=True)
    c.part(c.ell(30, 52, 12, 10), FACE, fur=True)                                                  # chest feathers
    for x, y in ((25, 48), (31, 50), (37, 48), (28, 55), (34, 56)):
        c.stamp(x, y, ["o.o", ".o."], {"o": "#a08878"})
    c.part(c.poly((42, 40), (52, 36), (60, 44), (63, 64), (40, 64)), WING, fur=True)                 # folded wing
    for x in (48, 53, 58):
        c.line((x - 4, 44), (x, 63), "#1e2258")
    c.part(c.poly((12, 14), (8, 0), (20, 9)), PLUM, fur=True)                                       # ear tufts
    c.part(c.poly((38, 9), (47, 0), (46, 13)), PLUM, fur=True)
    c.part(c.ell(29, 24, 19, 16), PLUM, fur=True)
    c.part(c.ell(33, 26, 14, 12), FACE)                                                            # facial disc
    c.part(c.ell(27, 23, 6.5, 6.5), GOLD)                                                          # glasses
    c.part(c.ell(41, 23, 5, 5.5), GOLD)
    c.part(c.ell(27, 23, 4.5, 4.5), ["#ffffff", "#fff6e0", "#f0e0c0", "#c8a880", "#2e1a20"], outline=False, hi=False)
    c.part(c.ell(41, 23, 3.2, 3.8), ["#ffffff", "#fff6e0", "#f0e0c0", "#c8a880", "#2e1a20"], outline=False, hi=False)
    c.line((33, 22), (36, 22), "#e09a28")
    c.stamp(25, 21, [".EE.", "EkkE", "EkWE", ".EE."], {"E": "#ffb02a", "k": "#1e1220", "W": "#ffffff"})
    c.stamp(40, 21, ["EE", "kk", "EE"], {"E": "#ffb02a", "k": "#1e1220"})
    c.part(c.poly((33, 29), (39, 29), (36, 36)), BEAK)
    c.line((20, 16), (25, 18), "#4e3a3a"); c.line((40, 17), (44, 16), "#4e3a3a")                   # brows
    return c


# ------------------------------------------------------------------ OLDSHELL: an old turtle monk in a straw hat
TURTLE = ["#d0f4a0", "#96cc6a", "#5c9a46", "#2e5a3a", "#0c2420"]
SHELL = ["#e0b870", "#b08448", "#7a5430", "#46302a", "#1a0c14"]
ROBE = ["#a08c62", "#766444", "#50422e", "#302428", "#120a14"]
STRAW = ["#fff4c0", "#f2d686", "#c89c48", "#8a6230", "#3a2018"]


def oldshell():
    c = Cv(64, 64)
    c.part(c.ell(11, 48, 13, 16), SHELL)                                                           # shell on the back
    for p in ((5, 40), (13, 37), (4, 52), (13, 50), (9, 60)):
        c.stamp(p[0], p[1], [".oo.", "o..o", ".oo."], {"o": "#46302a"})
    torso(c, ROBE)
    c.part(c.poly((22, 42), (32, 52), (40, 42), (44, 46), (32, 58), (18, 46)), ["#e0d4a8", "#b8a87c", "#857454", "#4e3e30", "#1a1014"])
    c.part(c.ell(30, 28, 13, 12) | c.poly((36, 26), (49, 28), (47, 35), (36, 37)), TURTLE)           # head with beak
    c.line((48, 32), (40, 33), "#2e5a3a")
    c.stamp(24, 25, ["oooo", "oEEo"], {"o": "#0c2420", "E": "#2a1a10"})                          # sleepy wise eyes
    c.stamp(38, 25, ["ooo", "oEo"], {"o": "#0c2420", "E": "#2a1a10"})
    c.part(c.poly((21, 20), (30, 20), (28, 22), (19, 23)), WHITE)                                   # bushy brows
    c.part(c.poly((36, 20), (43, 19), (42, 22), (36, 22)), WHITE)
    c.part(c.poly((28, 35), (47, 35), (42, 44), (34, 56), (30, 47), (23, 52), (25, 41)), WHITE, fur=True)  # long beard
    c.part(c.poly((1, 14), (28, 0), (60, 10), (52, 15), (8, 17)), STRAW)                            # straw hat
    for x in (12, 20, 28, 36, 44):
        c.line((x, 15 - abs(x - 28) // 6), (28, 1), "#c89c48")
    c.line((8, 16), (52, 14), "#8a6230")
    return c


# ------------------------------------------------------------------ LILYHOP: a ronin frog with a lily-pad hat
FROG = ["#d0ffa0", "#8ae060", "#4aa840", "#206a3a", "#0a2a1c"]
PAD = ["#b8f878", "#62cc4c", "#3a9a38", "#1a6a2e", "#082a18"]
TEAL = ["#6abac0", "#3a8a92", "#22606e", "#0e3a4a", "#041820"]
BELLY = ["#fcffd8", "#ecf6b0", "#bcd880", "#86a050", "#2a3a18"]


def lilyhop():
    c = Cv(64, 64)
    c.part(c.poly((2, 28), (5, 26), (18, 46), (15, 48)), ["#4a3a5a", "#30243e", "#1e1428", "#100a18", "#04020a"])  # sheath
    c.part(c.rect(3, 22, 7, 29), RED)                                                              # katana hilt
    for y in (23, 25, 27):
        c.line((3, y), (7, y + 1), "#2c0a1e")
    c.part(c.rect(2, 29, 9, 31), GOLD)
    torso(c, TEAL)
    c.part(c.poly((22, 40), (32, 54), (42, 40), (46, 44), (32, 62), (18, 44)), BELLY)                 # V collar
    c.part(c.ell(31, 31, 18, 11), FROG)                                                            # wide head
    c.part(c.ell(24, 19, 7.5, 7.5), FROG)                                                          # bulging eyes
    c.part(c.ell(40, 18, 6, 6.5), FROG)
    c.part(c.ell(25, 20, 5, 5), ["#fffbd0", "#ffe680", "#f0c040", "#a07020", "#2a1a10"], outline=False, hi=False)
    c.part(c.ell(40.5, 19, 3.6, 4), ["#fffbd0", "#ffe680", "#f0c040", "#a07020", "#2a1a10"], outline=False, hi=False)
    c.stamp(22, 20, ["kkkkkk"], {"k": "#0a2a1c"}); c.stamp(38, 19, ["kkkk"], {"k": "#0a2a1c"})      # bar pupils
    c.dots([(23, 18), (39, 17)], "#ffffff")
    c.line((16, 35), (30, 38), "#0a2a1c"); c.line((30, 38), (48, 33), "#0a2a1c")                    # wide grin
    c.dots([(44, 28), (46, 28)], "#0a2a1c")                                                       # nostrils
    c.part(c.ell(19, 34, 2.5, 1.5), PINK, outline=False, hi=False)
    c.part(c.ell(31, 9, 19, 4.5), PAD)                                                             # lily-pad hat
    c.part(c.poly((31, 9), (22, 4), (26, 4)), PAD, outline=False)
    c.line((31, 9), (19, 9), "#1a6a2e"); c.line((31, 9), (44, 7), "#1a6a2e")
    c.part(c.poly((34, 2), (37, -2), (40, 2), (37, 5)), PINK)                                       # little flower
    return c


# ------------------------------------------------------------------ MASKCAT: a masked cat burglar with a stolen gem
CAT = ["#ffffff", "#f8f4fc", "#dcd0ec", "#a898c4", "#3a2a4a"]
MASK = ["#d080f8", "#9a46d8", "#6a22a8", "#3a0a68", "#14022c"]
CAPE = ["#b070e8", "#7a3ab0", "#521a84", "#2a0a50", "#10021c"]


def maskcat():
    c = Cv(64, 64)
    c.part(c.poly((16, 40), (1, 35), (4, 46), (0, 54), (6, 64), (20, 64)), CAPE, fur=True)
    torso(c, CAPE)
    c.part(c.ell(30, 44, 4, 3), GOLD)                                                              # cape clasp
    c.part(c.poly((37, 16), (46, 1), (48, 19)), CAT)                                                # far ear
    c.part(c.poly((40, 14), (45, 6), (46, 15)), PINK, outline=False, hi=False)
    c.part(c.poly((14, 18), (16, 1), (28, 10)), CAT)                                                # near ear
    c.part(c.poly((17, 14), (17, 6), (24, 10)), PINK, outline=False, hi=False)
    c.part(c.ell(30, 25, 15, 13) | c.poly((15, 26), (9, 31), (15, 32), (12, 37), (20, 35), (22, 39)), CAT, fur=True)
    c.part(c.ell(42, 31, 6, 4.5), CAT)                                                             # muzzle
    c.part(c.poly((16, 19), (46, 16), (48, 22), (42, 25), (34, 22), (24, 26), (17, 24)), MASK)        # domino mask
    c.stamp(22, 20, ["oooooo", "oEEkEo", ".oEEo."], {"o": "#14022c", "E": "#a8ff3a", "k": "#14022c"})
    c.stamp(38, 19, ["oooo", "oEko", ".oo."], {"o": "#14022c", "E": "#a8ff3a", "k": "#14022c"})
    c.stamp(44, 27, ["ooo", ".o."], {"o": "#ff7aa8"})                                               # nose
    c.stamp(41, 31, ["o..o..o", ".oo.oo."], {"o": "#3a2a4a"})                                      # w mouth
    c.line((47, 30), (57, 28), "#a898c4"); c.line((47, 32), (57, 33), "#a898c4")                     # whiskers
    c.part(c.ell(54, 52, 6, 5), CAT)                                                               # paw
    c.part(c.poly((50, 42), (54, 37), (58, 42), (54, 48)), GEM)                                     # stolen gem
    return c


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
    cell = 64 * 4
    sheet = Image.new("RGB", (4 * cell, 3 * cell), (18, 14, 34))
    for i, (cid, fn) in enumerate(FIGHTERS.items()):
        if only and cid not in only:
            continue
        im = fn().image(UP)
        im.save(os.path.join(out, cid + ".png"))
        dark_variant(im).save(os.path.join(out, cid + "_dark.png"))
        half = im.resize((cell, cell), Image.NEAREST)
        sheet.paste(half, ((i % 4) * cell, (i // 4) * cell), half)
    sheet.save(os.path.join(os.environ.get("SHEET_DIR", "/tmp"), "fighters_sheet.png"))
    skill_icons()
    print("fighters written to", out)


if __name__ == "__main__":
    main(sys.argv[1:] or None)
