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
  localparam integer GRID_SIZE    = 10,
                     CELL_WIDTH   = 64,
                     CELL_HEIGHT  = 48,
                     GRID_LEFT    = 144,
                     GRID_TOP     = 35,
                     LINE_THICK   = 1;

  // Sprite parameters
  localparam integer SPRITE_W = 64,
                     SPRITE_H = 48;

  //------------------------------------------------
  // 0) Button debouncing with multi-stage sampling
  //------------------------------------------------
  reg [2:0] btn_l_hist, btn_r_hist, btn_u_hist, btn_d_hist;
  reg btn_l_debounced, btn_r_debounced, btn_u_debounced, btn_d_debounced;
  reg btn_l_prev,      btn_r_prev,      btn_u_prev,      btn_d_prev;
  
  reg [15:0] btn_sample_counter = 0;
  wire       btn_sample_tick    = (btn_sample_counter == 0);

  always @(posedge clk) begin
    btn_sample_counter <= btn_sample_counter + 1;
    if (btn_sample_tick) begin
      btn_l_hist <= {btn_l_hist[1:0], btn_l};
      btn_r_hist <= {btn_r_hist[1:0], btn_r};
      btn_u_hist <= {btn_u_hist[1:0], btn_u};
      btn_d_hist <= {btn_d_hist[1:0], btn_d};

      btn_l_prev <= btn_l_debounced;
      btn_r_prev <= btn_r_debounced;
      btn_u_prev <= btn_u_debounced;
      btn_d_prev <= btn_d_debounced;

      btn_l_debounced <= &btn_l_hist;
      btn_r_debounced <= &btn_r_hist;
      btn_u_debounced <= &btn_u_hist;
      btn_d_debounced <= &btn_d_hist;
    end
  end

  // Edge detection
  wire btn_l_edge = btn_l_debounced & ~btn_l_prev;
  wire btn_r_edge = btn_r_debounced & ~btn_r_prev;
  wire btn_u_edge = btn_u_debounced & ~btn_u_prev;
  wire btn_d_edge = btn_d_debounced & ~btn_d_prev;

  //------------------------------------------------
  // 1) Track sprite position in grid cells
  //------------------------------------------------
  reg [3:0] sprite_col = 0;
  reg [3:0] sprite_row = 0;

  always @(posedge clk) begin
    if (btn_sample_tick) begin
      if (btn_l_edge && sprite_col > 0)
        sprite_col <= sprite_col - 1;
      else if (btn_r_edge && sprite_col < GRID_SIZE-1)
        sprite_col <= sprite_col + 1;

      if (btn_u_edge && sprite_row > 0)
        sprite_row <= sprite_row - 1;
      else if (btn_d_edge && sprite_row < GRID_SIZE-1)
        sprite_row <= sprite_row + 1;
    end
  end

  //------------------------------------------------
  // 2) Compute sprite positioning (no overlap)
  //------------------------------------------------
  // Position at 1px inside top/left lines
  wire [9:0] sprite_x = GRID_LEFT + sprite_col * CELL_WIDTH + LINE_THICK;
  wire [9:0] sprite_y = GRID_TOP  + sprite_row * CELL_HEIGHT + LINE_THICK;
  // Shrink to avoid right/bottom lines
  wire [9:0] adjusted_sprite_w = CELL_WIDTH  - (2 * LINE_THICK);
  wire [9:0] adjusted_sprite_h = CELL_HEIGHT - (2 * LINE_THICK);

  //------------------------------------------------
  // 3) Detect when VGA scan is in the sprite area
  //------------------------------------------------
  wire in_sprite = bright
    && (hCount >= sprite_x)
    && (hCount <  sprite_x + adjusted_sprite_w)
    && (vCount >= sprite_y)
    && (vCount <  sprite_y + adjusted_sprite_h);

  //------------------------------------------------
  // 4) Compute sprite ROM address with scaling
  //------------------------------------------------
  // Map each display-pixel in adjusted area to full SPRITE_W×SPRITE_H ROM
  wire [11:0] sprite_addr = 
       ((vCount - sprite_y) * SPRITE_H / adjusted_sprite_h) * SPRITE_W
     + ((hCount - sprite_x) * SPRITE_W / adjusted_sprite_w);

  // Fetch color from ROM
  wire [11:0] sprite_color;
  sprite_rom rom (
    .clk   (clk),
    .addr  (sprite_addr),
    .color (sprite_color)
  );

  //------------------------------------------------
  // 5) Grid rendering logic
  //------------------------------------------------
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

  //------------------------------------------------
  // 6) Final pixel mux: sprite > grid > background > black
  //------------------------------------------------
  always @(*) begin
    if (!bright)
      rgb = BLACK;
    else if (in_sprite)
      rgb = sprite_color;
    else if (isV || isH)
      rgb = WHITE;
    else if (inGrid)
      rgb = BLUE;
    else
      rgb = BLACK;
  end

  // Static score
  always @(posedge clk)
    score <= 0;

endmodule
