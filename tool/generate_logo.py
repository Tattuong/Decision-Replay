#!/usr/bin/env python3
"""Decision Replay — clean icon, subtle 3D, fixed replay badge."""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "logo.png"
OUT_FG = ROOT / "assets" / "icon_foreground.png"

S = 2048
OUT_SIZE = 1024

BLUE_CENTER = (59, 130, 246)
BLUE_EDGE = (29, 78, 216)
CREAM = (255, 253, 248)
CREAM_BACK = (252, 250, 245)
CREAM_EDGE = (214, 208, 198)
INDIGO = (37, 99, 235)
INDIGO_HI = (96, 165, 250)
LINE = (226, 232, 240)
GOLD_HI = (253, 224, 138)
GOLD_LO = (202, 138, 4)
WHITE = (255, 255, 255)


def lerp3(a: tuple[int, int, int], b: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))  # type: ignore[return-value]


def radial_bg() -> Image.Image:
    img = Image.new("RGB", (S, S))
    px = img.load()
    c = S / 2
    max_r = c * 1.05
    for y in range(S):
        for x in range(S):
            t = min(1.0, math.hypot(x - c, y - c) / max_r)
            px[x, y] = lerp3(BLUE_CENTER, BLUE_EDGE, t * 0.88)
    return img.convert("RGBA")


def cream_card_layer(x: float, y: float, w: float, h: float, r: float) -> Image.Image:
    card = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(card)
    d.rounded_rectangle([x, y, x + w, y + h], radius=r, fill=CREAM)
    d.rounded_rectangle([x + 1, y + 1, x + w - 1, y + h - 1], radius=r - 1, outline=(240, 236, 228), width=2)
    hi = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    hd = ImageDraw.Draw(hi)
    hd.rounded_rectangle([x + 4, y + 4, x + w - 4, y + h * 0.35], radius=r * 0.5, fill=(255, 255, 255, 28))
    return Image.alpha_composite(card, hi)


def build_replay_badge(r: float) -> Image.Image:
    pad = int(r * 1.45)
    size = pad * 2
    cx = cy = pad
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))

    for y in range(size):
        for x in range(size):
            dx, dy = x - cx, y - cy
            dist = math.hypot(dx, dy)
            if dist <= r:
                t = min(1.0, (y / size) * 0.65 + (x / size) * 0.35 + (1 - dist / r) * 0.15)
                img.putpixel((x, y), lerp3(GOLD_HI, GOLD_LO, t) + (255,))

    d = ImageDraw.Draw(img)
    d.ellipse([cx - r + 1, cy - r + 2, cx + r + 1, cy + r + 2], outline=(120, 80, 0, 60), width=max(1, int(r * 0.04)))

    font_size = int(r * 1.15)
    font = None
    for path in (
        "/System/Library/Fonts/SFNSRounded.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
        "/Library/Fonts/Arial Unicode.ttf",
    ):
        try:
            font = ImageFont.truetype(path, font_size)
            break
        except OSError:
            continue
    if font is None:
        font = ImageFont.load_default()

    d.text((cx, cy - r * 0.02), "\u21bb", font=font, fill=WHITE, anchor="mm")
    return img


def compose(*, with_bg: bool) -> Image.Image:
    canvas = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    if with_bg:
        canvas.alpha_composite(radial_bg())

    nw, nh = S * 0.48, S * 0.54
    nx = (S - nw) / 2
    ny = (S - nh) / 2
    nr = nw * 0.12

    shadow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle([nx + 6, ny + 12, nx + nw + 10, ny + nh + 14], radius=nr, fill=(15, 23, 42, 85))
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(16)))

    back = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    bd = ImageDraw.Draw(back)
    bd.rounded_rectangle([nx + 5, ny + 5, nx + nw + 5, ny + nh + 5], radius=nr, fill=CREAM_BACK + (255,))
    canvas.alpha_composite(back)
    canvas.alpha_composite(cream_card_layer(nx, ny, nw, nh, nr))

    content = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(content)
    pad = nw * 0.14
    bar_h = nh * 0.12
    d.rounded_rectangle([nx + pad, ny + pad, nx + nw - pad, ny + pad + bar_h], radius=bar_h * 0.3, fill=INDIGO)
    d.rounded_rectangle([nx + pad, ny + pad + bar_h * 0.72, nx + nw - pad, ny + pad + bar_h], radius=bar_h * 0.12, fill=(29, 78, 216))

    yy = ny + pad + bar_h + nh * 0.1
    d.rounded_rectangle([nx + pad, yy, nx + nw - pad, yy + nh * 0.05], radius=nh * 0.025, fill=LINE)
    yy += nh * 0.11
    d.rounded_rectangle([nx + pad, yy, nx + nw - pad * 2.2, yy + nh * 0.05], radius=nh * 0.025, fill=LINE)
    canvas.alpha_composite(content)

    br = nw * 0.105
    bx = nx + nw - pad * 0.88
    by = ny + nh - pad * 0.88
    badge = build_replay_badge(br)
    bpad = int(br * 1.45)
    bsh = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    bsd = ImageDraw.Draw(bsh)
    bsd.ellipse([bx - br + 2, by - br + 4, bx + br + 2, by + br + 4], fill=(15, 23, 42, 75))
    canvas.alpha_composite(bsh.filter(ImageFilter.GaussianBlur(5)))
    canvas.paste(badge, (int(bx - bpad), int(by - bpad)), badge)

    return canvas.resize((OUT_SIZE, OUT_SIZE), Image.Resampling.LANCZOS)


def main() -> None:
    OUT.parent.mkdir(parents=True, exist_ok=True)
    compose(with_bg=True).convert("RGB").save(OUT, "PNG", optimize=True)
    compose(with_bg=False).save(OUT_FG, "PNG", optimize=True)
    print(f"Saved {OUT}")


if __name__ == "__main__":
    main()
