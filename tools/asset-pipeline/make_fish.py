# Draws the extra fish sprites of the fish book (2026-11-22), our own pixel art: 27x17 RGBA,
# facing left like the other sprites, dark outline, light belly, pattern per species.
# Usage: python3 make_fish.py OUT_DIR FIRST_NUMBER   -> fish_NN.png files.
import sys, math
from PIL import Image
W, H = 27, 17
out, first = sys.argv[1], int(sys.argv[2])

def hexc(s): s = s.lstrip('#'); return tuple(int(s[i:i+2], 16) for i in (0, 2, 4)) + (255,)
def shade(c, k): return tuple(max(0, min(255, int(v * k))) for v in c[:3]) + (255,)

def body_mask(kind):
    m = [[0] * W for _ in range(H)]
    cx, cy = 12.5, 8.0
    for y in range(H):
        for x in range(W):
            if kind == "eel":
                # Long wavy band.
                yc = 8 + 2.2 * math.sin(x * 0.45)
                if 1 <= x <= 25 and abs(y - yc) <= (2.2 if x < 22 else 1.2): m[y][x] = 1
                continue
            if kind == "flat":
                if ((x - 13) / 11.5) ** 2 + ((y - 8.5) / 6.2) ** 2 <= 1: m[y][x] = 1
                continue
            if kind == "round":
                if ((x - 11) / 8.5) ** 2 + ((y - 8) / 7.0) ** 2 <= 1: m[y][x] = 1
                continue
            rx, ry = (10.5, 4.3) if kind == "long" else ((9.0, 5.8) if kind == "deep" else (10.0, 4.8))
            if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1: m[y][x] = 1
    return m

def draw(spec):
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    px = img.load()
    base, belly, accent = hexc(spec["base"]), hexc(spec["belly"]), hexc(spec["accent"])
    kind = spec.get("kind", "normal")
    m = body_mask(kind)
    # Tail on the right (fish face left).
    tail = spec.get("tail", "fork")
    if kind not in ("eel", "flat"):
        tx = 21 if kind != "round" else 19
        for y in range(H):
            for x in range(tx, W):
                d = x - tx
                if tail == "fork" and (abs(y - 8) <= d * 0.9 and abs(y - 8) >= max(0, d - 3) * 0.8): m[y][x] = 2
                if tail == "round" and ((x - tx) / 5.0) ** 2 + ((y - 8) / (2 + d * 0.6)) ** 2 <= 1.2: m[y][x] = 2
                if tail == "big" and abs(y - 8) <= 1 + d * 1.1: m[y][x] = 2
    # Fins: dorsal on top, pectoral/anal below.
    fin = spec.get("fin", "low")
    if kind not in ("eel",):
        top = min(y for y in range(H) for x in range(W) if m[y][x] == 1)
        for x in range(8, 17 if fin != "long" else 21):
            h = 2 if fin == "low" else (3 if fin in ("high", "long") else 4)
            for k in range(1, h + 1):
                if fin == "spiky" and (x + k) % 2: continue
                yy = top + 1 - k + (1 if x in (8, 16) else 0)
                if 0 <= yy < H and m[yy][x] == 0 and (x - 8) < 9 - k: m[yy][x] = 3
        bot = max(y for y in range(H) for x in range(W) if m[y][x] == 1)
        for x in range(13, 17):
            if bot + 1 < H: m[bot + 1][x] = 3
        if spec.get("wing"):
            for y in range(4, 13):
                for x in range(9, 22):
                    if abs(y - 8) <= (x - 9) * 0.45 and m[y][x] == 0 and y < 8: m[y][x] = 3
    # Colors: body with belly gradient and pattern.
    for y in range(H):
        for x in range(W):
            v = m[y][x]
            if not v: continue
            if v == 1:
                c = base if y < 9 else belly
                if y == 9 or y == 8: c = tuple((a + b) // 2 for a, b in zip(base, belly))
                pat = spec.get("pattern", "")
                if pat == "stripes" and x % 4 == 0 and y < 11: c = accent
                if pat == "spots" and (x * 7 + y * 13) % 11 == 0: c = accent
                if pat == "band" and 9 <= x <= 11: c = accent
                if pat == "line" and y == 7: c = accent
                if pat == "dots" and (x + y) % 3 == 0 and y < 9: c = shade(base, 0.75)
                if pat == "redbelly" and y >= 9: c = accent
                if kind == "round" and pat == "spines" and (x + y) % 4 == 0: c = accent
                px[x, y] = c
            elif v == 2:
                px[x, y] = shade(accent if spec.get("tail_accent") else base, 0.85)
            else:
                px[x, y] = shade(accent if spec.get("fin_accent") else base, 0.8)
    # Dark outline around the shape.
    out_c = shade(base, 0.35)
    solid = [[px[x, y][3] > 0 for x in range(W)] for y in range(H)]
    for y in range(H):
        for x in range(W):
            if solid[y][x]: continue
            if any(0 <= x + dx < W and 0 <= y + dy < H and solid[y + dy][x + dx] for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                px[x, y] = out_c
    # Eye (front-left), mouth, gill line, extras.
    ex, ey = (5, 6) if kind not in ("round", "flat") else (6, 6)
    if kind == "eel": ex, ey = 3, int(8 + 2.2 * math.sin(3 * 0.45)) - 1
    px[ex, ey] = (255, 255, 255, 255); px[ex, ey + 1] = (20, 20, 25, 255); px[ex + 1, ey + 1] = (20, 20, 25, 255)
    if kind == "flat": px[ex + 2, ey - 1] = (255, 255, 255, 255); px[ex + 2, ey] = (20, 20, 25, 255)
    if kind not in ("eel",):
        for y in range(6, 11):
            if px[8, y][3] and m[y][8] == 1: px[8, y] = shade(px[8, y], 0.75)
    if spec.get("whiskers"):
        for k in range(3): px[max(0, 2 - k), 9 + k] = out_c; px[max(0, 2 - k), 7 + k] = out_c
    if spec.get("teeth"):
        for x in (2, 4): px[x, 9] = (250, 250, 250, 255)
    if spec.get("snout"):
        for x in range(0, 3): px[x, 8] = shade(base, 0.7)
    if spec.get("glow"):
        px[ex - 2 if ex > 2 else 0, ey - 3] = hexc(spec["accent"]); px[ex - 1, ey - 2] = shade(base, 0.5)
    return img

FISH = [
    {"base": "#9fb6c8", "belly": "#e8eef2", "accent": "#d0a040", "pattern": "line", "kind": "long"},           # lambari
    {"base": "#6a5a48", "belly": "#c8b89a", "accent": "#4a3a2a", "kind": "long", "whiskers": True, "tail": "round"},  # bagre
    {"base": "#b8b0a0", "belly": "#efe8dc", "accent": "#8a8070", "pattern": "dots"},                          # corvina
    {"base": "#3a6a9a", "belly": "#d8e4ee", "accent": "#20405a", "pattern": "line", "kind": "long"},          # anchova
    {"base": "#4a5a32", "belly": "#a8a878", "accent": "#2a3420", "pattern": "spots", "kind": "long", "teeth": True, "tail": "round"},  # traira
    {"base": "#5a5e66", "belly": "#e0884a", "accent": "#d06a3a", "kind": "deep", "pattern": "redbelly"},     # pacu
    {"base": "#8a9aa8", "belly": "#f0f2f4", "accent": "#202830", "pattern": "line", "kind": "long", "fin": "high"},  # robalo
    {"base": "#6a8a5a", "belly": "#f0d8d0", "accent": "#e07080", "pattern": "line", "fin_accent": False},   # truta arco-iris
    {"base": "#a08a6a", "belly": "#d8c8a8", "accent": "#7a6448", "kind": "flat", "pattern": "spots"},         # linguado
    {"base": "#7a8a94", "belly": "#e04a3a", "accent": "#e04a3a", "kind": "deep", "pattern": "redbelly", "teeth": True},  # piranha
    {"base": "#8a4a3a", "belly": "#c8886a", "accent": "#f0d0a0", "kind": "deep", "pattern": "spots", "fin": "spiky"},  # garoupa
    {"base": "#3a6ab0", "belly": "#d8e8f8", "accent": "#a8d0f0", "wing": True, "fin_accent": True},           # peixe-voador
    {"base": "#4a5a3a", "belly": "#8a9a6a", "accent": "#e0c040", "kind": "eel"},                               # enguia
    {"base": "#3a3a42", "belly": "#8a8a90", "accent": "#20202a", "whiskers": True, "tail": "round", "kind": "long"},  # peixe-gato
    {"base": "#c8c0b0", "belly": "#f2eee6", "accent": "#2a2a30", "pattern": "spots", "kind": "long", "whiskers": True},  # pintado
    {"base": "#3a4a3a", "belly": "#c8a060", "accent": "#202a20", "kind": "deep", "tail": "round"},            # tambaqui
    {"base": "#6a7078", "belly": "#c8ccd0", "accent": "#e8e8e0", "kind": "long", "snout": True, "pattern": "dots", "fin": "spiky"},  # esturjao
    {"base": "#c87a3a", "belly": "#e8b070", "accent": "#7a3a1a", "kind": "round", "pattern": "spines", "fin": "spiky", "tail": "round"},  # peixe-sapo
    {"base": "#4a5a4a", "belly": "#a8b098", "accent": "#d03a2a", "kind": "long", "tail": "big", "tail_accent": True, "pattern": "band"},  # pirarucu
    {"base": "#2a1a4a", "belly": "#6a3a8a", "accent": "#40f0e0", "fin": "spiky", "fin_accent": True, "tail_accent": True, "glow": True, "pattern": "line"},  # peixe-dragao
]
for i, spec in enumerate(FISH):
    draw(spec).save(f"{out}/fish_{first + i:02d}.png")
print("ok", len(FISH))
