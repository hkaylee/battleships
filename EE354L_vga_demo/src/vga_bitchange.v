`timescale 1ns / 1ps
module vga_bitchange(
    input  wire        clk,
    input  wire        bright,
    input  wire [9:0]  hCount,
    input  wire [9:0]  vCount,
    input  wire        btn_l,
    input  wire        btn_r,
    input  wire        btn_u,
    input  wire        btn_d,
    output reg  [11:0] rgb,
    output reg  [15:0] score
);

  // Colors
  localparam [11:0] BLACK = 12'h000,
                   WHITE = 12'hFFF,
                   BLUE  = 12'h00F;

  // Grid parameters
  localparam integer GRID_SIZE   = 10,
                     CELL_WIDTH  = 64,
                     CELL_HEIGHT = 48,
                     GRID_LEFT   = 144,
                     GRID_TOP    = 35,
                     LINE_THICK  = 1;

  // Sprite parameters
  localparam integer SPRITE_W = 64,
                     SPRITE_H = 48;

  //––––––––––––––––––––––––––––––––––––––––––––––––
  // 0) Edge-detect each button
  //––––––––––––––––––––––––––––––––––––––––––––––––
  reg btn_l_d, btn_r_d, btn_u_d, btn_d_d;
  always @(posedge clk) begin
    btn_l_d <= btn_l;
    btn_r_d <= btn_r;
    btn_u_d <= btn_u;
    btn_d_d <= btn_d;
  end
  wire btn_l_edge =  btn_l & ~btn_l_d;
  wire btn_r_edge =  btn_r & ~btn_r_d;
  wire btn_u_edge =  btn_u & ~btn_u_d;
  wire btn_d_edge =  btn_d & ~btn_d_d;

  //––––––––––––––––––––––––––––––––––––––––––––––––
  // 1) Track sprite position in grid‐cell coords (edge-only + debounce)
  //––––––––––––––––––––––––––––––––––––––––––––––––
  reg [3:0] sprite_col = 0;
  reg [3:0] sprite_row = 0;
  reg [19:0] cooldown = 0;  // cooldown counter for debouncing

  always @(posedge clk) begin
    if (cooldown != 0)
      cooldown <= cooldown - 1;
    else begin
      if (btn_l_edge && sprite_col > 0) begin
        sprite_col <= sprite_col - 1;
        cooldown <= 500_000;  // ~5ms debounce
      end
      else if (btn_r_edge && sprite_col < GRID_SIZE-1) begin
        sprite_col <= sprite_col + 1;
        cooldown <= 500_000;
      end

      if (btn_u_edge && sprite_row > 0) begin
        sprite_row <= sprite_row - 1;
        cooldown <= 500_000;
      end
      else if (btn_d_edge && sprite_row < GRID_SIZE-1) begin
        sprite_row <= sprite_row + 1;
        cooldown <= 500_000;
      end
    end
  end

  //––––––––––––––––––––––––––––––––––––––––––––––––
  // compute top-left corner of sprite (pixel coords)
  wire [9:0] sprite_x = GRID_LEFT + sprite_col * CELL_WIDTH;
  wire [9:0] sprite_y = GRID_TOP  + sprite_row * CELL_HEIGHT;

  //––––––––––––––––––––––––––––––––––––––––––––––––
  // detect VGA scan inside sprite area
  wire in_sprite = bright
    && (hCount >= sprite_x)
    && (hCount <  sprite_x + SPRITE_W)
    && (vCount >= sprite_y)
    && (vCount <  sprite_y + SPRITE_H);

  // compute address into ROM
  wire [9:0] sprite_addr =
       (vCount - sprite_y) * SPRITE_W
     + (hCount - sprite_x);

  // pull color from sprite ROM
  wire [11:0] sprite_color;
  sprite_rom rom (
    .clk   (clk),
    .addr  (sprite_addr),
    .color (sprite_color)
  );

  //––––––––––––––––––––––––––––––––––––––––––––––––
  // 2) Your existing grid logic
  wire isV = bright
    && (hCount >= GRID_LEFT)
    && (hCount <  GRID_LEFT + CELL_WIDTH*GRID_SIZE)
    && (((hCount - GRID_LEFT) % CELL_WIDTH) < LINE_THICK);
  wire isH = bright
    && (vCount >= GRID_TOP)
    && (vCount <  GRID_TOP + CELL_HEIGHT*GRID_SIZE)
    && (((vCount - GRID_TOP) % CELL_HEIGHT) < LINE_THICK);
  wire inGrid = bright
    && (hCount >= GRID_LEFT)
    && (hCount <  GRID_LEFT + CELL_WIDTH*GRID_SIZE)
    && (vCount >= GRID_TOP)
    && (vCount <  GRID_TOP  + CELL_HEIGHT*GRID_SIZE);

  //––––––––––––––––––––––––––––––––––––––––––––––––
  // 3) Final pixel mux: sprite > grid lines > grid fill > black
  always @(*) begin
    if (!bright)
      rgb = BLACK;
    else if (in_sprite)
      rgb = sprite_color;      // sprite on top
    else if (isV || isH)
      rgb = WHITE;             // grid lines
    else if (inGrid)
      rgb = BLUE;              // grid background
    else
      rgb = BLACK;
  end

  // static score (unchanged)
  always @(posedge clk)
    score <= 0;

endmodule
