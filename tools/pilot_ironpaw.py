"""Pilot: IRONPAW redrawn with pix3 (3/4 pose, asymmetric, brown-bear anatomy: shoulder hump, long muzzle, small round
ears, small deep-set eyes). Writes full-body and bust previews to $SHEET_DIR."""
import os
import sys
sys.path.insert(0, os.path.dirname(__file__))
from pix3 import Cv

# hue-shifted ramps: highlights lean yellow, shadows lean red-purple
FUR = ["#f8d890", "#d29a52", "#9c5e30", "#623226", "#2e1422"]
FUR_D = ["#c88a50", "#9a5c32", "#6c3a24", "#46221e", "#22101a"]     # legs / far side, a step darker
CREAM = ["#fff6dc", "#f0d6a0", "#cca070", "#8c5e48", "#3a1c22"]
IRON = ["#f4fbff", "#b6c8dc", "#7486a8", "#454c74", "#1c1834"]
RED = ["#ffb08a", "#ee5a48", "#b42c3a", "#6e1834", "#2c0a1e"]
CAPE = ["#e47060", "#b23a44", "#7a2240", "#4a1434", "#1e0818"]
LEATHER = ["#c89a60", "#946238", "#623c28", "#3e2222", "#1a0c14"]
GOLD = ["#fff8c0", "#ffd450", "#e09a28", "#a0602a", "#4a2418"]
PINK = ["#ffd6c8", "#f2a0a0", "#c46a74", "#7c3448", "#2e1422"]
INK = "#2e1422"
EYE = {"o": INK, "E": "#ffb02a", "W": "#fff6dc", "b": "#5a2a14"}


def claws(c, roots):
    for (x0, y0), (x1, y1) in roots:
        c.line((x0, y0), (x1, y1), "#eef6ff")
        c.line((x0 + 1, y0 + 1), (x1 + 1, y1 + 1), "#7486a8")
        c.dots([(x1, y1)], "#ffffff")


def full():
    c = Cv(64, 80)
    # cape, flowing behind to the left
    c.part(c.poly((30, 28), (40, 29), (37, 44), (31, 58), (28, 70), (22, 66), (18, 73), (13, 65), (8, 67), (11, 55),
                  (18, 40)), CAPE)
    # far arm hanging back, iron cuff, fist at the hip
    c.part(c.poly((21, 31), (29, 33), (25, 44), (22, 51), (14, 51), (15, 42)), FUR_D, fur=True)
    c.part(c.ell(17, 54, 4.5, 4), FUR_D)
    c.part(c.rect(13, 48, 21, 51), IRON)
    # legs (darker fur like a real bear's legs), shin guards, boots
    c.part(c.poly((25, 49), (32, 49), (31, 64), (30, 71), (23, 71), (25, 62)), FUR_D, fur=True)
    c.part(c.poly((24, 60), (31, 60), (30, 68), (24, 68)), IRON)
    c.part(c.poly((21, 68), (31, 68), (32, 73), (35, 77), (17, 77), (18, 72)), LEATHER)
    c.part(c.poly((33, 49), (41, 49), (45, 62), (48, 70), (41, 71), (37, 62), (33, 57)), FUR_D, fur=True)
    c.part(c.poly((38, 59), (45, 59), (47, 67), (40, 67)), IRON)
    c.part(c.poly((38, 68), (48, 68), (50, 72), (57, 75), (56, 77), (36, 77)), LEATHER)
    c.dots([(24, 73), (28, 73), (41, 72), (45, 72)], "#ffd450")
    # tabard
    c.part(c.poly((27, 49), (41, 49), (43, 61), (35, 66), (28, 59)), RED)
    c.line((29, 52), (40, 52), "#ffd450")
    # torso
    c.part(c.poly((22, 30), (42, 28), (46, 36), (44, 48), (22, 48), (19, 38)), FUR, fur=True)
    # chest plate with ridge and rivets
    c.part(c.poly((27, 31), (42, 30), (45, 38), (41, 47), (30, 47), (26, 39)), IRON)
    c.line((36, 32), (36, 46), "#454c74")
    c.dots([(30, 35), (41, 34), (30, 43), (41, 43)], "#ffd450")
    # belt and buckle
    c.part(c.rect(21, 46, 45, 50), LEATHER)
    c.part(c.rect(32, 46, 37, 50), GOLD)
    # shoulder hump (the brown bear's muscle hump), far shoulder
    c.part(c.ell(27, 27, 10, 6.5) | c.poly((17, 28), (14, 34), (20, 32), (19, 37), (25, 33)), FUR, fur=True)
    # near arm: shoulder, upper arm, bent forearm with iron gauntlet, raised fist with iron claws
    c.part(c.ell(46, 33, 6, 5) | c.poly((40, 30), (51, 31), (53, 38), (49, 36), (47, 40), (44, 36)), FUR, fur=True)
    c.part(c.poly((42, 34), (49, 35), (52, 45), (46, 47)), FUR, fur=True)
    c.part(c.poly((46, 44), (52, 47), (60, 37), (54, 33)), FUR)
    c.part(c.poly((50, 41), (56, 43), (60, 37), (54, 33)), IRON)
    c.part(c.ell(57, 32, 5, 4.5), FUR)
    claws(c, [((54, 28), (52, 20)), ((57, 27), (58, 18)), ((60, 28), (62, 21))])
    # head: small round ears, broad skull, long muzzle
    c.part(c.ell(48, 7, 3.5, 3.5), FUR_D)
    c.part(c.ell(27, 7, 4.5, 4.5), FUR)
    c.part(c.ell(27, 8, 2, 2), PINK, outline=False, hi=False)
    head = c.ell(36, 17, 13, 11) | c.poly((25, 18), (21, 23), (25, 23), (23, 28), (29, 26)) | c.poly((44, 25), (41, 30), (36, 27))
    c.part(head, FUR, fur=True)
    c.part(c.ell(49, 21, 7, 5), CREAM)
    c.stamp(53, 17, ["oooo", "oWko", ".oo."], {"o": INK, "k": "#5a3a48", "W": "#a88a98"})            # nose
    c.line((55, 24), (46, 24), INK)
    c.dots([(48, 25), (51, 25)], "#fff6dc")                                                    # fangs
    c.stamp(36, 12, ["bbbbbb", "ooooo.", "oEWEo.", ".ooo.."], EYE)                               # near eye under brow
    c.stamp(46, 12, ["bbbb", "ooo.", "oEo."], EYE)                                               # far eye
    for k in range(3):                                                                         # claw scars
        c.line((28 + k * 2, 10 + k), (29 + k * 2, 18 + k), "#ff7060")
    return c


def bust():
    c = Cv(64, 64)
    c.part(c.poly((8, 42), (22, 40), (19, 56), (21, 64), (0, 64), (1, 52)), CAPE)                # cape behind
    c.part(c.poly((14, 42), (46, 40), (54, 50), (56, 64), (6, 64), (8, 50)), FUR_D, fur=True)       # body
    c.part(c.poly((20, 46), (44, 44), (50, 55), (50, 64), (15, 64), (15, 55)), IRON)             # chest plate
    c.line((33, 46), (33, 63), "#454c74")
    c.dots([(22, 50), (43, 49), (20, 59), (45, 59)], "#ffd450")
    c.part(c.ell(12, 38, 12, 9) | c.poly((1, 38), (8, 30), (6, 42), (1, 46)), FUR, fur=True)     # shoulder hump
    c.part(c.ell(52, 48, 10, 7) | c.poly((44, 41), (58, 42), (63, 51), (57, 53), (55, 57), (49, 51)), FUR, fur=True)
    c.part(c.ell(14, 8, 5.5, 5.5), FUR)                                                          # small round ears
    c.part(c.ell(14, 9, 2.5, 2.5), PINK, outline=False, hi=False)
    c.part(c.ell(42, 7, 4.5, 4.5), FUR_D)
    head = c.ell(28, 23, 19, 16) | c.poly((12, 26), (8, 32), (13, 31), (10, 37), (16, 35), (16, 40), (21, 36)) | c.poly((44, 36), (40, 44), (34, 38))
    c.part(head, FUR, fur=True)
    c.part(c.ell(47, 30, 11, 7.5), CREAM)                                                        # long muzzle
    c.stamp(52, 23, ["oooooo", "oWWkko", "okkkko", ".oooo."], {"o": INK, "k": "#5a3a48", "W": "#a88a98"})
    c.line((57, 35), (44, 35), INK)
    c.line((44, 35), (42, 33), INK)
    c.dots([(47, 36), (48, 36), (52, 36), (53, 36)], "#fff6dc")
    c.stamp(24, 15, ["bbbbbbbb", ".bbbbbb.", ".oooooo.", ".oEWWEo.", ".oEEEEo.", "..oooo.."], EYE)
    c.stamp(40, 15, ["bbbbb", "ooooo", "oEWEo", ".ooo."], EYE)
    for k in range(3):
        c.line((16 + k * 3, 9 + k), (17 + k * 3, 21 + k), "#ff7060")
    c.part(c.poly((47, 52), (60, 50), (63, 64), (46, 64)), IRON)                                 # gauntlet
    c.part(c.ell(55, 52, 7, 6), FUR)                                                             # raised fist
    claws(c, [((51, 47), (48, 38)), ((55, 46), (55, 36)), ((59, 47), (62, 39))])
    return c


if __name__ == "__main__":
    out = os.environ.get("SHEET_DIR", "/tmp")
    full().image(6).save(os.path.join(out, "pilot_full.png"))
    bust().image(6).save(os.path.join(out, "pilot_bust.png"))
