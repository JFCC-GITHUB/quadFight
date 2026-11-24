#!/usr/bin/env python3
"""Pixel-art car for the bonus stage: assets/bonus/car_0..4.png (pristine -> dented -> smoking -> burning -> wreck).

Drawn on a 64x32 grid and enlarged 6x with nearest neighbour. Run: python3 tools/gen_car.py
"""
import os
import random

from PIL import Image, ImageDraw, ImageFilter

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "bonus")
W, H, UP = 64, 32, 6
INK = (24, 16, 32, 255)
RED, RED_HI, RED_LO = (222, 58, 58, 255), (255, 120, 110, 255), (140, 28, 44, 255)
GLASS, GLASS_HI = (110, 190, 235, 255), (200, 240, 255, 255)
CHAR, CHAR_LO = (60, 50, 56, 255), (34, 28, 36, 255)


def outline(im):
    a = im.getchannel("A")
    ring = Image.eval(a.filter(ImageFilter.MaxFilter(3)), lambda v: 255 if v > 0 else 0)
    edge = Image.composite(Image.new("RGBA", im.size, INK), Image.new("RGBA", im.size, (0, 0, 0, 0)), ring)
    return Image.alpha_composite(edge, im)


def car(stage):
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    rnd = random.Random(3 + stage)
    body, hi, lo = RED, RED_HI, RED_LO
    if stage >= 3:  # charred
        body, hi, lo = CHAR, (96, 80, 84, 255), CHAR_LO
    sq = 4 if stage == 4 else 0  # the wreck sits lower
    bot = 25 + sq // 4
    # shadow
    d.ellipse((6, 28, 58, 31), fill=(0, 0, 0, 90))
    # lower body and cabin
    d.polygon([(4, 22 + sq), (6, 15 + sq), (14, 14 + sq), (22, 7 + sq), (42, 7 + sq), (50, 14 + sq), (60, 15 + sq), (62, 22 + sq), (60, bot), (6, bot)], fill=body)
    d.polygon([(6, 15 + sq), (14, 14 + sq), (22, 7 + sq), (42, 7 + sq), (50, 14 + sq), (60, 15 + sq), (60, 17 + sq), (6, 17 + sq)], fill=hi)
    d.rectangle((6, 22 + sq, 60, bot), fill=lo)
    # windows
    if stage < 4:
        for pts in ([(24, 9 + sq), (31, 9 + sq), (31, 14 + sq), (18, 14 + sq)], [(34, 9 + sq), (41, 9 + sq), (47, 14 + sq), (34, 14 + sq)]):
            d.polygon(pts, fill=GLASS if stage < 2 else (30, 36, 52, 255))
        if stage < 2:
            d.line((25, 10, 22, 13), fill=GLASS_HI)
            d.line((35, 10, 38, 13), fill=GLASS_HI)
    # door line, handle, lights, bumpers
    d.line((32, 15 + sq, 32, 23 + sq), fill=lo)
    d.rectangle((28, 17 + sq, 30, 17 + sq), fill=(235, 235, 240, 255))
    d.rectangle((58, 17 + sq, 61, 19 + sq), fill=(255, 235, 120, 255) if stage < 1 else (90, 80, 60, 255))  # headlight
    d.rectangle((4, 17 + sq, 6, 19 + sq), fill=(255, 70, 70, 255) if stage < 3 else (60, 20, 24, 255))      # tail light
    d.rectangle((3, 22 + sq, 6, 23 + sq), fill=(200, 200, 210, 255))
    d.rectangle((59, 22 + sq, 62, 23 + sq), fill=(200, 200, 210, 255) if stage < 2 else (120, 120, 130, 255))
    # damage
    if stage >= 1:  # dents and cracked glass
        for x, y, r in ((12, 19, 3), (47, 18, 3), (38, 22, 2)):
            d.ellipse((x - r, y - r, x + r, y + r), fill=lo)
        d.line((36, 9, 40, 14), fill=GLASS_HI)
        d.line((27, 9, 24, 14), fill=GLASS_HI)
    if stage >= 2:  # bent door, hanging bumper, smoke
        d.polygon([(33, 16 + sq), (45, 16 + sq), (44, 23 + sq), (34, 24 + sq)], fill=lo)
        d.rectangle((57, 24, 63, 26), fill=(150, 150, 160, 255))
        for k in range(5):
            x, y, r = 54 + rnd.randint(-5, 4), 9 - k * 3, 2 + k // 2
            d.ellipse((x - r, y - r, x + r, y + r), fill=(150, 150, 160, 220 - k * 30))
    if stage >= 3:  # flames on the hood
        for x0, h in ((50, 8), (55, 11), (59, 7), (45, 6)):
            d.polygon([(x0 - 3, 15 + sq), (x0, 15 + sq - h), (x0 + 3, 15 + sq)], fill=(255, 150, 40, 255))
            d.polygon([(x0 - 1, 15 + sq), (x0, 15 + sq - h + 3), (x0 + 2, 15 + sq)], fill=(255, 230, 110, 255))
    # wheels
    for cx in (15, 49):
        r = 5 if stage < 3 else 4
        d.ellipse((cx - r, 26 - r + sq // 2, cx + r, 26 + r + sq // 2 - 1), fill=(34, 30, 40, 255))
        d.ellipse((cx - 2, 24 + sq // 2, cx + 1, 27 + sq // 2), fill=(170, 170, 180, 255))
    if stage == 4:  # wreck: one wheel gone, big black smoke, small fires
        d.rectangle((44, 25, 54, 31), fill=(0, 0, 0, 0))
        for k in range(7):
            x, y, r = 30 + rnd.randint(-12, 12), 4 - k * 2, 3 + k // 2
            d.ellipse((x - r, y - r, x + r, y + r), fill=(40, 38, 46, 230 - k * 20))
        for x0 in (22, 38, 52):
            d.polygon([(x0 - 2, 14 + sq), (x0, 8 + sq), (x0 + 2, 14 + sq)], fill=(255, 150, 40, 255))
    return outline(im)


def main():
    os.makedirs(OUT, exist_ok=True)
    sheet = Image.new("RGB", (5 * W * UP // 2, H * UP // 2), (50, 44, 70))
    for st in range(5):
        im = car(st).resize((W * UP, H * UP), Image.NEAREST)
        im.save(os.path.join(OUT, f"car_{st}.png"))
        small = im.resize((W * UP // 2, H * UP // 2), Image.NEAREST)
        sheet.paste(small, (st * W * UP // 2, 0), small)
    sheet.save(os.path.join(os.environ.get("SHEET_DIR", "/tmp"), "car_sheet.png"))
    print("car written to", OUT)


if __name__ == "__main__":
    main()
