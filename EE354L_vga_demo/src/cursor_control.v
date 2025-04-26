`timescale 1ns / 1ps
`include "sprite_12_bit_rom.v"

module vga_with_snapped_sprite (
  input  wire        clk,
  input  wire        bright,
  input  wire [9:0]  hCount,
  input  wire [9:0]  vCount,
  // raw Nexys A7 buttons (active high)
  input  wire        btn_l,
  input  wire        btn_r,
  input  wire        btn_u,
  input  wire        btn_d,
  output reg  [11:0] rgb,
  output reg  [15:0] score
);

  //─────────────────────────────────────────────────────────
  // Parameters & computed grid metrics
  //─────────────────────────────────────────────────────────
  localparam integer H_ACTIVE    = 640,
                     V_ACTIVE    = 480,
                     GRID_SIZE   = 10,
                     LINE_W      = 1;

  // how much total space lines consume
  localparam integer LINE_SPACE  = (GRID_SIZE + 1) * LINE_W;
  localparam integer AVAIL_H     = H_ACTIVE - LINE_SPACE;
  localparam integer AVAIL_V     = V_ACTIVE - LINE_SPACE;

  // your cells might be rectangles – pick the user’s sizes:
  localparam integer CELL_W      = AVAIL_H / GRID_SIZE;
  localparam integer CELL_H      = AVAIL_V / GRID_SIZE;

  // these match your existing choices (64×48 in your last example)
  // localparam integer CELL_W = 64, CELL_H = 48;

  // total grid span in each dimension
  localparam integer GRID_WPX    = CELL_W * GRID_SIZE + LINE_SPACE;
  localparam integer GRID_HPX    = CELL_H * GRID_SIZE + LINE_SPACE;

  // top/left corner of the grid (you already had 144,35)
  localparam integer GRID_LEFT   = (H_ACTIVE - GRID_WPX) / 2;
  localparam integer GRID_TOP    = (V_ACTIVE - GRID_HPX) / 2;

  // step from one cell to the next (including the line)
  localparam integer STEP_X      = CELL_W + LINE_W;
  localparam integer STEP_Y      = CELL_H + LINE_W;


  //─────────────────────────────────────────────────────────
  // Debounce + one‐pulse for each button
  //─────────────────────────────────────────────────────────
  function automatic [15:0] repeat_bit(input [3:0] b); 
    // helper to fill a shift‐register width (16) with the same bit
    integer i; 
    begin 
      repeat_bit = {16{b[0]}}; 
      for(i=1;i<16;i=i+1) 
        repeat_bit[i] = b[0];
    end 
  endfunction

  // simple 16-bit shift‐register debounce
  reg [15:0] sb_l, sb_r, sb_u, sb_d;
  wire db_l = &sb_l, db_r = &sb_r, db_u = &sb_u, db_d = &sb_d;

  always @(posedge clk) begin
    sb_l <= { sb_l[14:0], btn_l };
    sb_r <= { sb_r[14:0], btn_r };
    sb_u <= { sb_u[14:0], btn_u };
    sb_d <= { sb_d[14:0], btn_d };
  end

  // one‐pulse generators
  reg d1_l, d1_r, d1_u, d1_d;
  wire p_l = db_l & ~d1_l;
  wire p_r = db_r & ~d1_r;
  wire p_u = db_u & ~d1_u;
  wire p_d = db_d & ~d1_d;

  always @(posedge clk) begin
    d1_l <= db_l;  d1_r <= db_r;
    d1_u <= db_u;  d1_d <= db_d;
  end


  //─────────────────────────────────────────────────────────
  // Grid‐cell indices & “snapped” sprite position
  //─────────────────────────────────────────────────────────
  reg [3:0] gridX = 0, gridY = 0;  // 0…9

  always @(posedge clk) begin
    // left/right within 0…GRID_SIZE-1
    if      (p_l && gridX > 0         ) gridX <= gridX - 1;
    else if (p_r && gridX < GRID_SIZE-1) gridX <= gridX + 1;
    // up/down
    if      (p_u && gridY > 0         ) gridY <= gridY - 1;
    else if (p_d && gridY < GRID_SIZE-1) gridY <= gridY + 1;
  end

  // convert cell indices → pixel origin for sprite
  // (you can center the sprite inside the cell if SPRITE_SIZE < CELL_W/CELL_H)
  localparam integer SPRITE_SIZE = 16;
  wire [9:0] spriteX = GRID_LEFT + gridX * STEP_X 
                      + (CELL_W - SPRITE_SIZE)/2;
  wire [9:0] spriteY = GRID_TOP  + gridY * STEP_Y 
                      + (CELL_H - SPRITE_SIZE)/2;


  //─────────────────────────────────────────────────────────
  // Grid‐line & cell detection (identical to before)
  //─────────────────────────────────────────────────────────
  wire inGridH = bright
               && (hCount >= GRID_LEFT)
               && (hCount <  GRID_LEFT + GRID_WPX);
  wire inGridV = bright
               && (vCount >= GRID_TOP)
               && (vCount <  GRID_TOP  + GRID_HPX);

  wire isVertLine = inGridV
                 && (((hCount - GRID_LEFT) % STEP_X) < LINE_W);
  wire isHorLine  = inGridH
                 && (((vCount - GRID_TOP ) % STEP_Y) < LINE_W);
  wire inCell     = inGridH && inGridV;


  //─────────────────────────────────────────────────────────
  // Sprite ROM instantiation & window test
  //─────────────────────────────────────────────────────────
  wire [3:0] romRow = vCount - spriteY;
  wire [3:0] romCol = hCount - spriteX;

  wire [11:0] spriteColor;
  sprite_rom sprite_inst (
    .clk        (clk),
    .row        (romRow),
    .col        (romCol),
    .color_data (spriteColor)
  );

  wire spriteWindow = (hCount >= spriteX) 
                    && (hCount <  spriteX + SPRITE_SIZE)
                    && (vCount >= spriteY)
                    && (vCount <  spriteY + SPRITE_SIZE);


  //─────────────────────────────────────────────────────────
  // Final pixel mux
  //─────────────────────────────────────────────────────────
  localparam [11:0] BLACK = 12'h000,
                    WHITE = 12'hFFF,
                    BLUE  = 12'h00F;

  always @(*) begin
    if (!bright)
      rgb = BLACK;
    else if (spriteWindow)
      rgb = spriteColor;
    else if (isVertLine || isHorLine)
      rgb = WHITE;
    else if (inCell)
      rgb = BLUE;
    else
      rgb = BLACK;
  end

  // unused score
  always @(posedge clk)
    score <= 0;

endmodule
