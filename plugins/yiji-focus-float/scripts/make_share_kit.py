from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageOps, ImageFilter


ROOT = Path("/Users/jingyuanwang/Documents/New project/plugins/yiji-focus-float")
SHARE_DIR = ROOT / "share-kit"
ASSET = ROOT / "prototype/assets/yiji-share-redraw-strong.png"

CARD_W = 1600
CARD_H = 1200
OUTER_PAD = 92

BG = (248, 242, 229)
INK = (40, 57, 50)
SUB = (99, 115, 107)
PANEL = (255, 250, 243)
BORDER = (230, 210, 176)
LINE = (224, 214, 198)
SHADOW = (193, 180, 150, 70)


def font(size: int, bold: bool = False):
    if bold:
      candidates = [
          "/System/Library/Fonts/PingFang.ttc",
          "/System/Library/Fonts/Supplemental/Arial Unicode.ttf",
      ]
    else:
      candidates = [
          "/System/Library/Fonts/PingFang.ttc",
          "/System/Library/Fonts/Supplemental/Arial Unicode.ttf",
      ]
    for path in candidates:
        try:
            return ImageFont.truetype(path, size=size)
        except OSError:
            continue
    return ImageFont.load_default()


def make_canvas():
    return Image.new("RGBA", (CARD_W, CARD_H), BG + (255,))


def round_rect(draw, box, radius, fill, outline=None, width=1):
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def add_shadow(base: Image.Image, box, radius=18, expand=24):
    x0, y0, x1, y1 = box
    shadow = Image.new("RGBA", (CARD_W, CARD_H), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(shadow)
    sdraw.rounded_rectangle(
        (x0 + 8, y0 + 18, x1 + 8, y1 + 18),
        radius=radius,
        fill=SHADOW,
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(expand // 3))
    base.alpha_composite(shadow)


def add_title(draw, chapter, title, subtitle):
    draw.text((OUTER_PAD, 72), chapter, fill=(47, 116, 96), font=font(28))
    draw.text((OUTER_PAD, 118), title, fill=INK, font=font(78, bold=True))
    draw.text((OUTER_PAD, 248), subtitle, fill=SUB, font=font(34))


def load_pet(max_w=190, max_h=230):
    image = Image.open(ASSET).convert("RGBA")
    matte = Image.new("RGBA", image.size, BG + (255,))
    matte.alpha_composite(image)
    bbox = image.getchannel("A").getbbox()
    if bbox is not None:
        pad = 2
        x0 = max(0, bbox[0] - pad)
        y0 = max(0, bbox[1] - pad)
        x1 = min(image.width, bbox[2] + pad)
        y1 = min(image.height, bbox[3] + pad)
        matte = matte.crop((x0, y0, x1, y1))
    image = matte
    image.thumbnail((max_w, max_h), Image.Resampling.NEAREST)
    return image


def paste_pet(base: Image.Image, x: int, y: int, scale_w=190, scale_h=230):
    pet = load_pet(scale_w, scale_h)
    base.alpha_composite(pet, (x, y))


def bubble(draw, box, pointer_x, fill=PANEL):
    round_rect(draw, box, 22, fill, outline=BORDER, width=2)
    px = pointer_x
    y = box[3]
    draw.polygon(
        [(px - 18, y), (px + 6, y), (px - 6, y + 18)],
        fill=fill,
        outline=BORDER,
    )


def chip(draw, box, text, fill, text_fill=(43, 56, 52)):
    round_rect(draw, box, 18, fill)
    bbox = draw.textbbox((0, 0), text, font=font(24, bold=True))
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    draw.text(
        (box[0] + (box[2] - box[0] - tw) / 2, box[1] + (box[3] - box[1] - th) / 2 - 3),
        text,
        fill=text_fill,
        font=font(24, bold=True),
    )


def chapter_start():
    img = make_canvas()
    draw = ImageDraw.Draw(img)
    add_title(draw, "CHAPTER 01", "双击一姬，今天开工", "选一个任务，轻轻开始，不用想太多。")
    panel = (OUTER_PAD, 365, CARD_W - OUTER_PAD - 260, CARD_H - 110)
    add_shadow(img, panel)
    bubble(draw, panel, panel[2] - 90)
    draw.text((panel[0] + 34, panel[1] + 34), "喵，离accept更近一步", fill=INK, font=font(42, bold=True))
    draw.text((panel[0] + 36, panel[1] + 92), "点一下就开始计时。", fill=SUB, font=font(28))
    tasks = ["开组会", "seminar", "读文献", "洗数据", "做模型", "写论文", "娱乐", "饭饭", "运动", "家庭生活"]
    fills = [
        (210, 232, 228), (233, 219, 195), (214, 233, 207), (211, 229, 243), (233, 213, 239),
        (244, 229, 170), (242, 213, 220), (243, 223, 193), (210, 235, 217), (224, 217, 247)
    ]
    sx = panel[0] + 48
    sy = panel[1] + 176
    w = 328
    h = 62
    gap_x = 52
    gap_y = 36
    for idx, task in enumerate(tasks):
        row = idx // 2
        col = idx % 2
        x = sx + col * (w + gap_x)
        y = sy + row * (h + gap_y)
        chip(draw, (x, y, x + w, y + h), task, fills[idx])
    paste_pet(img, CARD_W - 330, CARD_H - 360, 210, 250)
    return img


def chapter_reminders():
    img = make_canvas()
    draw = ImageDraw.Draw(img)
    add_title(draw, "CHAPTER 02", "一姬很安静，只在该提醒时提醒", "不开工时久没动，或娱乐太久，才会轻轻冒头叫你。")
    pet_x = CARD_W - 330
    pet_y = CARD_H - 310
    paste_pet(img, pet_x, pet_y, 210, 250)
    bubble_one = (OUTER_PAD + 40, 430, CARD_W - 300, 650)
    add_shadow(img, bubble_one)
    bubble(draw, bubble_one, bubble_one[2] - 130)
    draw.text((bubble_one[0] + 32, bubble_one[1] + 34), "20 分钟没动键鼠", fill=INK, font=font(36, bold=True))
    draw.text((bubble_one[0] + 32, bubble_one[1] + 90), "喵，人在干什么？", fill=SUB, font=font(28))
    bubble_two = (OUTER_PAD + 120, 700, CARD_W - 180, 940)
    add_shadow(img, bubble_two)
    bubble(draw, bubble_two, bubble_two[2] - 210)
    draw.text((bubble_two[0] + 32, bubble_two[1] + 34), "娱乐超过 1 小时", fill=INK, font=font(36, bold=True))
    draw.text((bubble_two[0] + 32, bubble_two[1] + 90), "喵，不是说好要带咪发AER的吗？", fill=SUB, font=font(28))
    return img


def chapter_wrapup():
    img = make_canvas()
    draw = ImageDraw.Draw(img)
    add_title(draw, "CHAPTER 03", "双击收尾，今天就有战果", "结束一段时补两句，Done Today 会慢慢长成你自己的小日历。")
    panel = (OUTER_PAD, 350, CARD_W - OUTER_PAD - 260, CARD_H - 120)
    add_shadow(img, panel)
    bubble(draw, panel, panel[2] - 110)
    draw.text((panel[0] + 32, panel[1] + 34), "运动 结束啦", fill=INK, font=font(38, bold=True))
    draw.text((panel[0] + 32, panel[1] + 84), "补一句成果就收工。", fill=SUB, font=font(26))
    draw.text((panel[0] + 32, panel[1] + 150), "这一段做成了什么", fill=SUB, font=font(24))
    round_rect(draw, (panel[0] + 32, panel[1] + 184, panel[2] - 32, panel[1] + 236), 18, (255, 255, 255), outline=LINE, width=2)
    draw.text((panel[0] + 48, panel[1] + 196), "把今天的运动做完了。", fill=(117, 127, 120), font=font(24))
    draw.text((panel[0] + 32, panel[1] + 274), "感觉如何", fill=SUB, font=font(24))
    round_rect(draw, (panel[0] + 32, panel[1] + 308, panel[2] - 32, panel[1] + 360), 18, (255, 255, 255), outline=LINE, width=2)
    draw.text((panel[0] + 48, panel[1] + 320), "舒服很多，脑子清醒了。", fill=(117, 127, 120), font=font(24))
    chip(draw, (panel[0] + 34, panel[3] - 66, panel[0] + 154, panel[3] - 12), "继续", (239, 229, 211))
    chip(draw, (panel[0] + 170, panel[3] - 66, panel[0] + 324, panel[3] - 12), "喵，人好棒！", (56, 125, 97), (255, 255, 255))
    paste_pet(img, CARD_W - 325, CARD_H - 355, 210, 250)
    return img


def chapter_review():
    img = make_canvas()
    draw = ImageDraw.Draw(img)
    add_title(draw, "CHAPTER 04", "Done Today / Done This Week", "点开就能看今天和这周，像一份只属于你的电脑小日历。")
    panel = (OUTER_PAD, 365, CARD_W - OUTER_PAD, CARD_H - 100)
    add_shadow(img, panel)
    round_rect(draw, panel, 24, PANEL, outline=BORDER, width=2)
    chip(draw, (panel[0] + 42, panel[1] + 40, panel[0] + 314, panel[1] + 104), "Done Today", (210, 229, 245))
    chip(draw, (panel[0] + 342, panel[1] + 40, panel[0] + 668, panel[1] + 104), "Done This Week", (227, 219, 247))
    left = panel[0] + 54
    top = panel[1] + 155
    col_w = 178
    gap = 22
    days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    for idx, day in enumerate(days):
        x = left + idx * (col_w + gap)
        round_rect(draw, (x, top, x + col_w, top + 455), 16, (255, 255, 255), outline=LINE, width=1)
        draw.text((x + 18, top + 18), day, fill=(53, 66, 61), font=font(24, bold=True))
        for line in range(1, 9):
            y = top + 18 + line * 48
            draw.line((x + 16, y, x + col_w - 16, y), fill=LINE, width=2)
    events = [
        ("洗数据", "Tue 10:00", 1, 140, (209, 229, 243)),
        ("写论文", "Wed 15:00", 2, 350, (246, 230, 167)),
        ("开组会", "Fri 13:30", 4, 255, (210, 232, 228)),
        ("娱乐", "Sat 20:00", 5, 455, (243, 213, 220)),
    ]
    for label, time_text, col, y, fill in events:
        x = left + col * (col_w + gap) + 16
        round_rect(draw, (x, top + y, x + col_w - 36, top + y + 86), 18, fill)
        draw.text((x + 16, top + y + 14), label, fill=(53, 66, 61), font=font(22, bold=True))
        draw.text((x + 16, top + y + 48), time_text, fill=(77, 91, 84), font=font(18))
    paste_pet(img, panel[2] - 330, panel[3] - 275, 190, 220)
    return img


def stitch(images):
    gap = 56
    width = max(image.width for image in images)
    height = sum(image.height for image in images) + gap * (len(images) - 1)
    canvas = Image.new("RGBA", (width, height), BG + (255,))
    y = 0
    for image in images:
        canvas.alpha_composite(image, (0, y))
        y += image.height + gap
    return canvas


def main():
    SHARE_DIR.mkdir(parents=True, exist_ok=True)
    chapters = [
        ("chapter-01-start.png", chapter_start()),
        ("chapter-02-reminders.png", chapter_reminders()),
        ("chapter-03-wrapup-and-today.png", chapter_wrapup()),
        ("chapter-04-today-week.png", chapter_review()),
    ]
    images = []
    for name, image in chapters:
        path = SHARE_DIR / name
        image.save(path)
        images.append(image)
    stitched = stitch(images)
    stitched.save(SHARE_DIR / "yiji-guide-long.png")


if __name__ == "__main__":
    main()
