`timescale 1ns / 1ps

module ship_status #(parameter SHIP_SIZE = 3)(
    input  wire                   clk,      // System clock
    input  wire                   reset,    // Asynchronous reset (active high)
    input  wire [SHIP_SIZE-1:0]   seg_hit,  // Each bit indicates if a segment is hit
    output reg                    ship_sunk // Asserted when ship is sunk
);

    // Combinational check (using reduction AND) to determine if all segments are hit
    // The design keeps ship_sunk high after the ship is sunk.
    always @(posedge clk or posedge reset) begin
        if (reset)
            ship_sunk <= 1'b0;
        else if (&seg_hit)  // reduction AND: true if every bit in seg_hit is 1.
            ship_sunk <= 1'b1;
        else
            ship_sunk <= ship_sunk; // hold the value (once sunk, remains sunk)
    end

endmodule
