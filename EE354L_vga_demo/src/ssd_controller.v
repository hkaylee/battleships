`timescale 1ns / 1ps
module ssd_controller(
  input  wire       clk,
  input  wire [4:0] turns_left,
  input  wire       win,
  input  wire       lose,
  output reg [7:0]  anode,
  output reg [6:0]  ssdOut
);
  // 7-segment encoding function
  function [6:0] seg7;
    input [7:0] char;
    case(char)
      "0": seg7 = 7'b1000000;  "1": seg7 = 7'b1111001;
      "2": seg7 = 7'b0100100;  "3": seg7 = 7'b0110000;
      "4": seg7 = 7'b0011001;  "5": seg7 = 7'b0010010;
      "6": seg7 = 7'b0000010;  "7": seg7 = 7'b1111000;
      "8": seg7 = 7'b0000000;  "9": seg7 = 7'b0010000;
      "W": seg7 = 7'b0001001;  "I": seg7 = 7'b1111001;
      "N": seg7 = 7'b0101011;  "L": seg7 = 7'b1000111;
      "O": seg7 = 7'b1000000;  "S": seg7 = 7'b0010010;
      "E": seg7 = 7'b0000110;
      default: seg7 = 7'b1111111;
    endcase
  endfunction

  reg [1:0] digit_sel;
  always @(posedge clk) digit_sel <= digit_sel + 1;

  always @(*) begin
    case(digit_sel)
      // Digit 3 (leftmost)
      2'd3: begin anode = 8'b11110111;
        if (lose)       ssdOut = seg7("L");
        else             ssdOut = 7'b1111111;
      end
      // Digit 2
      2'd2: begin anode = 8'b11111011;
        if (win)        ssdOut = seg7("W");
        else if (lose)  ssdOut = seg7("O");
        else             ssdOut = 7'b1111111;
      end
      // Digit 1
      2'd1: begin anode = 8'b11111101;
        if (win)        ssdOut = seg7("I");
        else if (lose)  ssdOut = seg7("S");
        else             ssdOut = seg7("0" + (turns_left / 10));
      end
      // Digit 0 (rightmost)
      2'd0: begin anode = 8'b11111110;
        if (win)        ssdOut = seg7("N");
        else if (lose)  ssdOut = seg7("E");
        else             ssdOut = seg7("0" + (turns_left % 10));
      end
      default: begin anode = 8'b11111111; ssdOut = 7'b1111111; end
    endcase
  end
endmodule