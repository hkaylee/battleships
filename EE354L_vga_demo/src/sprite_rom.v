`timescale 1ns / 1ps
module sprite_rom (
  input  wire        clk,
  input  wire [11:0] addr,        // <<< changed from [9:0] to [11:0]
  output reg  [11:0] color
);

  // Assuming your sprite is 64x48 = 3072 pixels
  localparam integer W = 64;
  localparam integer H = 48;

  reg [11:0] mem [0:W*H-1];  // 0 to 3071

  initial begin
    $readmemh("sprite.mem", mem);
  end

  always @(posedge clk) begin
    color <= mem[addr];
  end

endmodule
