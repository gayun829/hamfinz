"""상점 옷·악세서리 PNG를 원본 완성형 스킨 위치에 맞춘다.

각 부품은 design/shop-svg에서 정렬한 완성형 스킨에서 잘라낸 그림이다.
완성형 스킨 SVG를 768×768로 그린 뒤 부품 PNG를 같은 자리로 옮기는
정수 픽셀 이동량을 템플릿 매칭으로 찾는다. 모든 햄핀 스킨은 눈 위치가 같아
완성형 스킨 좌표가 곧 기본 몸 좌표다.

    python scripts/align_shop_layers.py           # 이동량만 출력
    python scripts/align_shop_layers.py --apply   # PNG를 이동해 덮어쓰기
    python scripts/align_shop_layers.py --sheet out.png  # 기본 몸 착용 미리보기

필요 패키지: pillow, numpy, resvg-py
"""

import argparse
import io
import sys
from pathlib import Path

import numpy as np
import resvg_py
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
PARTS = ROOT / 'assets/figma/shop/accessories'
SKINS = ROOT / 'assets/figma/shop/skins'
SIZE = 768
SEARCH = 14
# 머리 장식과 옷이 한 파일에 있으면 이 y를 기준으로 나눠 따로 맞춘다.
SPLIT_Y = 420
WHOLE, HEAD, BODY = (0, SIZE), (0, SPLIT_Y), (SPLIT_Y, SIZE)

# 부품 → (기준 완성형 스킨, 맞출 영역들). 지니 옷·수염은 완성형과 그림이
# 달라 매칭하지 않는다.
TARGETS = {
    'clothing_ninja': ('skin_ninja', [WHOLE]),
    'accessory_ninja': ('skin_ninja', [WHOLE]),
    'clothing_kindergarten': ('skin_kindergarten', [WHOLE]),
    'accessory_kindergarten_hat': ('skin_kindergarten', [WHOLE]),
    'accessory_kindergarten_hair': ('skin_kindergarten', [HEAD, BODY]),
    'accessory_kindergarten': ('skin_kindergarten', [HEAD, BODY]),
    'accessory_genie_hair': ('skin_genie', [HEAD]),
    'accessory_genie_set': ('skin_genie', [HEAD]),
    'accessory_perm': ('skin_perm', [WHOLE]),
    'accessory_grandma': ('skin_grandma', [WHOLE]),
    'accessory_tie': ('skin_business', [WHOLE]),
}


def render_skin(name):
    png = resvg_py.svg_to_bytes(
        svg_path=str(SKINS / f'{name}.svg'), width=SIZE, height=SIZE)
    return np.asarray(Image.open(io.BytesIO(bytes(png))).convert('RGBA'))


def shift(a, dx, dy):
    out = np.zeros_like(a)
    h, w = a.shape[:2]
    out[max(dy, 0):h + min(dy, 0), max(dx, 0):w + min(dx, 0)] = \
        a[max(-dy, 0):h + min(-dy, 0), max(-dx, 0):w + min(-dx, 0)]
    return out


def best_offset(part, ref):
    """부품의 불투명 픽셀이 기준 스킨 색과 가장 비슷해지는 (dx, dy)."""
    alpha = part[..., 3] > 200
    if alpha.sum() < 50:
        return 0, 0, 0.0, 0.0
    ys, xs = np.nonzero(alpha)
    y0, y1 = max(ys.min() - SEARCH, 0), min(ys.max() + SEARCH + 1, SIZE)
    x0, x1 = max(xs.min() - SEARCH, 0), min(xs.max() + SEARCH + 1, SIZE)
    p = part[y0:y1, x0:x1].astype(np.float32)
    r = ref[y0:y1, x0:x1].astype(np.float32)

    def error(dx, dy):
        moved = shift(p, dx, dy)
        mask = moved[..., 3] > 200
        color = np.abs(moved[..., :3][mask] - r[..., :3][mask]).mean()
        uncovered = (r[..., 3][mask] < 200).mean() * 255
        return color + uncovered

    err, dx, dy = min(
        (error(dx, dy), dx, dy)
        for dy in range(-SEARCH, SEARCH + 1)
        for dx in range(-SEARCH, SEARCH + 1))
    return dx, dy, error(0, 0), err


def region(img, rows):
    out = np.zeros_like(img)
    out[rows[0]:rows[1]] = img[rows[0]:rows[1]]
    return out


def align(apply):
    refs = {}
    for name, (skin, regions) in TARGETS.items():
        path = PARTS / f'{name}.png'
        part = np.asarray(Image.open(path).convert('RGBA'))
        if part.shape[:2] != (SIZE, SIZE):
            sys.exit(f'{path.name}: {part.shape[1]}x{part.shape[0]}, expected {SIZE}x{SIZE}')
        ref = refs.setdefault(skin, render_skin(skin))
        result = part.copy()
        moved = False
        for rows in regions:
            piece = region(part, rows)
            dx, dy, before, after = best_offset(piece, ref)
            label = {WHOLE: 'all', HEAD: 'head', BODY: 'body'}[rows]
            print(f'{name:28s} {label:4s} dx={dx:+3d} dy={dy:+3d}  '
                  f'error {before:5.1f} -> {after:5.1f}')
            if dx or dy:
                moved = True
                result[rows[0]:rows[1]] = 0
                # 아래 영역이 위로 올라오는 경우를 위해 이동한 조각은 합성한다.
                layer = Image.fromarray(result)
                layer.alpha_composite(Image.fromarray(shift(piece, dx, dy)))
                result = np.asarray(layer).copy()
        if apply and moved:
            Image.fromarray(result).save(path, optimize=True)


def sheet(out):
    body = Image.fromarray(render_skin('skin_default'))
    names = sorted(p.stem for p in PARTS.glob('*.png'))
    cols, tw, th = 5, 260, 300
    rows = (len(names) + cols - 1) // cols
    canvas = Image.new('RGB', (cols * tw, rows * th), 'white')
    draw = ImageDraw.Draw(canvas)
    for i, name in enumerate(names):
        im = Image.new('RGBA', (SIZE, SIZE), (255, 255, 255, 255))
        im.alpha_composite(body)
        im.alpha_composite(Image.open(PARTS / f'{name}.png').convert('RGBA'))
        x, y = (i % cols) * tw, (i // cols) * th
        canvas.paste(im.crop((190, 150, 580, 600)).resize((tw, th)), (x, y))
        draw.text((x + 4, y + 4), name, fill='black')
    canvas.save(out)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--apply', action='store_true')
    parser.add_argument('--sheet')
    args = parser.parse_args()
    if args.sheet:
        sheet(args.sheet)
    else:
        align(args.apply)
