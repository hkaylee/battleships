
//////////////////////////////////////////////////
// Module: cursor_control
//////////////////////////////////////////////////
// This module updates the cursor position on a 10×10 grid.

module cursor_control (
    input  wire        clk,         // System clock
    input  wire        reset,       // Asynchronous system reset
    input  wire        player_turn, // High when the game FSM is in player turn state
    input  wire        btn_up,      // Directional button: up
    input  wire        btn_down,    // Directional button: down
    input  wire        btn_left,    // Directional button: left
    input  wire        btn_right,   // Directional button: right
    output reg  [3:0]  cursor_row,  // Row index (0 to 9)
    output reg  [3:0]  cursor_col   // Column index (0 to 9)
);

    // Define grid boundaries for a 10×10 grid.
    localparam MIN_INDEX = 4'd0;
    localparam MAX_INDEX = 4'd9;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            cursor_row <= MIN_INDEX;
            cursor_col <= MIN_INDEX;
        end
        else if (player_turn) begin
            // Check vertical movement first.
            if (btn_up && (cursor_row > MIN_INDEX))
                cursor_row <= cursor_row - 1;
            else if (btn_down && (cursor_row < MAX_INDEX))
                cursor_row <= cursor_row + 1;

            // Check horizontal movement.
            if (btn_left && (cursor_col > MIN_INDEX))
                cursor_col <= cursor_col - 1;
            else if (btn_right && (cursor_col < MAX_INDEX))
                cursor_col <= cursor_col + 1;
        end
    end

endmodule