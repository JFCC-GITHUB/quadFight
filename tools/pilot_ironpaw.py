"""Pilot: IRONPAW redrawn with pix3 (3/4 pose, asymmetric). Writes full-body and bust previews to $SHEET_DIR."""
import os
import sys
sys.path.insert(0, os.path.dirname(__file__))
from pix3 import Cv

FUR = ["#f0c080", "#c88c4c", "#92582c", "#5c351a", "#2a1408"]
CREAM = ["#fff4d8", "#f2d8a8", "#d4aa78", "#94704a", "#2a1408"]
IRON = ["#f4f8ff", "#b8c4dc", "#7a88a8", "#465070", "#1a1e30"]
RED = ["#ff9a84", "#e8504a", "#b02c34", "#701a26", "#2a0a12"]
CAPE = ["#d8606a", "#a8323e", "#74202e", "#44121e", "#1a060c"]
LEATHER = ["#b88858", "#8a5c38", "#5c3a22", "#3a2210", "#180c04"]
GOLD = ["#fff4b0", "#ffd24a", "#e0a020", "#a06a10", "#4a2a08"]
PINK = ["#ffd0d0", "#f09aa0", "#c0646c", "#7a3040", "#2a1408"]


def full():
    c = Cv(64, 80)
    # cape, flowing behind to the left
    c.part(c.poly((28, 27), (39, 27), (37, 44), (31, 58), (28, 70), (22, 66), (18, 73), (13, 65), (8, 67), (11, 55),
                  (18, 41)), CAPE)
    # far arm hanging back, fist at the hip
    c.part(c.poly((22, 29), (30, 31), (25, 43), (22, 51), (14, 51), (15, 42)), FUR)
    c.part(c.ell(17, 54, 4.5, 4), FUR)
    c.part(c.rect(13, 48, 21, 51), IRON)
    # legs and boots
    c.part(c.poly((25, 49), (32, 49), (31, 64), (30, 71), (23, 71), (25, 62)), FUR)
    c.part(c.poly((24, 60), (31, 60), (30, 68), (24, 68)), IRON)
    c.part(c.poly((21, 68), (31, 68), (32, 73), (35, 77), (17, 77), (18, 72)), LEATHER)
    c.part(c.poly((33, 49), (41, 49), (45, 62), (48, 70), (41, 71), (37, 62), (33, 57)), FUR)
    c.part(c.poly((38, 59), (45, 59), (47, 67), (40, 67)), IRON)
    c.part(c.poly((38, 68), (48, 68), (50, 72), (57, 75), (56, 77), (36, 77)), LEATHER)
    c.dots([(24, 73), (28, 73), (41, 72), (45, 72)], "#ffd24a")
    # tabard
    c.part(c.poly((27, 49), (41, 49), (43, 61), (35, 66), (28, 59)), RED)
    # torso
    c.part(c.poly((22, 28), (41, 26), (45, 36), (43, 48), (22, 48), (19, 38)), FUR)
    # chest plate with ridge
    c.part(c.poly((26, 29), (41, 28), (44, 38), (40, 47), (29, 47), (25, 38)), IRON)
    c.line((35, 30), (35, 46), "#465070")
    c.dots([(29, 33), (40, 32), (29, 42), (40, 42)], "#ffd24a")
    # belt and buckle
    c.part(c.rect(21, 46, 44, 50), LEATHER)
    c.part(c.rect(31, 46, 37, 50), GOLD)
    # shoulders: fur mantle, fluffy edge
    c.part(c.ell(45, 31, 6, 5) | c.poly((40, 27), (50, 29), (51, 36), (47, 34), (46, 38), (43, 34)), FUR)
    c.part(c.ell(22, 31, 5, 4) | c.poly((18, 29), (26, 27), (24, 36), (21, 33), (19, 37)), FUR)
    # near arm: upper arm, bent forearm with gauntlet, fist with claws
    c.part(c.poly((40, 32), (48, 33), (51, 43), (45, 45)), FUR)
    c.part(c.poly((44, 42), (51, 44), (58, 31), (52, 27)), FUR)
    c.part(c.poly((48, 36), (54, 38), (58, 31), (52, 27)), IRON)
    c.part(c.ell(55, 25, 5, 4.5), FUR)
    for i, (x0, y0, x1, y1) in enumerate([(51, 22, 49, 12), (55, 21, 56, 10), (58, 23, 62, 14)]):
        c.line((x0, y0), (x1, y1), "#dfe8ff")
        c.line((x0 + 1, y0), (x1 + 1, y1 + 1), "#7a88a8")
    # neck fur then head
    c.part(c.ell(36, 26, 8, 3.5), CREAM)
    c.part(c.ell(46, 6, 4, 4), FUR)
    c.part(c.ell(27, 7, 5, 5), FUR)
    c.part(c.ell(27, 8, 2.5, 2.5), PINK, outline=False, dither=False)
    head = c.ell(36, 15, 12, 10) | c.poly((26, 13), (21, 19), (25, 20), (22, 25), (30, 24)) | c.poly((44, 22), (42, 27), (37, 24))
    c.part(head, FUR)
    c.fur(head, "#5c351a", 50, seed=3)
    c.fur(head, "#f0c080", 24, seed=4)
    c.part(c.ell(46, 19, 6.5, 5), CREAM)
    c.stamp(50, 16, ["ooo", "oko"], {"o": "#2a1408", "k": "#5a4a58"})
    c.line((48, 23), (42, 23), "#2a1408")
    c.dots([(44, 24), (46, 24)], "#fff4d8")
    c.stamp(35, 11, ["ooooo", "oEWEo", ".ooo."], {"o": "#2a1408", "E": "#ffb02a", "W": "#fff4d8"})
    c.stamp(45, 11, ["oooo", "oEEo"], {"o": "#2a1408", "E": "#ffb02a"})
    c.line((34, 8), (40, 10), "#2a1408"); c.line((34, 9), (39, 11), "#2a1408")
    c.line((44, 9), (49, 11), "#2a1408")
    for k in range(3):                                                                           # claw scars
        c.line((28 + k * 2, 6 + k), (29 + k * 2, 15 + k), "#ff6a5a")
    return c


def bust():
    c = Cv(64, 64)
    c.part(c.poly((10, 40), (24, 38), (20, 56), (22, 64), (0, 64), (2, 52)), CAPE)               # cape behind
    c.part(c.poly((16, 40), (46, 38), (54, 50), (56, 64), (6, 64), (8, 50)), FUR)                # body
    c.part(c.poly((20, 44), (44, 42), (50, 54), (50, 64), (14, 64), (14, 54)), IRON)             # chest plate
    c.line((32, 44), (32, 63), "#465070")
    c.dots([(22, 48), (42, 47), (20, 58), (44, 58)], "#ffd24a")
    c.part(c.ell(12, 44, 9, 7) | c.poly((3, 42), (10, 36), (8, 46), (4, 50)), FUR)               # far mantle
    c.part(c.ell(52, 46, 10, 8) | c.poly((44, 38), (58, 40), (62, 50), (56, 52), (54, 56), (48, 50)), FUR)
    c.part(c.ell(32, 41, 15, 5), CREAM)                                                          # neck ruff
    c.part(c.ell(46, 8, 6, 6), FUR); c.part(c.ell(46, 9, 3, 3), PINK, outline=False, dither=False)
    c.part(c.ell(14, 9, 7, 7), FUR); c.part(c.ell(14, 10, 3.5, 3.5), PINK, outline=False, dither=False)
    head = c.ell(30, 23, 18, 15) | c.poly((14, 20), (7, 28), (13, 29), (9, 37), (20, 36)) | c.poly((46, 34), (42, 42), (36, 37))
    c.part(head, FUR)
    c.fur(head, "#5c351a", 110, seed=3); c.fur(head, "#f0c080", 55, seed=4)
    c.part(c.ell(42, 30, 8, 6.5), CREAM)
    c.stamp(45, 24, ["ooooo", "okkko", ".ooo."], {"o": "#2a1408", "k": "#6a5a68"})
    c.line((48, 34), (40, 34), "#2a1408"); c.line((40, 34), (39, 32), "#2a1408")
    c.dots([(43, 35), (46, 35)], "#fff4d8")
    c.stamp(26, 17, ["oooooo", "oEWEEo", "oEEEEo", ".oooo."], {"o": "#2a1408", "E": "#ffb02a", "W": "#fff4d8"})
    c.stamp(40, 17, ["ooooo", "oEEEo", ".ooo."], {"o": "#2a1408", "E": "#ffb02a"})
    c.line((24, 13), (33, 16), "#2a1408"); c.line((24, 14), (32, 17), "#2a1408")
    c.line((39, 14), (46, 16), "#2a1408")
    for k in range(3):
        c.line((17 + k * 3, 6 + k), (18 + k * 3, 17 + k), "#ff6a5a")
    c.part(c.ell(54, 56, 7, 6), FUR)                                                             # raised fist
    for x0, x1 in [(50, 47), (54, 54), (58, 61)]:
        c.line((x0, 51), (x1, 42), "#dfe8ff"); c.line((x0 + 1, 51), (x1 + 1, 43), "#7a88a8")
    return c


if __name__ == "__main__":
    out = os.environ.get("SHEET_DIR", "/tmp")
    full().image(6).save(os.path.join(out, "pilot_full.png"))
    bust().image(6).save(os.path.join(out, "pilot_bust.png"))
