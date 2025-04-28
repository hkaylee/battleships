`timescale 1ns / 1ps
module vga_top(
  input  wire        ClkPort,
  input  wire        BtnL, BtnR, BtnU, BtnD, BtnC,
  input  wire        SW0,           // ← reset switch
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
    .reset            (SW0), 
    .btn_c            (BtnC),
    .sprite_row       (sprite_row),
    .sprite_col       (sprite_col),
    .cell_status_flat(cell_status_flat),
    .turns_left       (turns_left)
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
    .anode      (Anodes),
    .ssdOut     (Segs)
  );

  assign QuadSpiFlashCS = 1;
endmodule