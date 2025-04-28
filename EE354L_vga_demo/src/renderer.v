`timescale 1ns / 1ps
module renderer(
  input  wire        clk,
  input  wire        bright,
  input  wire [9:0]  hCount,
  input  wire [9:0]  vCount,
  input  wire [11:0] sprite_color,
  input  wire        in_sprite,
  input  wire [199:0] cell_status_flat,
  output reg  [11:0] rgb
);
  localparam BLACK=12'h000, WHITE=12'hFFF, BLUE=12'h00F,
             GRAY=12'h888, RED=12'hF00;
  localparam integer GRID_LEFT=144, GRID_TOP=35,
                     CELL_WIDTH=64, CELL_HEIGHT=48,
                     LINE_THICK=1;

  wire inGrid = bright &&
                (hCount>=GRID_LEFT) && (hCount<GRID_LEFT+CELL_WIDTH*10) &&
                (vCount>=GRID_TOP)  && (vCount<GRID_TOP +CELL_HEIGHT*10);
  wire [3:0] row = (vCount - GRID_TOP) / CELL_HEIGHT;
  wire [3:0] col = (hCount - GRID_LEFT) / CELL_WIDTH;
  wire isV = inGrid && (((hCount - GRID_LEFT) % CELL_WIDTH) < LINE_THICK);
  wire isH = inGrid && (((vCount - GRID_TOP) % CELL_HEIGHT) < LINE_THICK);

  wire [1:0] status = inGrid ? cell_status_flat[(row*10+col)*2 +: 2] : 2'b00;
  reg  [11:0] bg;
  always @(*) begin
    case(status)
      2'b00: bg = BLUE;   // water
      2'b01: bg = GRAY;   // miss
      2'b10: bg = BLACK;  // hit
      2'b11: bg = RED;    // sunk
      default: bg = BLUE;
    endcase
  end

  always @(*) begin
    if (!bright)
      rgb = BLACK;
    else if (in_sprite && sprite_color!=12'h00F)
      rgb = sprite_color;
    else if (isV || isH)
      rgb = WHITE;
    else
      rgb = bg;
  end
endmodule