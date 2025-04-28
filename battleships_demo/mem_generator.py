from PIL import Image

# 1) open and *resize* to exactly your CELL_WIDTH×CELL_HEIGHT
img = Image.open("sprite.png").convert("RGB")
img = img.resize((64,48), Image.NEAREST)

# 2) write out 12-bit mem
with open("sprite.mem","w") as f:
  for y in range(48):
    for x in range(64):
      r,g,b = img.getpixel((x,y))
      # down to 4-bit each
      val = ((r>>4)<<8) | ((g>>4)<<4) | (b>>4)
      f.write(f"{val:03x}\n")
