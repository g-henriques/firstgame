"""Minimal reader/writer for the Aseprite (.aseprite/.ase) file format.

Spec: https://github.com/aseprite/aseprite/blob/main/docs/ase-file-specs.md

Writes RGBA sprites with one or more layers, frame durations, animation
tags and a palette, so every generated asset can be opened, edited and
re-exported from Aseprite itself (see tools/export_aseprite.sh).
"""
import struct
import zlib


def _string(s):
    data = s.encode("utf-8")
    return struct.pack("<H", len(data)) + data


def _chunk(chunk_type, payload):
    return struct.pack("<IH", len(payload) + 6, chunk_type) + payload


def _layer_chunk(name):
    # flags: visible | editable, type normal, child level 0, blend normal, opacity 255
    payload = struct.pack("<HHHHHHB3x", 3, 0, 0, 0, 0, 0, 255) + _string(name)
    return _chunk(0x2004, payload)


def _cel_chunk(layer_index, img):
    raw = bytearray()
    for px in img.pixels:
        raw.extend(px)
    payload = struct.pack("<HhhBHh5x", layer_index, 0, 0, 255, 2, 0)
    payload += struct.pack("<HH", img.w, img.h) + zlib.compress(bytes(raw), 9)
    return _chunk(0x2005, payload)


def _palette_chunk(colors):
    colors = colors[:256] or [(0, 0, 0, 0)]
    payload = struct.pack("<III8x", len(colors), 0, len(colors) - 1)
    for c in colors:
        payload += struct.pack("<HBBBB", 0, *c)
    return _chunk(0x2019, payload)


def _tags_chunk(tags):
    payload = struct.pack("<H8x", len(tags))
    for name, start, end in tags:
        payload += struct.pack("<HHBH6x3Bx", start, end, 0, 0, 0, 0, 0) + _string(name)
    return _chunk(0x2018, payload)


def write(path, frames, durations=None, tags=None, layer="Layer 1", palette=None):
    """frames: list of Img (all the same size). durations in ms."""
    w, h = frames[0].w, frames[0].h
    durations = durations or [100] * len(frames)
    if palette is None:
        seen = []
        for f in frames:
            for px in f.pixels:
                if px[3] and px not in seen:
                    seen.append(px)
        palette = [(0, 0, 0, 0)] + seen
    body = b""
    for i, frame in enumerate(frames):
        chunks = []
        if i == 0:
            chunks.append(_palette_chunk(palette))
            chunks.append(_layer_chunk(layer))
            if tags:
                chunks.append(_tags_chunk(tags))
        chunks.append(_cel_chunk(0, frame))
        data = b"".join(chunks)
        header = struct.pack("<IHHH2xI", len(data) + 16, 0xF1FA, min(len(chunks), 0xFFFF),
                             durations[i], len(chunks))
        body += header + data
    header = struct.pack("<IHHHHHIHIIB3xHBBhhHH84x",
                         128 + len(body), 0xA5E0, len(frames), w, h, 32, 1, 100, 0, 0,
                         0, len(palette), 1, 1, 0, 0, 16, 16)
    with open(path, "wb") as fh:
        fh.write(header + body)


def read(path):
    """Returns dict(width, height, frames=[{duration, cels:[(w,h,bytes)]}], tags, layers)."""
    with open(path, "rb") as fh:
        data = fh.read()
    size, magic, nframes, w, h, depth = struct.unpack_from("<IHHHHH", data, 0)
    assert magic == 0xA5E0 and size == len(data), "bad header"
    assert depth == 32
    pos = 128
    out = {"width": w, "height": h, "frames": [], "tags": [], "layers": []}
    for _ in range(nframes):
        fsize, fmagic, _old, dur, nchunks = struct.unpack_from("<IHHH2xI", data, pos)
        assert fmagic == 0xF1FA
        cpos = pos + 16
        frame = {"duration": dur, "cels": []}
        for _ in range(nchunks):
            csize, ctype = struct.unpack_from("<IH", data, cpos)
            payload = data[cpos + 6:cpos + csize]
            if ctype == 0x2004:
                n = struct.unpack_from("<H", payload, 16)[0]
                out["layers"].append(payload[18:18 + n].decode())
            elif ctype == 0x2005:
                cw, ch = struct.unpack_from("<HH", payload, 16)
                pixels = zlib.decompress(payload[20:])
                assert len(pixels) == cw * ch * 4
                frame["cels"].append((cw, ch, pixels))
            elif ctype == 0x2018:
                ntags = struct.unpack_from("<H", payload, 0)[0]
                p = 10
                for _ in range(ntags):
                    start, end = struct.unpack_from("<HH", payload, p)
                    p += 17
                    n = struct.unpack_from("<H", payload, p)[0]
                    out["tags"].append((payload[p + 2:p + 2 + n].decode(), start, end))
                    p += 2 + n
            cpos += csize
        assert cpos == pos + fsize
        out["frames"].append(frame)
        pos += fsize
    return out
