`timescale 1ns / 1ps
module ssd_controller(
  input  wire       clk,
  input  wire [4:0] turns_left,
  input  wire [2:0] ships_remaining,  // NEW: Input for remaining ships
  output reg [7:0]  anode,
  output reg [6:0]  ssdOut
);
  // 7-seg hex encoding for 0-F
  function [6:0] seg7;
    input [3:0] val;
    case(val)
      4'h0: seg7 = 7'b1000000;
      4'h1: seg7 = 7'b1111001;
      4'h2: seg7 = 7'b0100100;
      4'h3: seg7 = 7'b0110000;
      4'h4: seg7 = 7'b0011001;
      4'h5: seg7 = 7'b0010010;
      4'h6: seg7 = 7'b0000010;
      4'h7: seg7 = 7'b1111000;
      4'h8: seg7 = 7'b0000000;
      4'h9: seg7 = 7'b0010000;
      4'hA: seg7 = 7'b0001000;
      4'hB: seg7 = 7'b0000011;
      4'hC: seg7 = 7'b1000110;
      4'hD: seg7 = 7'b0100001;
      4'hE: seg7 = 7'b0000110;
      4'hF: seg7 = 7'b0001110;
      default: seg7 = 7'b1111111;
    endcase
  endfunction

  // Add a simple counter for multiplexing between displays
  reg [15:0] refresh_cnt;
  always @(posedge clk) begin
    refresh_cnt <= refresh_cnt + 1;
  end
  
  // Use the MSB of the counter to alternate between displays
  wire display_select = refresh_cnt[15];

  always @(*) begin
    if (display_select) begin
      // Display turns_left on SSD0
      anode = 8'b11111110;  // Activate SSD0
      ssdOut = seg7(turns_left[3:0]);
    end else begin
      // Display ships_remaining on SSD5
      anode = 8'b11101111; // SSD4 active
      ssdOut = seg7({1'b0, ships_remaining});  // Zero-extend to 4 bits
    end
  end
endmodule