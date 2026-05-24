#!/usr/bin/env python3
"""
把两张「多款美食」网格图切成 10 张单图，并把浅灰/浅蓝灰底变成白底。
用法（在项目根目录）:
  pip install Pillow
  python scripts/split_reward_images.py path/to/image1.png path/to/image2.png
  或把两张图放到 scripts/reward_sources/ 下，命名为 01_cakes.png 和 02_sandwiches.png 后运行:
  python scripts/split_reward_images.py
输出到 Morning60s/Assets.xcassets 下 Reward01.imageset ... Reward10.imageset
"""
import os
import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("请先安装 Pillow: pip install Pillow")
    sys.exit(1)

# 默认：项目根目录
ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "Morning60s" / "Assets.xcassets"
SOURCES = ROOT / "scripts" / "reward_sources"

# 背景色容差：RGB 都大于此值视为背景，替换为纯白
BG_THRESHOLD = 215
# 每张源图切 2 列 x 3 行 = 6 张，共 12 张，取前 10 张作为「10 款普通奖励」
ROWS, COLS = 3, 2
TOTAL_REWARDS = 10


def make_white_bg(img: Image.Image) -> Image.Image:
    """把接近浅灰/浅蓝灰的像素改成纯白"""
    img = img.convert("RGBA")
    w, h = img.size
    data = list(img.getdata())
    new_data = []
    for (r, g, b, a) in data:
        if r >= BG_THRESHOLD and g >= BG_THRESHOLD and b >= BG_THRESHOLD:
            new_data.append((255, 255, 255, a))
        else:
            new_data.append((r, g, b, a))
    img.putdata(new_data)
    return img.convert("RGB")


def split_grid(img: Image.Image):
    """按 3 行 2 列切成 6 块"""
    w, h = img.size
    cw, ch = w // COLS, h // ROWS
    for row in range(ROWS):
        for col in range(COLS):
            left = col * cw
            top = row * ch
            yield img.crop((left, top, left + cw, top + ch))


def main():
    if len(sys.argv) >= 3:
        path1 = Path(sys.argv[1])
        path2 = Path(sys.argv[2])
    else:
        path1 = SOURCES / "01_cakes.png"
        path2 = SOURCES / "02_sandwiches.png"
        if not path1.exists() or not path2.exists():
            path1 = SOURCES / "unnamed.jpg"
            path2 = SOURCES / "unnamed-2.jpg"
        if not path1.exists() or not path2.exists():
            print("用法: python scripts/split_reward_images.py <图1> <图2>")
            print("或把 01_cakes.png 和 02_sandwiches.png（或 unnamed.jpg / unnamed-2.jpg）放到 scripts/reward_sources/ 后直接运行")
            sys.exit(1)

    ASSETS.mkdir(parents=True, exist_ok=True)
    index = 0
    for path in (path1, path2):
        img = Image.open(path).convert("RGB")
        img = make_white_bg(img)
        for tile in split_grid(img):
            if index >= TOTAL_REWARDS:
                break
            index += 1
            name = f"Reward{index:02d}"
            imageset = ASSETS / f"{name}.imageset"
            imageset.mkdir(parents=True, exist_ok=True)
            out_png = imageset / f"{name}.png"
            tile.save(out_png, "PNG")
            # Contents.json for Xcode
            contents = {
                "images": [{"filename": f"{name}.png", "idiom": "universal", "scale": "1x"}],
                "info": {"author": "xcode", "version": 1},
            }
            import json
            (imageset / "Contents.json").write_text(json.dumps(contents, indent=2), encoding="utf-8")
            print("Written", out_png)
        if index >= TOTAL_REWARDS:
            break

    print("Done. 共生成", min(index, TOTAL_REWARDS), "张图，白底已处理。")


if __name__ == "__main__":
    main()
