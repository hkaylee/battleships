`timescale 1ns/1ps
module ssd_controller(
  input  wire        clk,
  input  wire [4:0]  turns_left,
  input  wire        win,
  input  wire        lose,
  output reg  [7:0]  anode,
  output reg  [6:0]  ssdOut
);
  // 7-segment patterns: 0–9, A–Z, etc.
  function [6:0] seg7;
    input [7:0] char;
    case(char)
      "0": seg7 = 7'b100_0000;  "1": seg7 = 7'b111_1001;
      "2": seg7 = 7'b010_0100;  "3": seg7 = 7'b011_0000;
      "4": seg7 = 7'b001_1001;  "5": seg7 = 7'b001_0010;
      "6": seg7 = 7'b000_0010;  "7": seg7 = 7'b111_1000;
      "8": seg7 = 7'b000_0000;  "9": seg7 = 7'b001_0000;
      "W": seg7 = 7'b000_1001;  "I": seg7 = 7'b111_1001;
      "N": seg7 = 7'b010_0101;  "L": seg7 = 7'b100_0111;
      "O": seg7 = 7'b100_0000;  "S": seg7 = 7'b001_0010;
      default: seg7 = 7'b111_1111;
    endcase
  endfunction

  reg [1:0] digit_sel = 0;
  always @(posedge clk) digit_sel <= digit_sel + 1;

  always @(*) begin
    case(digit_sel)
      2'd0: begin anode=8'b1111_1110;
            if (win)       ssdOut = seg7("L");
            else if (lose) ssdOut = seg7("L");
            else           ssdOut = seg7("0"+turns_left%10);
      end
      2'd1: begin anode=8'b1111_1101;
            if (win)       ssdOut = seg7("I");
            else if (lose) ssdOut = seg7("O");
            else           ssdOut = seg7("0"+turns_left/10);
      end
      2'd2: begin anode=8'b1111_1011;
            if (win)       ssdOut = seg7("N");
            else if (lose) ssdOut = seg7("S");
            else           ssdOut = 7'b111_1111;
      end
      2'd3: begin anode=8'b1111_0111; ssdOut = 7'b111_1111; end
      default: begin anode=8'b1111_1111; ssdOut=7'b111_1111; end
    endcase
  end

endmodule
