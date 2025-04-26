# png2mem.py
from PIL import Image

# 1) load and convert to RGB
img = Image.open("sprite.png").convert("RGB")
width, height = img.size

# 2) open output .mem
with open("sprite.mem", "w") as f:
    # line-by-line, row-major order
    for y in range(height):
        for x in range(width):
            r, g, b = img.getpixel((x, y))
            # reduce 8-bit → 4-bit per channel
            r4 = r >> 4
            g4 = g >> 4
            b4 = b >> 4
            # pack into 12 bits: RRRRGGGGBBBB
            val = (r4 << 8) | (g4 << 4) | b4
            # write hex, 3 digits, no “0x” prefix (for $readmemh)
            f.write(f"{val:03x}\n")
