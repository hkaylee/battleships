`timescale 1ns / 1ps
module vga_bitchange(
    input  wire        clk,
    input  wire        bright,
    input  wire [9:0]  hCount,
    input  wire [9:0]  vCount,
    // replace your single button port with four directions:
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
    localparam integer GRID_SIZE    = 10,
                       CELL_WIDTH   = 64,
                       CELL_HEIGHT  = 48,
                       GRID_LEFT    = 144,
                       GRID_TOP     = 35,
                       LINE_THICK   = 1;

    // Sprite parameters (must match your sprite_rom.v W,H)
    localparam integer SPRITE_W = 64,
                       SPRITE_H = 48;

    //––––––––––––––––––––––––––––––––––––––––––––––––
    // 1) Track sprite position in grid‐cell coords
    //––––––––––––––––––––––––––––––––––––––––––––––––
    reg [3:0] sprite_col = 0, sprite_row = 0;

    always @(posedge clk) begin
      // move left/right if pressed and in-bounds
      if (btn_l && sprite_col > 0)               sprite_col <= sprite_col - 1;
      else if (btn_r && sprite_col < GRID_SIZE-1) sprite_col <= sprite_col + 1;
      // move up/down
      if (btn_u && sprite_row > 0)               sprite_row <= sprite_row - 1;
      else if (btn_d && sprite_row < GRID_SIZE-1) sprite_row <= sprite_row + 1;
    end

    // compute top‐left corner of sprite in pixel coords
    wire [9:0] sprite_x = GRID_LEFT + sprite_col * CELL_WIDTH;
    wire [9:0] sprite_y = GRID_TOP  + sprite_row * CELL_HEIGHT;

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
    //––––––––––––––––––––––––––––––––––––––––––––––––
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
    //––––––––––––––––––––––––––––––––––––––––––––––––
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

    // Static score (unchanged)
    always @(posedge clk) score <= 0;

endmodule
