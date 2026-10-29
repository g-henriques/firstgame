#!/usr/bin/env python3
"""Generates every piece of art for Arena Survivor.

For each asset it writes:
  art/<name>.aseprite            editable source (open it in Aseprite)
  assets/sprites/<name>.png      horizontal sprite sheet
  assets/sprites/<name>.json     frame/tag data (same layout as Aseprite's
                                 `--data --format json-array --list-tags`)

After editing a .aseprite file in Aseprite, run tools/export_aseprite.sh to
re-export the sheets; the game reads the tags from the json, so new frames or
timings are picked up automatically.

Usage: python3 tools/art/build_art.py
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))

import aseprite  # noqa: E402
from pixel import (PAL, CLEAR, Img, from_ascii, mirror, outline, ellipse,  # noqa: E402
                   lerp_color, with_alpha, dither, save_sheet, noise_rng, strip)

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
ART = os.path.join(ROOT, "art")
SPRITES = os.path.join(ROOT, "assets", "sprites")
UI = os.path.join(ROOT, "assets", "ui")
FONTS = os.path.join(ROOT, "assets", "fonts")

P = PAL
K = P["outline"]


def save(name, frames, durations, tags, out_dir=SPRITES):
    save_sheet(name, frames, durations, tags, out_dir, ART, aseprite)
    print(f"  {name}: {len(frames)} frame(s) {frames[0].w}x{frames[0].h}")


def check(rows, w, name):
    for r in rows:
        assert len(r) == w, f"{name}: row {r!r} has {len(r)} cols, expected {w}"


def layer(rows, colors, w, h, oy=0, name="?"):
    check(rows, w, name)
    return from_ascii(rows, colors, w, h, 0, oy)


def compose(*parts):
    base = Img(parts[0][0].w, parts[0][0].h)
    for img, dx, dy in parts:
        base.paste(img.shifted(dx, dy), 0, 0)
    return base


# ---------------------------------------------------------------- characters

def build_player():
    c = {"h": P["brown"], "H": P["rust"], "s": P["skin"], "S": P["skinshade"], "e": K,
         "r": P["red"], "R": P["darkred"], "b": P["blue"], "B": P["deepblue"],
         "l": P["brown"], "y": P["gold"], "p": P["slate"], "o": P["darkbrown"]}
    head = layer([
        ".....hhhhhh.....",
        "....hHHHHhhh....",
        "....hhssssss....",
        "....hssseses....",
        "....hsssssSS....",
        ".....SsssSS.....",
    ], c, 16, 16, 2, "player head")
    body = layer([
        "....rrrrrrr.....",
        "...Rrbbbbbb.....",
        "...R.bbbbbbs....",
        ".....BllylB.....",
        ".....bbBbbb.....",
    ], c, 16, 16, 8, "player body")

    def legs(rows, oy=13):
        return layer(rows, c, 16, 16, oy, "player legs")

    stand = legs([".....pp..pp.....", ".....oo..oo....."])
    walk_a = legs(["....pp...pp.....", "...oo.....oo...."])
    walk_b = legs([".....ppppp......", "......pp.p......", "......oo.oo....."], 12)
    walk_c = legs(["......pp.pp.....", "......oo..oo...."])

    idle0 = compose((stand, 0, 0), (body, 0, 0), (head, 0, 0))
    idle1 = compose((stand, 0, 0), (body, 0, 1), (head, 0, 1))
    w0 = compose((walk_a, 0, 0), (body, 0, 0), (head, 0, 0))
    w1 = compose((walk_b, 0, 0), (body, 0, -1), (head, 0, -1))
    w2 = compose((walk_c, 0, 0), (body, 0, 0), (head, 0, 0))
    frames = [outline(f) for f in (idle0, idle1, w0, w1, w2, w1)]
    save("player", frames, [450, 450, 110, 110, 110, 110],
         [("idle", 0, 1), ("walk", 2, 5)])
    return frames[0]


def build_bat():
    c = {"v": P["wine"], "V": P["plum"], "m": P["pink"], "r": P["red"], "w": P["white"]}
    up = mirror(["........", "........", "........", "..m.....", "..mm....", "..mmm.v.",
                 "...mmvvv", "....vvrv", ".....vvv", ".....vwv", "......vV"])
    mid = mirror(["........", "........", "........", "........", "........", "......v.",
                  ".mmm.vvv", "mmmmvvrv", "m.mmmvvv", ".....vwv", "......vV"])
    down = mirror(["........", "........", "........", "........", "........", "......v.",
                   ".....vvv", "....mvrv", "...mmvvv", "..mmmvwv", "..mm..vV", "..m....."])
    fu = layer(up, c, 16, 16, 1, "bat")
    fm = layer(mid, c, 16, 16, 0, "bat")
    fd = layer(down, c, 16, 16, 0, "bat")
    frames = [outline(f) for f in (fu, fm, fd, fm)]
    save("bat", frames, [90] * 4, [("move", 0, 3)])


def build_slime():
    c = {"g": P["lime"], "G": P["green"], "L": P["mint"], "e": K}
    normal = mirror(["......gg", "....gggg", "...gLggg", "..gLggeg", "..gggggg", "..Gggggg",
                     "...GGGGG"])
    squash = mirror(["......gg", "...ggggg", "..gLggeg", ".gLggggg", ".GGggggg", "..GGGGGG"])
    stretch = mirror(["......gg", ".....ggg", "....gLgg", "....Lggg", "...gLgeg", "...ggggg",
                      "...ggggg", "...Ggggg", "....GGGG"])
    fn = layer(normal, c, 16, 16, 8, "slime")
    fs = layer(squash, c, 16, 16, 9, "slime")
    ft = layer(stretch, c, 16, 16, 6, "slime")
    frames = [outline(f) for f in (fn, fs, fn, ft)]
    save("slime", frames, [160, 140, 160, 140], [("move", 0, 3)])


def build_skeleton():
    c = {"w": P["fog"], "W": P["white"], "G": P["steel"], "e": K}
    upper = layer([
        "......wwww......",
        ".....wWWwww.....",
        ".....wwwewe.....",
        ".....wwwwww.....",
        "......wGwGw.....",
        ".......ww.......",
        ".....wwwwww.....",
        "....w.wGwGw.w...",
        "....w.wGwGw.w...",
        "....w..www..w...",
        "......wGGw......",
    ], c, 16, 16, 1, "skeleton")
    legs_a = layer(["......w..w......", "......w..w......", ".....ww..ww....."], c, 16, 16,
                   12, "skeleton legs")
    legs_b = layer([".....w....w.....", "....w......w....", "...ww......ww..."], c, 16, 16,
                   12, "skeleton legs")
    f0 = compose((legs_a, 0, 0), (upper, 0, 0))
    f1 = compose((legs_b, 0, 0), (upper, 0, 1))
    frames = [outline(f) for f in (f0, f1, f0, f1)]
    save("skeleton", frames, [140] * 4, [("move", 0, 3)])


def build_ghost():
    c = {"c": P["fog"], "W": P["white"], "G": P["silver"], "e": P["navy"]}
    top = mirror(["......cc", "....cccc", "...cWccc", "..cWcccc", "..ccceec", "..ccceec",
                  "..cccccc", "..ccccce", "..cccccc", "..Gccccc", "..GGcccc"])
    body = layer(top, c, 16, 16, 2, "ghost")
    tails = [
        ["..GGcGGccGGcGG..", "..G..GG..GG..G.."],
        ["..GGGcGGGGcGGG..", "...G..GG..GG..G."],
        ["..GGcGGccGGcGG..", "..G..GG..GG..G.."],
        ["..GGGcGGGGcGGG..", ".G..GG..GG..G..."],
    ]
    frames = []
    for i, t in enumerate(tails):
        bob = [0, -1, -1, 0][i]
        frames.append(outline(compose((layer(t, c, 16, 16, 13, "ghost tail"), 0, bob),
                                      (body, 0, bob))))
    save("ghost", frames, [150] * 4, [("move", 0, 3)])


def build_ogre():
    c = {"o": P["clay"], "O": P["rust"], "y": P["yellow"], "w": P["white"], "t": P["brown"],
         "T": P["darkbrown"], "c": P["brown"], "C": P["darkbrown"]}
    upper = layer([
        ".........oooooo.........",
        "........oooooooo........",
        "........ooooyoyo........",
        "........oooooooOo.......",
        "........OowooowO........",
        ".........OOOOOO.........",
        "......oooooooooooo......",
        ".....oooooooooooooo.....",
        "....oooOooooooooOooo....",
        "....ooo.ooooooooo.oocc..",
        "....ooo.ooooooooo.oocc..",
        "....OOO.ttttttttt.OOcc..",
        ".....O..tTtTtTtTt..OcCC.",
        "........ttttttttt...cCCC",
        "....................CCCC",
        ".....................CC.",
    ], c, 24, 24, 2, "ogre")
    legs_a = layer([
        ".........oo...oo........",
        ".........oo...oo........",
        ".........oo...oo........",
        "........OOO..OOO........",
    ], c, 24, 24, 16, "ogre legs")
    legs_b = layer([
        "........oo.....oo.......",
        "........oo.....oo.......",
        "........oo.....oo.......",
        ".......OOO.....OOO......",
    ], c, 24, 24, 16, "ogre legs")
    f0 = compose((legs_a, 0, 0), (upper, 0, 0))
    f1 = compose((legs_b, 0, 0), (upper, 0, -1))
    frames = [outline(f) for f in (f0, f1, f0, f1)]
    save("ogre", frames, [200] * 4, [("move", 0, 3)])


# ---------------------------------------------------------------- weapons / fx

def build_bolt():
    frames = []
    for i in range(3):
        img = Img(12, 12)
        cx = cy = 6
        r_out = 4.6 + (0.6 if i == 1 else 0)
        for y in range(12):
            for x in range(12):
                d = math.hypot(x + 0.5 - cx, y + 0.5 - cy)
                if d < 1.6:
                    img.set(x, y, P["white"])
                elif d < 3.0:
                    img.set(x, y, P["cyan"])
                elif d < 4.0:
                    img.set(x, y, P["blue"])
                elif d < r_out and dither(x + i, y, 0.5):
                    img.set(x, y, with_alpha(P["deepblue"], 220))
        # sparkle
        sx, sy = [(2, 2), (9, 3), (8, 9)][i]
        img.set(sx, sy, P["white"])
        frames.append(img)
    save("bolt", frames, [70] * 3, [("fly", 0, 2)])


def build_knife():
    c = {"l": P["clay"], "L": P["brown"], "y": P["gold"], "W": P["white"], "G": P["silver"]}
    base = layer([
        "................",
        "................",
        "................",
        "..lllyWWWWWWW...",
        "..LLLyGGGGGGGW..",
        "................",
        "................",
        "................",
    ], c, 16, 8, 0, "knife")
    save("knife", [outline(base)], [100], [("fly", 0, 0)])


def build_aura():
    size = 96
    frames = []
    for f in range(4):
        img = Img(size, size)
        c = size / 2
        for y in range(size):
            for x in range(size):
                d = math.hypot(x + 0.5 - c, y + 0.5 - c)
                if d > 47:
                    continue
                t = d / 47
                if t > 0.93:
                    img.set(x, y, with_alpha(P["yellow"], 200))
                elif t > 0.86:
                    if dither(x, y, 0.5):
                        img.set(x, y, with_alpha(P["gold"], 150))
                    else:
                        img.set(x, y, with_alpha(P["yellow"], 70))
                else:
                    a = int(25 + 35 * t)
                    img.set(x, y, with_alpha(P["yellow"], a))
        # rotating sparkles
        for k in range(8):
            ang = k * math.pi / 4 + f * math.pi / 16
            r = 40 if k % 2 else 30
            sx, sy = int(c + math.cos(ang) * r), int(c + math.sin(ang) * r)
            for dx, dy in ((0, 0), (1, 0), (-1, 0), (0, 1), (0, -1)):
                img.set(sx + dx, sy + dy, with_alpha(P["white"], 230 if (dx, dy) == (0, 0) else 160))
        frames.append(img)
    save("aura", frames, [120] * 4, [("pulse", 0, 3)])


def build_poof():
    frames = []
    for f in range(5):
        img = Img(16, 16)
        r = 2.5 + f * 1.4
        for y in range(16):
            for x in range(16):
                d = math.hypot(x + 0.5 - 8, y + 0.5 - 8)
                if d <= r:
                    inner = d < r - 2.2
                    if f >= 3 and inner:
                        continue
                    col = P["white"] if f < 2 else P["fog"] if f < 4 else P["silver"]
                    if f == 4 and not dither(x, y, 0.5):
                        continue
                    img.set(x, y, col)
        frames.append(img)
    save("poof", frames, [50, 50, 60, 70, 80], [("burst", 0, 4)])


def build_shadow():
    img = Img(14, 6)
    ellipse(img, 7, 3, 6.5, 2.6, (24, 20, 37, 90))
    save("shadow", [img], [100], [("idle", 0, 0)])


def build_pickups():
    gem = ["....LM....", "...LMMD...", "..LMMMDD..", "..MMMMDD..", "...MMDD...", "....DD...."]
    gems = {
        "gem_blue": (P["cyan"], P["blue"], P["deepblue"]),
        "gem_green": (P["mint"], P["lime"], P["green"]),
        "gem_red": (P["salmon"], P["red"], P["darkred"]),
        "gem_purple": (P["salmon"], P["pink"], P["wine"]),
    }
    frames, tags = [], []
    for name, (l, m, d) in gems.items():
        img = outline(layer(gem, {"L": l, "M": m, "D": d}, 10, 10, 2, name))
        img.set(4, 3, P["white"])
        tags.append((name, len(frames), len(frames)))
        frames.append(img)
    heart = layer(["..rr.rr...", ".rwrrrrR..", ".rrrrrrR..", "..rrrrR...", "...rrR....",
                   "....R....."], {"r": P["red"], "R": P["darkred"], "w": P["white"]},
                  10, 10, 2, "heart")
    tags.append(("heart", len(frames), len(frames)))
    frames.append(outline(heart))
    skull = layer(["...wwww...", "..wwwwww..", "..wewwew..", "..wewwew..", "..wwwwww..",
                   "...wGwG..."], {"w": P["fog"], "e": K, "G": P["steel"]}, 10, 10, 2, "skull")
    tags.append(("skull", len(frames), len(frames)))
    frames.append(outline(skull))
    clock = Img(10, 10)
    ellipse(clock, 5, 5, 4, 4, P["fog"])
    ellipse(clock, 5, 5, 3, 3, P["white"])
    for y in range(2, 6):
        clock.set(5, y, K)
    clock.set(6, 5, K)
    clock.set(7, 5, K)
    tags.append(("clock", len(frames), len(frames)))
    frames.append(outline(clock))
    star = layer(["....yy....", "....yy....", "yyyyyyyyyy", ".yyyyyyyy.", "..yyyyyy..",
                  "..yyOyyy..", ".yyy..yyy.", ".yy....yy."],
                 {"y": P["yellow"], "O": P["gold"]}, 10, 10, 1, "star")
    star.set(4, 2, P["white"])
    tags.append(("star", len(frames), len(frames)))
    frames.append(outline(star))
    chest = layer(["..........", ".bbbbbbbb.", ".bBBBBBBb.", ".yyyywyyy.", ".bbbyybbb.",
                   ".bbbbbbbb.", ".BBBBBBBB."],
                  {"b": P["clay"], "B": P["rust"], "y": P["gold"], "w": P["yellow"]},
                  10, 10, 1, "chest")
    tags.append(("chest", len(frames), len(frames)))
    frames.append(outline(chest))
    save("pickups", frames, [100] * len(frames), tags)


# ---------------------------------------------------------------- tileset / map

T = 16


def grass_tile(seed, dark=False):
    rng = noise_rng(seed)
    img = Img(T, T, P["forest"] if dark else P["green"])
    for y in range(T):
        for x in range(T):
            r = rng.random()
            if r < 0.18:
                img.set(x, y, P["forest"] if not dark else P["pine"])
            elif r < 0.24:
                img.set(x, y, P["lime"] if not dark else P["green"])
    for _ in range(5):
        x, y = rng.randrange(T), rng.randrange(1, T)
        img.set(x, y, P["lime"] if not dark else P["green"])
        img.set(x, y - 1, P["mint"] if not dark else P["lime"])
    return img


def dirt_tile(seed):
    rng = noise_rng(seed)
    img = Img(T, T, P["clay"])
    for y in range(T):
        for x in range(T):
            r = rng.random()
            if r < 0.2:
                img.set(x, y, P["rust"])
            elif r < 0.28:
                img.set(x, y, P["tan"])
    for _ in range(3):
        x, y = rng.randrange(T - 1), rng.randrange(T - 1)
        img.set(x, y, P["brown"])
        img.set(x + 1, y, P["tan"])
    return img


def stone_floor(seed, cracked=False, rune=False):
    rng = noise_rng(seed)
    img = Img(T, T, P["silver"])
    # 2x2 slabs, offset rows
    for y in range(T):
        for x in range(T):
            col = P["silver"]
            if rng.random() < 0.15:
                col = P["fog"]
            elif rng.random() < 0.12:
                col = P["steel"]
            img.set(x, y, col)
    for x in range(T):
        img.set(x, 7, P["steel"])
        img.set(x, 15, P["steel"])
        img.set(x, 0, P["fog"])
        img.set(x, 8, P["fog"])
    for y in range(0, 8):
        img.set(7, y, P["steel"])
        img.set(8, y, P["fog"])
    for y in range(8, 16):
        img.set(15, y, P["steel"])
        img.set(0, y, P["fog"])
    if cracked:
        x, y = 3, 2
        for _ in range(9):
            img.set(x, y, P["slate"])
            x += rng.choice([0, 1])
            y += 1
    if rune:
        for y in range(T):
            for x in range(T):
                d = math.hypot(x + 0.5 - 8, y + 0.5 - 8)
                if 4.2 < d < 5.6:
                    img.set(x, y, P["cyan"] if (x + y) % 3 else P["blue"])
        img.rect(7, 7, 2, 2, P["cyan"])
    return img


def wall_top(seed):
    rng = noise_rng(seed)
    img = Img(T, T, P["slate"])
    for y in range(T):
        for x in range(T):
            if rng.random() < 0.2:
                img.set(x, y, P["navy"])
            elif rng.random() < 0.08:
                img.set(x, y, P["steel"])
    for x in range(T):
        img.set(x, 0, P["steel"])
    return img


def wall_face(seed, torch=False):
    img = Img(T, T, P["steel"])
    for row in range(4):
        y0 = row * 4
        off = 0 if row % 2 == 0 else 4
        for x in range(T):
            img.set(x, y0 + 3, P["navy"])
            img.set(x, y0, P["silver"])
        for bx in range(-8, T, 8):
            x = bx + off
            for y in range(y0, y0 + 4):
                img.set(x, y, P["navy"])
                img.set(x + 1, y, P["silver"] if y != y0 + 3 else P["navy"])
    for x in range(T):
        img.set(x, 15, K)
        img.set(x, 14, P["slate"])
    if torch:
        img.rect(7, 7, 2, 6, P["brown"])
        img.rect(6, 6, 4, 2, P["darkbrown"])
        flame = [(7, 3, "yellow"), (8, 3, "gold"), (7, 4, "yellow"), (8, 4, "yellow"),
                 (6, 5, "orange"), (7, 5, "gold"), (8, 5, "gold"), (9, 5, "orange"), (8, 2, "orange"),
                 (7, 2, "gold")]
        for x, y, c in flame:
            img.set(x, y, P[c])
    return img


def deco(base, rows, colors, oy=0):
    d = outline(from_ascii(rows, colors, T, T, 0, oy))
    out = base.copy()
    out.paste(d, 0, 0)
    return out


def build_tileset():
    tiles = []
    grass = grass_tile(1)
    tiles.append(grass)                           # 0 grass
    tiles.append(grass_tile(2))                   # 1 grass b
    flowers = grass_tile(3)
    rng = noise_rng(30)
    for _ in range(4):
        x, y = rng.randrange(2, 14), rng.randrange(2, 14)
        col = rng.choice([P["yellow"], P["white"], P["salmon"]])
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            flowers.set(x + dx, y + dy, col)
        flowers.set(x, y, P["gold"])
    tiles.append(flowers)                         # 2 flowers
    tuft = deco(grass_tile(4), ["................", "................", "................",
                                "................", "................", "......m...m.....",
                                "...m..lm.ml.....", "...lm.ll.ll..m..", "....l.ll.l..ml..",
                                "....llllll..l..."], {"m": P["mint"], "l": P["lime"]}, 2)
    tiles.append(tuft)                            # 3 tuft
    tiles.append(grass_tile(5, dark=True))        # 4 dark grass
    tiles.append(dirt_tile(6))                    # 5 dirt
    mix = dirt_tile(7)
    g = grass_tile(8)
    rng = noise_rng(9)
    for y in range(T):
        for x in range(T):
            if rng.random() < 0.45:
                mix.set(x, y, g.get(x, y))
    tiles.append(mix)                             # 6 dirt/grass mix
    tiles.append(stone_floor(10))                 # 7 stone
    tiles.append(stone_floor(11, cracked=True))   # 8 stone cracked
    tiles.append(wall_top(12))                    # 9 wall top
    tiles.append(wall_face(13))                   # 10 wall face
    tiles.append(wall_face(14, torch=True))       # 11 wall face + torch
    bush = deco(grass_tile(15), ["................", "................", "................",
                                 "....mllll.......", "...mlllllll.....", "..mllGlllllG....",
                                 "..llllllGlll....", "..lGlllllllG....", "...lllGlllG.....",
                                 "....GGGGGGG....."],
                {"m": P["mint"], "l": P["lime"], "G": P["green"]}, 3)
    tiles.append(bush)                            # 12 bush
    rock = deco(grass_tile(16), ["................", "................", "................",
                                 "................", "................", ".....ffss.......",
                                 "....fssssss.....", "...fsssssssS....", "...sssssssSS....",
                                 "....SSSSSSS....."],
                {"f": P["fog"], "s": P["silver"], "S": P["steel"]}, 3)
    tiles.append(rock)                            # 13 rock
    bones = deco(grass_tile(17), ["................", "................", "................",
                                  "................", "................", "................",
                                  "..ww......www...", "...wwwwwwwwew...", "..ww....w.www...",
                                  "........w......."],
                 {"w": P["fog"], "e": K}, 2)
    tiles.append(bones)                           # 14 bones
    mush = deco(grass_tile(18), ["................", "................", "................",
                                 "................", "................", "........rr......",
                                 ".......rwrr.....", "......rrrwrr....", "........ss......",
                                 "........ss......"],
                {"r": P["red"], "w": P["white"], "s": P["sand"]}, 3)
    tiles.append(mush)                            # 15 mushroom
    tiles.append(stone_floor(19, rune=True))      # 16 rune stone
    tiles.append(grass_tile(20, dark=True))       # 17 dark grass b
    cols = 8
    rows = (len(tiles) + cols - 1) // cols
    sheet = Img(cols * T, rows * T)
    for i, t in enumerate(tiles):
        sheet.paste(t, (i % cols) * T, (i // cols) * T)
    save("tileset", [sheet], [100], [])


# ---------------------------------------------------------------- icons

def icon(rows, colors, name):
    check(rows, 16, name)
    return outline(from_ascii(rows, colors, 16, 16))


def build_icons():
    out = []

    out.append(("wand", icon([
        "................",
        "................",
        "..y.......cc....",
        ".........cWcc...",
        "....y....cccb...",
        "..........bb..y.",
        ".........lL.....",
        "........lL......",
        ".......lL.......",
        "......lL........",
        ".....lL.........",
        "....lL..........",
        "...lL...........",
        "..lL............",
        "................",
        "................",
    ], {"y": P["yellow"], "c": P["cyan"], "W": P["white"], "b": P["blue"], "l": P["clay"],
        "L": P["brown"]}, "wand")))

    out.append(("knife", icon([
        "................",
        "............WW..",
        "...........WGW..",
        "..........WGG...",
        ".........WGG....",
        "........WGG.....",
        ".......WGG......",
        "...yy.WGG.......",
        "....yWGG........",
        "....yyG.........",
        "...lL.yy........",
        "..lL............",
        ".lL.............",
        "................",
        "................",
        "................",
    ], {"W": P["white"], "G": P["silver"], "y": P["gold"], "l": P["clay"], "L": P["brown"]},
        "knife")))

    aura = Img(16, 16)
    for y in range(16):
        for x in range(16):
            d = math.hypot(x + 0.5 - 8, y + 0.5 - 8)
            if d < 2:
                aura.set(x, y, P["white"])
            elif d < 4.5:
                aura.set(x, y, P["yellow"])
            elif d < 6 and dither(x, y, 0.5):
                aura.set(x, y, P["gold"])
            elif 6 <= d < 7:
                aura.set(x, y, P["gold"])
    out.append(("aura", outline(aura)))

    out.append(("might", icon([
        "................",
        ".......WG.......",
        ".......WG.......",
        ".......WG.......",
        ".......WG.......",
        ".......WG.......",
        ".......WG.......",
        ".......WG.......",
        "....yyyyyyyy....",
        ".......rR.......",
        ".......rR.......",
        "......yyyy......",
        "................",
        "................",
        "................",
        "................",
    ], {"W": P["white"], "G": P["silver"], "y": P["gold"], "r": P["red"], "R": P["darkred"]},
        "might").shifted(0, 1)))

    out.append(("speed", icon([
        "................",
        "................",
        "..WW............",
        ".WWWW..bbbb.....",
        "..WWWW.bbbb.....",
        "...WWWWbbbb.....",
        ".......bbbb.....",
        ".......bbbb.....",
        ".......bbbbbb...",
        ".......bbbbbbbb.",
        ".......BBBBBBBB.",
        "................",
        "................",
        "................",
        "................",
        "................",
    ], {"W": P["fog"], "b": P["clay"], "B": P["brown"]}, "speed").shifted(-1, 2)))

    heart = icon([
        "................",
        "................",
        "....rrr..rrr....",
        "...rwwrrrrrrr...",
        "..rwrrrrrrrrrR..",
        "..rrrrrrrrrrrR..",
        "..rrrrrrrrrrrR..",
        "...rrrrrrrrrR...",
        "....rrrrrrrR....",
        ".....rrrrrR.....",
        "......rrRR......",
        ".......RR.......",
        "................",
        "................",
        "................",
        "................",
    ], {"r": P["red"], "R": P["darkred"], "w": P["white"]}, "vitality")
    for x, y in ((7, 5), (8, 5), (6, 6), (7, 6), (8, 6), (9, 6), (7, 7), (8, 7)):
        heart.set(x, y, P["white"])
    out.append(("vitality", heart.shifted(0, 1)))

    out.append(("recovery", icon([
        "................",
        "......llll......",
        ".......ff.......",
        ".......ff.......",
        ".....ffffff.....",
        "....ffggggff....",
        "...fgWggggggf...",
        "...fgWggggggf...",
        "...fggggggggf...",
        "...fggggggGGf...",
        "....fGGGGGGf....",
        ".....ffffff.....",
        "................",
        "................",
        "................",
        "................",
    ], {"l": P["brown"], "f": P["fog"], "g": P["lime"], "G": P["green"], "W": P["white"]},
        "recovery").shifted(0, 1)))

    out.append(("armor", icon([
        "................",
        "...ssssssssss...",
        "...sbbbbbbbbs...",
        "...sbbbyybbbs...",
        "...sbbyyyybbs...",
        "...sbbbyybbbs...",
        "...sbbbyybbbs...",
        "...sBbbbbbbBs...",
        "....sBbbbbBs....",
        ".....sBbbBs.....",
        "......sBBs......",
        ".......ss.......",
        "................",
        "................",
        "................",
        "................",
    ], {"s": P["silver"], "b": P["blue"], "B": P["deepblue"], "y": P["gold"]}, "armor")
        .shifted(0, 1)))

    out.append(("magnet", icon([
        "................",
        "...WWW....WWW...",
        "...WWW....WWW...",
        "...rrr....rrr...",
        "...rrr....rrr...",
        "...rrr....rrr...",
        "...rrr....rrr...",
        "...rrrr..rrrr...",
        "...rrrrrrrrrr...",
        "....rrrrrrrr....",
        ".....RRRRRR.....",
        "................",
        "................",
        "................",
        "................",
        "................",
    ], {"W": P["fog"], "r": P["red"], "R": P["darkred"]}, "magnet").shifted(0, 2)))

    out.append(("cooldown", icon([
        "................",
        "...llllllllll...",
        "....ffffffff....",
        "....fyyyyyyf....",
        ".....fyyyyf.....",
        "......fyyf......",
        ".......ff.......",
        "......fyyf......",
        ".....f.yy.f.....",
        "....f.yyyy.f....",
        "....fyyyyyyf....",
        "...llllllllll...",
        "................",
        "................",
        "................",
        "................",
    ], {"l": P["brown"], "f": P["fog"], "y": P["gold"]}, "cooldown").shifted(0, 1)))

    amount = Img(16, 16)
    orb = from_ascii([".cc.", "cWcc", "cccb", ".bb."],
                     {"c": P["cyan"], "W": P["white"], "b": P["blue"]})
    for ox, oy in ((6, 2), (2, 9), (10, 9)):
        amount.paste(orb, ox, oy)
    out.append(("amount", outline(amount)))

    area = Img(16, 16)
    for y in range(16):
        for x in range(16):
            d = math.hypot(x + 0.5 - 8, y + 0.5 - 8)
            if 3.2 < d < 4.6:
                area.set(x, y, P["cyan"])
            elif d < 1.5:
                area.set(x, y, P["white"])
    arrows = [(8, 1, 0, 1), (8, 14, 0, -1), (1, 8, 1, 0), (14, 8, -1, 0)]
    for ax, ay, dx, dy in arrows:
        # arrow tip pointing outwards
        area.set(ax, ay, P["yellow"])
        area.set(ax - 1 if dy else ax, ay if dy else ay - 1, P["yellow"])
        for k in (1, 2):
            px, py = ax + dx * k, ay + dy * k
            area.set(px, py, P["yellow"])
            area.set(px - 1 if dy else px, py if dy else py - 1, P["yellow"])
        # arrow head wings
        area.set(ax - 2 if dy else ax + dx, ay + dy if dy else ay - 2, P["gold"])
        area.set(ax + 1 if dy else ax + dx, ay + dy if dy else ay + 1, P["gold"])
    out.append(("area", outline(area)))

    star = icon([
        "................",
        ".......yy.......",
        ".......yy.......",
        "......yyyy......",
        ".yyyyyyyyyyyyyy.",
        "..yyyyyyyyyyyy..",
        "...yyyyyyyyyy...",
        "....yyyyyyyy....",
        "....yyyyyyyy....",
        "...yyyyyyyyyy...",
        "...yyyy..yyyy...",
        "..yyy......yyy..",
        "..yy........yy..",
        "................",
        "................",
        "................",
    ], {"y": P["yellow"]}, "growth")
    for x, y in ((7, 2), (6, 4), (7, 4), (5, 5)):
        star.set(x, y, P["white"])
    for x, y in ((11, 5), (10, 6), (11, 10), (12, 11), (12, 12), (9, 8), (10, 9)):
        star.set(x, y, P["gold"])
    out.append(("growth", star.shifted(0, 1)))

    out.append(("heal", icon([
        "................",
        "................",
        "......cccc......",
        ".....ccccccc....",
        "....ccTcccccc...",
        "....cccccccCC...",
        "....ccccccCCC...",
        ".....cccccCC....",
        "......ccCCC.....",
        "........WW......",
        ".........WW.....",
        "........WWWW....",
        ".........WW.....",
        "................",
        "................",
        "................",
    ], {"c": P["clay"], "C": P["rust"], "T": P["tan"], "W": P["white"]}, "heal")))

    frames = [img for _, img in out]
    tags = [(name, i, i) for i, (name, _) in enumerate(out)]
    save("icons", frames, [100] * len(frames), tags)


# ---------------------------------------------------------------- GUI

def bevel_box(w, h, fill, light, dark, border=K, inner=None):
    img = Img(w, h, fill)
    for x in range(w):
        img.set(x, 0, border)
        img.set(x, h - 1, border)
        img.set(x, 1, light)
        img.set(x, h - 2, dark)
    for y in range(h):
        img.set(0, y, border)
        img.set(w - 1, y, border)
        if 0 < y < h - 1:
            img.set(1, y, light)
            img.set(w - 2, y, dark)
    if inner:
        for x in range(2, w - 2):
            img.set(x, 2, inner)
            img.set(x, h - 3, inner)
        for y in range(2, h - 2):
            img.set(2, y, inner)
            img.set(w - 3, y, inner)
    # rounded corners
    for x, y in ((0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)):
        img.set(x, y, CLEAR)
    for x, y in ((1, 1), (w - 2, 1), (1, h - 2), (w - 2, h - 2)):
        img.set(x, y, border)
    return img


def build_gui():
    os.makedirs(UI, exist_ok=True)
    items = {}

    panel = bevel_box(24, 24, P["navy"], P["silver"], P["steel"], inner=K)
    for x in range(3, 21):
        panel.set(x, 3, P["slate"])
    for x, y in ((3, 3), (20, 3), (3, 20), (20, 20)):
        panel.set(x, y, P["gold"])
    items["panel"] = panel

    gold = bevel_box(24, 24, P["navy"], P["yellow"], P["orange"], inner=K)
    for x in range(3, 21):
        gold.set(x, 3, P["slate"])
    for x, y in ((3, 3), (20, 3), (3, 20), (20, 20)):
        gold.set(x, y, P["white"])
    items["panel_gold"] = gold

    def button(fill, light, dark, border=K, press=False):
        img = Img(24, 16, CLEAR)
        body = bevel_box(24, 15, fill, light, dark, border)
        if press:
            img.paste(body, 0, 1)
        else:
            img.paste(body, 0, 0)
            for x in range(1, 23):
                img.set(x, 15, P["navy"] if x not in (1, 22) else CLEAR)
            img.set(0, 15, CLEAR)
            img.set(23, 15, CLEAR)
        return img

    items["button_normal"] = button(P["slate"], P["steel"], P["navy"])
    items["button_hover"] = button(P["steel"], P["silver"], P["slate"], P["gold"])
    items["button_pressed"] = button(P["navy"], P["slate"], P["navy"], P["gold"], press=True)
    items["button_disabled"] = button(P["navy"], P["slate"], P["navy"], P["slate"])
    focus = Img(24, 16)
    for x in range(1, 23):
        focus.set(x, 0, P["yellow"])
        focus.set(x, 15, P["yellow"])
    for y in range(1, 15):
        focus.set(0, y, P["yellow"])
        focus.set(23, y, P["yellow"])
    items["button_focus"] = focus

    bar = Img(12, 8, P["navy"])
    for x in range(12):
        bar.set(x, 0, K)
        bar.set(x, 7, K)
        bar.set(x, 6, P["slate"])
    for y in range(8):
        bar.set(0, y, K)
        bar.set(11, y, K)
    bar.set(0, 0, CLEAR)
    bar.set(11, 0, CLEAR)
    bar.set(0, 7, CLEAR)
    bar.set(11, 7, CLEAR)
    items["bar_bg"] = bar

    def fill(colors):
        img = Img(4, 6)
        for y, c in enumerate(colors):
            for x in range(4):
                img.set(x, y, c)
        return img

    items["bar_hp"] = fill([P["salmon"], P["red"], P["red"], P["red"], P["darkred"], P["darkred"]])
    items["bar_xp"] = fill([P["cyan"], P["cyan"], P["blue"], P["blue"], P["deepblue"], P["deepblue"]])
    items["bar_boss"] = fill([P["pink"], P["wine"], P["wine"], P["wine"], P["plum"], P["plum"]])

    slot = bevel_box(20, 20, P["navy"], P["steel"], P["slate"])
    items["slot"] = slot

    overlay = Img(4, 4, (24, 20, 37, 170))
    items["dim"] = overlay

    for name, img in items.items():
        save(name, [img], [100], [], out_dir=UI)


# ---------------------------------------------------------------- font + logo

GLYPHS = {
    "A": [".###.", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
    "B": ["####.", "#...#", "#...#", "####.", "#...#", "#...#", "####."],
    "C": [".###.", "#...#", "#....", "#....", "#....", "#...#", ".###."],
    "D": ["####.", "#...#", "#...#", "#...#", "#...#", "#...#", "####."],
    "E": ["#####", "#....", "#....", "####.", "#....", "#....", "#####"],
    "F": ["#####", "#....", "#....", "####.", "#....", "#....", "#...."],
    "G": [".###.", "#...#", "#....", "#.###", "#...#", "#...#", ".###."],
    "H": ["#...#", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
    "I": ["###", ".#.", ".#.", ".#.", ".#.", ".#.", "###"],
    "J": ["..###", "...#.", "...#.", "...#.", "#..#.", "#..#.", ".##.."],
    "K": ["#...#", "#..#.", "#.#..", "##...", "#.#..", "#..#.", "#...#"],
    "L": ["#....", "#....", "#....", "#....", "#....", "#....", "#####"],
    "M": ["#...#", "##.##", "#.#.#", "#.#.#", "#...#", "#...#", "#...#"],
    "N": ["#...#", "##..#", "#.#.#", "#..##", "#...#", "#...#", "#...#"],
    "O": [".###.", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
    "P": ["####.", "#...#", "#...#", "####.", "#....", "#....", "#...."],
    "Q": [".###.", "#...#", "#...#", "#...#", "#.#.#", "#..#.", ".##.#"],
    "R": ["####.", "#...#", "#...#", "####.", "#.#..", "#..#.", "#...#"],
    "S": [".####", "#....", "#....", ".###.", "....#", "....#", "####."],
    "T": ["#####", "..#..", "..#..", "..#..", "..#..", "..#..", "..#.."],
    "U": ["#...#", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
    "V": ["#...#", "#...#", "#...#", "#...#", "#...#", ".#.#.", "..#.."],
    "W": ["#...#", "#...#", "#...#", "#.#.#", "#.#.#", "##.##", "#...#"],
    "X": ["#...#", "#...#", ".#.#.", "..#..", ".#.#.", "#...#", "#...#"],
    "Y": ["#...#", "#...#", ".#.#.", "..#..", "..#..", "..#..", "..#.."],
    "Z": ["#####", "....#", "...#.", "..#..", ".#...", "#....", "#####"],
    "0": [".###.", "#...#", "#..##", "#.#.#", "##..#", "#...#", ".###."],
    "1": [".#.", "##.", ".#.", ".#.", ".#.", ".#.", "###"],
    "2": [".###.", "#...#", "....#", "...#.", "..#..", ".#...", "#####"],
    "3": ["####.", "....#", "....#", ".###.", "....#", "....#", "####."],
    "4": ["...#.", "..##.", ".#.#.", "#..#.", "#####", "...#.", "...#."],
    "5": ["#####", "#....", "####.", "....#", "....#", "#...#", ".###."],
    "6": [".###.", "#....", "#....", "####.", "#...#", "#...#", ".###."],
    "7": ["#####", "....#", "...#.", "..#..", ".#...", ".#...", ".#..."],
    "8": [".###.", "#...#", "#...#", ".###.", "#...#", "#...#", ".###."],
    "9": [".###.", "#...#", "#...#", ".####", "....#", "....#", ".###."],
    "!": ["#", "#", "#", "#", "#", ".", "#"],
    "?": [".###.", "#...#", "....#", "...#.", "..#..", ".....", "..#.."],
    ".": [".", ".", ".", ".", ".", ".", "#"],
    ",": ["..", "..", "..", "..", "..", ".#", "#."],
    ":": [".", "#", ".", ".", ".", "#", "."],
    ";": ["..", ".#", "..", "..", "..", ".#", "#."],
    "-": ["....", "....", "....", "####", "....", "....", "...."],
    "+": [".....", "..#..", "..#..", "#####", "..#..", "..#..", "....."],
    "=": [".....", ".....", "#####", ".....", "#####", ".....", "....."],
    "/": ["....#", "...#.", "...#.", "..#..", ".#...", ".#...", "#...."],
    "%": ["##..#", "##..#", "...#.", "..#..", ".#...", "#..##", "#..##"],
    "(": [".#", "#.", "#.", "#.", "#.", "#.", ".#"],
    ")": ["#.", ".#", ".#", ".#", ".#", ".#", "#."],
    "'": ["#", "#", ".", ".", ".", ".", "."],
    '"': ["#.#", "#.#", "...", "...", "...", "...", "..."],
    "<": ["...#", "..#.", ".#..", "#...", ".#..", "..#.", "...#"],
    ">": ["#...", ".#..", "..#..", "...#", "..#.", ".#..", "#..."],
    "_": ["....", "....", "....", "....", "....", "....", "####"],
    "#": [".#.#.", "#####", ".#.#.", ".#.#.", ".#.#.", "#####", ".#.#."],
    "*": [".....", "#.#.#", ".###.", "#####", ".###.", "#.#.#", "....."],
    "×": [".....", ".....", "#...#", ".#.#.", "..#..", ".#.#.", "#...#"],
}
GLYPHS[">"] = ["#...", ".#..", "..#.", "...#", "..#.", ".#..", "#..."]

ACCENTS = {
    "acute": ["..#", ".#."],
    "grave": ["#..", ".#."],
    "circ": [".#.", "#.#"],
    "tilde": [".#.#", "#.#."],
}
ACCENTED = {
    "Á": ("A", "acute"), "À": ("A", "grave"), "Â": ("A", "circ"), "Ã": ("A", "tilde"),
    "É": ("E", "acute"), "È": ("E", "grave"), "Ê": ("E", "circ"),
    "Í": ("I", "acute"), "Ì": ("I", "grave"),
    "Ó": ("O", "acute"), "Ò": ("O", "grave"), "Ô": ("O", "circ"), "Õ": ("O", "tilde"),
    "Ú": ("U", "acute"), "Ù": ("U", "grave"),
}

CELL_W, CELL_H, CAP_TOP = 6, 11, 2


def glyph_bitmap(ch):
    """Returns (rows of height CELL_H, width)."""
    if ch == "Ç":
        base = GLYPHS["C"]
        rows = ["." * 5] * CAP_TOP + base + ["..#..", ".#..."]
        return rows, 5
    if ch in ACCENTED:
        letter, acc = ACCENTED[ch]
        base = GLYPHS[letter]
        w = len(base[0])
        a = ACCENTS[acc]
        aw = len(a[0])
        pad = max(0, (w - aw + 1) // 2)
        acc_rows = [("." * pad + r).ljust(w, ".")[:w] for r in a]
        return acc_rows + base + ["." * w] * 2, w
    base = GLYPHS[ch]
    w = len(base[0])
    return ["." * w] * CAP_TOP + base + ["." * w] * 2, w


def build_font():
    os.makedirs(FONTS, exist_ok=True)
    chars = list(GLYPHS.keys()) + list(ACCENTED.keys()) + ["Ç"]
    entries = []
    cols = 16
    total = len(chars) + 1
    rows_n = (total + cols - 1) // cols
    sheet = Img(cols * CELL_W, rows_n * CELL_H)
    white = P["white"]
    bitmaps = {}
    for i, ch in enumerate(chars):
        rows, w = glyph_bitmap(ch)
        assert len(rows) == CELL_H, ch
        x0, y0 = (i % cols) * CELL_W, (i // cols) * CELL_H
        for y, r in enumerate(rows):
            assert len(r) == w, (ch, r)
            for x, px in enumerate(r):
                if px == "#":
                    sheet.set(x0 + x, y0 + y, white)
        bitmaps[ch] = (rows, w)
        entries.append((ch, x0, y0, w))
    sheet.to_pil().save(os.path.join(FONTS, "pixel_font.png"))
    lines = [
        'info face="ArenaPixel" size=11 bold=0 italic=0 charset="" unicode=1 stretchH=100 '
        'smooth=0 aa=0 padding=0,0,0,0 spacing=1,1 outline=0',
        f"common lineHeight={CELL_H} base=9 scaleW={sheet.w} scaleH={sheet.h} pages=1 packed=0 "
        "alphaChnl=0 redChnl=4 greenChnl=4 blueChnl=4",
        'page id=0 file="pixel_font.png"',
    ]
    char_lines = [f"char id=32 x=0 y=0 width=0 height=0 xoffset=0 yoffset=0 xadvance=4 page=0 chnl=15"]
    for ch, x0, y0, w in entries:
        ids = {ord(ch)}
        low = ch.lower()
        if low != ch and len(low) == 1:
            ids.add(ord(low))
        for cid in sorted(ids):
            char_lines.append(f"char id={cid} x={x0} y={y0} width={w} height={CELL_H} xoffset=0 "
                              f"yoffset=0 xadvance={w + 1} page=0 chnl=15")
    lines.append(f"chars count={len(char_lines)}")
    lines += char_lines
    with open(os.path.join(FONTS, "pixel_font.fnt"), "w") as fh:
        fh.write("\n".join(lines) + "\n")
    # also keep an editable aseprite copy of the font sheet
    aseprite.write(os.path.join(ART, "pixel_font.aseprite"), [sheet], [100], [])
    print(f"  font: {len(entries)} glyphs")
    return bitmaps


def render_text(bitmaps, text, scale):
    widths = [bitmaps[c][1] if c != " " else 3 for c in text]
    w = sum(widths) + len(text) - 1
    img = Img(w * scale, CELL_H * scale)
    x = 0
    for c, cw in zip(text, widths):
        if c != " ":
            rows, _ = bitmaps[c]
            for y, r in enumerate(rows):
                for gx, px in enumerate(r):
                    if px == "#":
                        img.rect((x + gx) * scale, y * scale, scale, scale, P["white"])
        x += cw + 1
    return img


def gradient_text(mask, top, bottom, y0, y1):
    out = Img(mask.w, mask.h)
    for y in range(mask.h):
        t = min(1, max(0, (y - y0) / max(1, (y1 - y0))))
        col = lerp_color(top, bottom, t)
        for x in range(mask.w):
            if mask.get(x, y)[3]:
                out.set(x, y, col)
    return out


def build_logo(bitmaps):
    scale = 4
    top = render_text(bitmaps, "ARENA", scale)
    bottom = render_text(bitmaps, "SURVIVOR", scale)
    cap0, cap1 = CAP_TOP * scale, (CAP_TOP + 7) * scale
    top = gradient_text(top, P["yellow"], P["orange"], cap0, cap1)
    bottom = gradient_text(bottom, P["salmon"], P["darkred"], cap0, cap1)
    # highlight line on top of each glyph row
    w = max(top.w, bottom.w) + 16
    h = 2 * 7 * scale + 30
    logo = Img(w, h)

    def stamp(img, ox, oy):
        # thick outline + drop shadow
        shadow = Img(img.w, img.h)
        for y in range(img.h):
            for x in range(img.w):
                if img.get(x, y)[3]:
                    shadow.set(x, y, P["outline"])
        for dx in range(-2, 3):
            for dy in range(-2, 5):
                logo.paste(shadow, ox + dx, oy + dy)
        logo.paste(img, ox, oy)

    stamp(top, (w - top.w) // 2, 4 - cap0)
    stamp(bottom, (w - bottom.w) // 2, 4 + 7 * scale + 10 - cap0)
    # crossed swords ornament between the words
    cy = 4 + 7 * scale + 4
    for x in range(8, w - 8):
        if (w // 2 - top.w // 2 - 4) > x or x > (w // 2 + top.w // 2 + 4):
            logo.set(x, cy, P["gold"])
            logo.set(x, cy + 1, P["darkbrown"])
    save("logo", [logo], [100], [], out_dir=UI)


def build_project_icon(player_frame):
    img = Img(64, 64)
    for y in range(64):
        for x in range(64):
            d = math.hypot(x + 0.5 - 32, y + 0.5 - 32)
            if d < 30:
                img.set(x, y, P["green"] if dither(x, y, 0.6) else P["forest"])
            elif d < 32:
                img.set(x, y, P["outline"])
    p = player_frame.scaled(3)
    img.paste(p, 8, 6)
    img.to_pil().save(os.path.join(ROOT, "assets", "icon.png"))


def main():
    print("Building Arena Survivor art...")
    pf = build_player()
    build_bat()
    build_slime()
    build_skeleton()
    build_ghost()
    build_ogre()
    build_bolt()
    build_knife()
    build_aura()
    build_poof()
    build_shadow()
    build_pickups()
    build_tileset()
    build_icons()
    build_gui()
    bm = build_font()
    build_logo(bm)
    build_project_icon(pf)
    # round-trip check of every .aseprite we wrote
    for f in sorted(os.listdir(ART)):
        if f.endswith(".aseprite"):
            aseprite.read(os.path.join(ART, f))
    print("Done.")


if __name__ == "__main__":
    main()
