
//////////////////////////////////////////////////
// Module: grid_cell
//////////////////////////////////////////////////
module grid_cell (
    input  wire       clk,
    input  wire       reset,     // Asynchronous reset: sets cell to initial state (BLUE)
    input  wire       shot,      // Signal indicating a shot fired on this cell
    input  wire       is_ship,   // 1 if a ship segment occupies this cell, 0 otherwise
    input  wire       ship_sunk, // Signal from game logic: ship (or adjacent ship) has been sunk
    output reg  [3:0] cell_state // One-hot encoded state of the cell
);

    // One-hot encoded cell states (4 states)
    localparam STATE_BLUE  = 4'b0001;  // Untouched water (blue)
    localparam STATE_GRAY  = 4'b0010;  // Miss (gray)
    localparam STATE_BLACK = 4'b0100;  // Hit (black: ship hit but not yet sunk)
    localparam STATE_RED   = 4'b1000;  // Sunk (red: ship fully sunk or adjacent to sunk ship)

    reg [3:0] next_state;

    // Sequential logic: update cell state on the rising edge or when reset is asserted
    always @(posedge clk or posedge reset) begin
        if (reset)
            cell_state <= STATE_BLUE;
        else
            cell_state <= next_state;
    end

    // Combinational logic: determine next state based on current state and inputs
    always @(*) begin
        // Default: maintain current state
        next_state = cell_state;
        case (cell_state)
            STATE_BLUE: begin
                // If shot fired on this cell, decide based on whether a ship is there
                if (shot) begin
                    if (is_ship)
                        next_state = STATE_BLACK; // Register hit
                    else
                        next_state = STATE_GRAY;  // Register miss
                end
                // Also, if the ship in/near this cell has been sunk,
                // override to sunk state.
                if (ship_sunk)
                    next_state = STATE_RED;
            end

            STATE_BLACK: begin
                // Remain in hit state until the full ship is sunk
                if (ship_sunk)
                    next_state = STATE_RED;
                else
                    next_state = STATE_BLACK;
            end

            STATE_GRAY: begin
                // Once a miss, the cell stays in the miss state
                next_state = STATE_GRAY;
            end

            STATE_RED: begin
                // Once sunk (or adjacent to a sunk ship), the cell stays red
                next_state = STATE_RED;
            end

            default: next_state = STATE_BLUE;
        endcase
    end

endmodule

module grid_array(
    input wire clk,
    input wire reset,
    input wire [99:0] shot,          // Individual shot signals for each cell
    input reg [99:0] is_ship,       // Individual ship position signals for each cell
    input wire [99:0] ship_sunk,     // Individual sunk signals for each cell
    output wire [399:0] cell_state_flat 
);

genvar i;
generate
    for (i = 0; i < 100; i = i + 1) begin : grid_cells
        wire [3:0] state;
        assign cell_state_flat[i*4 +: 4] = state;

        grid_cell cell_inst(
            .clk(clk),
            .reset(reset),
            .shot(shot[i]),
            .is_ship(is_ship[i]),
            .ship_sunk(ship_sunk[i]),
            .cell_state(state)
        );
    end
endgenerate


endmodule
