from PIL import Image

# sprite size must match what you used in your Verilog
WIDTH = 64
HEIGHT = 48

# create a blank RGB image
img = Image.new('RGB', (WIDTH, HEIGHT))

# open the mem file
with open("sprite.mem", "r") as f:
    lines = f.readlines()

for idx, line in enumerate(lines):
    hexval = int(line.strip(), 16)
    r = (hexval >> 8) & 0xF
    g = (hexval >> 4) & 0xF
    b = (hexval >> 0) & 0xF
    # scale up 4-bit color to 8-bit for viewing
    r = (r << 4) | r
    g = (g << 4) | g
    b = (b << 4) | b
    x = idx % WIDTH
    y = idx // WIDTH
    img.putpixel((x, y), (r, g, b))

img.show()   # pops up the image so you can see it
img.save("reconstructed_sprite.png")   # saves it if you want
