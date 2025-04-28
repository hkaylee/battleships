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
    output reg  [11:0] rgb,       // unused, renderer draws now
    output wire [3:0]  sprite_row,
    output wire [3:0]  sprite_col,
    output wire        in_sprite
);
  // Parameters
  localparam integer GRID_SIZE    = 10;
  localparam integer CELL_WIDTH   = 64;
  localparam integer CELL_HEIGHT  = 48;
  localparam integer GRID_LEFT    = 144;
  localparam integer GRID_TOP     = 35;
  localparam integer LINE_THICK   = 1;
  localparam integer SPRITE_W     = 64;
  localparam integer SPRITE_H     = 48;

  // Debounce logic (unchanged)
  reg [2:0] btn_l_hist, btn_r_hist, btn_u_hist, btn_d_hist;
  reg btn_l_debounced, btn_r_debounced, btn_u_debounced, btn_d_debounced;
  reg btn_l_prev, btn_r_prev, btn_u_prev, btn_d_prev;
  reg [15:0] sample_cnt = 0;
  wire sample_tick = (sample_cnt == 0);
  always @(posedge clk) begin
    sample_cnt <= sample_cnt + 1;
    if (sample_tick) begin
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
  wire btn_l_edge = btn_l_debounced & ~btn_l_prev;
  wire btn_r_edge = btn_r_debounced & ~btn_r_prev;
  wire btn_u_edge = btn_u_debounced & ~btn_u_prev;
  wire btn_d_edge = btn_d_debounced & ~btn_d_prev;

  // Sprite position registers
  reg [3:0] col_reg = 0, row_reg = 0;
  assign sprite_col = col_reg;
  assign sprite_row = row_reg;

  always @(posedge clk) begin
    if (sample_tick) begin
      if (btn_l_edge && col_reg > 0)        col_reg <= col_reg - 1;
      else if (btn_r_edge && col_reg < GRID_SIZE-1) col_reg <= col_reg + 1;
      if (btn_u_edge && row_reg > 0)        row_reg <= row_reg - 1;
      else if (btn_d_edge && row_reg < GRID_SIZE-1) row_reg <= row_reg + 1;
    end
  end

  // Center sprite in cell
  wire [9:0] sprite_x = GRID_LEFT + col_reg*CELL_WIDTH + LINE_THICK + ((CELL_WIDTH - 2*LINE_THICK - SPRITE_W)/2);
  wire [9:0] sprite_y = GRID_TOP  + row_reg*CELL_HEIGHT + LINE_THICK + ((CELL_HEIGHT-2*LINE_THICK - SPRITE_H)/2);

  // in_sprite detection
  assign in_sprite = bright
    && (hCount >= sprite_x) && (hCount < sprite_x + SPRITE_W)
    && (vCount >= sprite_y) && (vCount < sprite_y + SPRITE_H);

  // rgb unused here
  always @(*) rgb = 12'h000;
endmodule