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
module vga_top(
    input  wire        ClkPort,
    // four-way direction buttons for sprite movement
    input  wire        BtnL,
    input  wire        BtnR,
    input  wire        BtnU,
    input  wire        BtnD,

    // VGA outputs
    output wire        hSync,
    output wire        vSync,
    output wire [3:0]  vgaR,
    output wire [3:0]  vgaG,
    output wire [3:0]  vgaB,

    // Seven-segment outputs
    output wire        An0,
    output wire        An1,
    output wire        An2,
    output wire        An3,
    output wire        An4,
    output wire        An5,
    output wire        An6,
    output wire        An7,
    output wire        Ca,
    output wire        Cb,
    output wire        Cc,
    output wire        Cd,
    output wire        Ce,
    output wire        Cf,
    output wire        Cg,
    output wire        Dp,

    // Flash chip disable
    output wire        QuadSpiFlashCS
);

    //------------------------------------------
    // Internal nets
    //------------------------------------------
    wire        bright;
    wire [9:0]  hc, vc;
    wire [11:0] rgb;        // from vga_bitchange
    wire [15:0] score;
    wire [6:0]  ssdOut;
    wire [3:0]  anode;

    //------------------------------------------
    // VGA timing generator
    //------------------------------------------
    display_controller dc (
      .clk    (ClkPort),
      .hSync  (hSync),
      .vSync  (vSync),
      .bright (bright),
      .hCount (hc),
      .vCount (vc)
    );

    //------------------------------------------
    // Grid + sprite cursor logic
    //------------------------------------------
    vga_bitchange vbc (
      .clk    (ClkPort),
      .bright (bright),
      .hCount (hc),
      .vCount (vc),
      .btn_l  (BtnL),
      .btn_r  (BtnR),
      .btn_u  (BtnU),
      .btn_d  (BtnD),
      .rgb    (rgb),
      .score  (score)
    );

    //------------------------------------------
    // Score → seven-segment decoder
    //------------------------------------------
    counter cnt (
      .clk           (ClkPort),
      .displayNumber (score),
      .anode         (anode),
      .ssdOut        (ssdOut)
    );

    //------------------------------------------
    // Seven-segment wiring
    //------------------------------------------
    assign Dp = 1'b1;
    assign {Ca, Cb, Cc, Cd, Ce, Cf, Cg} = ssdOut;
    // only 4 digits used; pad upper 4 off
    assign {An7, An6, An5, An4, An3, An2, An1, An0} = {4'b1111, anode};

    //------------------------------------------
    // RGB(12) → VGA(4)
    //------------------------------------------
    assign vgaR = rgb[11:8];
    assign vgaG = rgb[7:4];
    assign vgaB = rgb[3:0];

    //------------------------------------------
    // Disable flash chip
    //------------------------------------------
    assign QuadSpiFlashCS = 1'b1;

endmodule