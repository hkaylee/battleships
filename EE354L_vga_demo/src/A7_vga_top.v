`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    12:18:00 12/14/2017 
// Design Name: 
// Module Name:    vga_top 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
// Date: 04/04/2020
// Author: Yue (Julien) Niu
// Description: Port from NEXYS3 to NEXYS4
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps
module vga_top(
  input  wire        ClkPort,
  input  wire        BtnL, BtnR, BtnU, BtnD, BtnC,
  output wire        hSync, vSync,
  output wire [3:0]  vgaR, vgaG, vgaB,
  output wire [7:0]  Anodes,
  output wire [6:0]  Segs,
  output wire        QuadSpiFlashCS
);
  wire        bright;
  wire [9:0]  hc, vc;
  wire [11:0] rgb_pix, sprite_color;
  wire        in_sprite;
  wire [3:0]  sprite_row, sprite_col;
  wire [199:0] cell_status_flat;
  wire [4:0]  turns_left;
  wire        win, lose;

  display_controller dc(
    .clk    (ClkPort),
    .hSync  (hSync),
    .vSync  (vSync),
    .bright (bright),
    .hCount (hc),
    .vCount (vc)
  );

  vga_bitchange cursor_control(
    .clk        (ClkPort),
    .bright     (bright),
    .hCount     (hc),
    .vCount     (vc),
    .btn_l      (BtnL),
    .btn_r      (BtnR),
    .btn_u      (BtnU),
    .btn_d      (BtnD),
    .rgb        (),
    .sprite_row (sprite_row),
    .sprite_col (sprite_col),
    .in_sprite  (in_sprite)
  );

  sprite_rom rom(
    .clk   (ClkPort),
    .addr  (in_sprite ? ((vc - (35 + sprite_row*48 + 1))*64 + (hc - (144 + sprite_col*64 + 1))) : 12'd0),
    .color (sprite_color)
  );

  game_state gs(
    .clk              (ClkPort),
    .reset            (1'b0),
    .btn_c            (BtnC),
    .sprite_row       (sprite_row),
    .sprite_col       (sprite_col),
    .cell_status_flat(cell_status_flat),
    .turns_left       (turns_left),
    .win              (win),
    .lose             (lose)
  );

  renderer rdr(
    .clk              (ClkPort),
    .bright           (bright),
    .hCount           (hc),
    .vCount           (vc),
    .sprite_color     (sprite_color),
    .in_sprite        (in_sprite),
    .cell_status_flat(cell_status_flat),
    .rgb              (rgb_pix)
  );

  assign vgaR = rgb_pix[11:8];
  assign vgaG = rgb_pix[7 :4];
  assign vgaB = rgb_pix[3 :0];

  ssd_controller ssd(
    .clk        (ClkPort),
    .turns_left (turns_left),
    .win        (win),
    .lose       (lose),
    .anode      (Anodes),
    .ssdOut     (Segs)
  );

  assign QuadSpiFlashCS = 1;
endmodule