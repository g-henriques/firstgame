"""Tiny pixel-art toolkit used by build_art.py."""
import json
import math
import os
import random

from PIL import Image

CLEAR = (0, 0, 0, 0)


def hex_color(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


# Project palette (inspired by Endesga 32).
PAL = {
    "outline": hex_color("181425"),
    "navy": hex_color("262b44"),
    "slate": hex_color("3a4466"),
    "steel": hex_color("5a6988"),
    "silver": hex_color("8b9bb4"),
    "fog": hex_color("c0cbdc"),
    "white": hex_color("ffffff"),
    "red": hex_color("e43b44"),
    "darkred": hex_color("a22633"),
    "wine": hex_color("68386c"),
    "plum": hex_color("45283c"),
    "pink": hex_color("b55088"),
    "salmon": hex_color("f6757a"),
    "orange": hex_color("f77622"),
    "gold": hex_color("feae34"),
    "yellow": hex_color("fee761"),
    "lime": hex_color("63c74d"),
    "green": hex_color("3e8948"),
    "forest": hex_color("265c42"),
    "pine": hex_color("193c3e"),
    "mint": hex_color("a8e070"),
    "blue": hex_color("0099db"),
    "cyan": hex_color("2ce8f5"),
    "deepblue": hex_color("124e89"),
    "brown": hex_color("733e39"),
    "darkbrown": hex_color("3e2731"),
    "rust": hex_color("be4a2f"),
    "clay": hex_color("d77643"),
    "tan": hex_color("e4a672"),
    "sand": hex_color("ead4aa"),
    "skin": hex_color("e8b796"),
    "skinshade": hex_color("c28569"),
}


class Img:
    def __init__(self, w, h, fill=CLEAR):
        self.w, self.h = w, h
        self.pixels = [fill] * (w * h)

    def copy(self):
        c = Img(self.w, self.h)
        c.pixels = list(self.pixels)
        return c

    def get(self, x, y):
        if 0 <= x < self.w and 0 <= y < self.h:
            return self.pixels[y * self.w + x]
        return CLEAR

    def set(self, x, y, c):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.pixels[y * self.w + x] = c

    def blend(self, x, y, c):
        """Alpha-composite c over the pixel."""
        if not (0 <= x < self.w and 0 <= y < self.h) or c[3] == 0:
            return
        dst = self.get(x, y)
        a = c[3] / 255
        da = dst[3] / 255
        oa = a + da * (1 - a)
        if oa == 0:
            return
        rgb = tuple(int((c[i] * a + dst[i] * da * (1 - a)) / oa) for i in range(3))
        self.set(x, y, rgb + (int(oa * 255),))

    def paste(self, other, ox, oy):
        for y in range(other.h):
            for x in range(other.w):
                px = other.get(x, y)
                if px[3]:
                    self.blend(ox + x, oy + y, px)

    def rect(self, x0, y0, w, h, c):
        for y in range(y0, y0 + h):
            for x in range(x0, x0 + w):
                self.set(x, y, c)

    def shifted(self, dx, dy):
        out = Img(self.w, self.h)
        for y in range(self.h):
            for x in range(self.w):
                out.set(x + dx, y + dy, self.get(x, y))
        return out

    def flipped(self):
        out = Img(self.w, self.h)
        for y in range(self.h):
            for x in range(self.w):
                out.set(self.w - 1 - x, y, self.get(x, y))
        return out

    def scaled(self, s):
        out = Img(self.w * s, self.h * s)
        for y in range(out.h):
            for x in range(out.w):
                out.set(x, y, self.get(x // s, y // s))
        return out

    def to_pil(self):
        im = Image.new("RGBA", (self.w, self.h))
        im.putdata(self.pixels)
        return im


def from_ascii(rows, colors, w=None, h=None, ox=0, oy=0):
    """Build an image from ASCII art. '.' and ' ' are transparent."""
    w = w or max(len(r) for r in rows)
    h = h or len(rows)
    img = Img(w, h)
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch in ". ":
                continue
            if ch not in colors:
                raise KeyError(f"unknown colour key {ch!r} in row {row!r}")
            img.set(ox + x, oy + y, colors[ch])
    return img


def mirror(half_rows):
    """Left-half ascii rows -> symmetric full rows."""
    return [r + r[::-1] for r in half_rows]


def outline(img, color=PAL["outline"], diagonal=False):
    out = img.copy()
    for y in range(img.h):
        for x in range(img.w):
            if img.get(x, y)[3]:
                continue
            n = [(1, 0), (-1, 0), (0, 1), (0, -1)]
            if diagonal:
                n += [(1, 1), (-1, -1), (1, -1), (-1, 1)]
            if any(img.get(x + dx, y + dy)[3] > 0 for dx, dy in n):
                out.set(x, y, color)
    return out


def ellipse(img, cx, cy, rx, ry, c, filled=True):
    for y in range(img.h):
        for x in range(img.w):
            d = ((x + 0.5 - cx) / rx) ** 2 + ((y + 0.5 - cy) / ry) ** 2
            if filled and d <= 1:
                img.set(x, y, c)
            elif not filled and 0.75 <= d <= 1:
                img.set(x, y, c)


def lerp_color(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(4))


def with_alpha(c, a):
    return c[:3] + (a,)


BAYER4 = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]


def dither(x, y, t):
    """True when ordered-dither threshold says 'on' for intensity t in [0,1]."""
    return t * 16 > BAYER4[y % 4][x % 4] + 0.5


def strip(frames):
    w, h = frames[0].w, frames[0].h
    out = Img(w * len(frames), h)
    for i, f in enumerate(frames):
        out.paste(f, i * w, 0)
    return out


def save_sheet(name, frames, durations, tags, sprites_dir, art_dir, aseprite_mod):
    """Saves art/<name>.aseprite and assets/sprites/<name>.png + .json
    (the json mirrors `aseprite --data --format json-array --list-tags`)."""
    os.makedirs(sprites_dir, exist_ok=True)
    os.makedirs(art_dir, exist_ok=True)
    aseprite_mod.write(os.path.join(art_dir, name + ".aseprite"), frames, durations, tags)
    sheet = strip(frames)
    sheet.to_pil().save(os.path.join(sprites_dir, name + ".png"))
    w, h = frames[0].w, frames[0].h
    data = {
        "frames": [
            {
                "filename": f"{name} {i}.aseprite",
                "frame": {"x": i * w, "y": 0, "w": w, "h": h},
                "rotated": False,
                "trimmed": False,
                "spriteSourceSize": {"x": 0, "y": 0, "w": w, "h": h},
                "sourceSize": {"w": w, "h": h},
                "duration": durations[i],
            }
            for i in range(len(frames))
        ],
        "meta": {
            "app": "https://www.aseprite.org/",
            "version": "1.3",
            "image": name + ".png",
            "format": "RGBA8888",
            "size": {"w": sheet.w, "h": sheet.h},
            "scale": "1",
            "frameTags": [
                {"name": t, "from": a, "to": b, "direction": "forward", "color": "#000000ff"}
                for t, a, b in tags
            ],
            "layers": [{"name": "Layer 1", "opacity": 255, "blendMode": "normal"}],
            "slices": [],
        },
    }
    with open(os.path.join(sprites_dir, name + ".json"), "w") as fh:
        json.dump(data, fh, indent=1)


def noise_rng(seed):
    return random.Random(seed)


def dist(ax, ay, bx, by):
    return math.hypot(ax - bx, ay - by)
