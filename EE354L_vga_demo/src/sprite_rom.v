`timescale 1ns / 1ps
module sprite_rom (
  input  wire        clk,
  input  wire [9:0]  addr,        // address runs from 0 to (W*H-1)
  output reg [11:0]  color        // 12-bit RGB
);

  // change 64 and 64 to your PNG’s width & height
  localparam integer W = 64, H = 48;

  // declare a block RAM
  reg [11:0] mem [0:W*H-1];

  initial begin
    // this reads sprite.mem (the file you generated) into the RAM
    $readmemh("sprite.mem", mem);
  end

  // synchronous read
  always @(posedge clk)
    color <= mem[addr];

endmodule
