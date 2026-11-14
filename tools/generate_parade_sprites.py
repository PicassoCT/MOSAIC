#!/usr/bin/env python3
"""Regenerate the small vector-drawn parade particle sprites (Pillow required)."""
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "bitmaps" / "ProjectileTextures"
SCALE = 4
SIZE = 128

def canvas():
    image = Image.new("RGBA", (SIZE*SCALE, SIZE*SCALE), (0,0,0,0))
    return image, ImageDraw.Draw(image)

def poly(draw, points, color):
    draw.polygon([(round(x*SCALE),round(y*SCALE)) for x,y in points], fill=color)

def line(draw, points, color, width=1):
    draw.line([(round(x*SCALE),round(y*SCALE)) for x,y in points], fill=color, width=round(width*SCALE), joint="curve")

def save(image, name):
    OUT.mkdir(parents=True, exist_ok=True)
    image.resize((SIZE,SIZE), Image.Resampling.LANCZOS).save(OUT / (name+".png"))

def main():
    image, draw = canvas()
    # White folded paper allows the CEG's three systems to supply bright colours.
    poly(draw, [(39,24),(96,38),(84,102),(29,86)], "#fff8e8")
    poly(draw, [(39,24),(96,38),(72,59),(29,86)], "#ffffff")
    line(draw, [(29,86),(72,59),(96,38)], "#d5e3eb", 2)
    save(image, "parade_confetti")

    image, draw = canvas()
    # Distinct long neck, angular wings, body and tail; shaded fold planes.
    poly(draw, [(47,75),(12,31),(62,55),(111,13),(83,72),(63,87)], "#fff7dd")
    poly(draw, [(12,31),(62,55),(54,76)], "#ffffff")
    poly(draw, [(62,55),(111,13),(70,74)], "#d0dbed")
    poly(draw, [(47,75),(26,115),(61,84),(83,72),(92,48),(108,53),(95,58),(85,91),(65,98)], "#fff9ed")
    poly(draw, [(47,75),(61,84),(26,115)], "#b5c9e3")
    poly(draw, [(61,84),(83,72),(65,98)], "#d0dbed")
    line(draw, [(54,76),(62,55),(70,74),(65,98)], "#9cafd0", 1.6)
    line(draw, [(85,91),(92,48),(108,53)], "#bdcbe2", 1.4)
    save(image, "parade_origami")

    image, draw = canvas()
    # Cherry blossom petal, with the characteristic shallow notched tip.
    poly(draw, [(63,114),(39,89),(24,63),(22,40),(31,20),(48,13),(64,25),(80,14),(98,22),(107,43),(102,65),(87,92)], "#ffb4cf")
    poly(draw, [(63,114),(43,73),(38,45),(48,20),(64,32),(80,22),(89,45),(79,76)], "#ffe1eb")
    line(draw, [(63,108),(61,76),(64,39)], "#e57fa6", 2)
    save(image, "parade_petal")

    image, draw = canvas()
    # Fictional inflation note. Keep the oversized denomination readable when close.
    poly(draw, [(9,37),(114,27),(120,88),(15,100)], "#e1ead0")
    poly(draw, [(15,43),(108,34),(114,83),(21,92)], "#50896d")
    poly(draw, [(20,47),(104,39),(108,79),(25,86)], "#cedeb7")
    draw.ellipse((44*SCALE,44*SCALE,85*SCALE,81*SCALE), fill="#87ae89", outline="#3b715f", width=2*SCALE)
    # Pixel geometry rather than a machine-specific font keeps output reproducible.
    glyphs={"1":["010","110","010","010","111"],"0":["111","101","101","101","111"],"B":["110","101","110","101","110"]}
    text="100B"
    origin_x, origin_y, pixel = 39, 54, 3
    for i, char in enumerate(text):
        for y, row in enumerate(glyphs[char]):
            for x, filled in enumerate(row):
                if filled=="1":
                    left=(origin_x+i*4*pixel+x*pixel)*SCALE
                    top=(origin_y+y*pixel)*SCALE
                    draw.rectangle((left,top,left+pixel*SCALE-1,top+pixel*SCALE-1), fill="#173e37")
    line(draw, [(26,52),(35,51)], "#35664e", 2)
    line(draw, [(93,75),(101,74)], "#35664e", 2)
    save(image, "parade_banknote")

if __name__ == "__main__":
    main()
