// hit_detector.v
module hit_detector (
    input  wire       clk,
    input  wire       reset,
    input  wire       shot,         
    input  wire [3:0] cursor_row,   // Current row selected
    input  wire [3:0] cursor_col,   // Current col selected
    output reg        hit           // ie when player presses center button. 
);
    wire [6:0] index;
    assign index = cursor_row * 4'd10 + cursor_col;

    parameter [99:0] SHIP_MAP = 100'b
        0000000000_  // row 9
        0000000000_  // row 8
        0000011111_  // row 7 fixed map for now 
        0000000000_  // row 6
        0000000000_  // row 5
        0000000000_  // row 4
        0000000000_  // row 3
        0000000000_  // row 2
        0000000000_  // row 1
        0000000000;  // row 0

    // When a shot occurs, check the bit at the computed index.
    // Here we output the result only on the shot pulse.
    always @(posedge clk or posedge reset) begin
        if (reset)
            hit <= 1'b0;
        else if (shot)
            hit <= SHIP_MAP[index];
        else
            hit <= 1'b0;  // Ensure the hit signal is only one clock cycle wide
    end

endmodule