module battleship_top(
    input wire clk,
    input wire reset,
    input wire start_btn,
    input wire reset_btn,
    input wire btn_up, btn_down, btn_left, btn_right, btn_select, // Cursor controls
    output wire [3:0] cell_states[99:0] // Output cell states (for display)
);

// Internal Signals
wire [6:0] selected_cell;
wire shot_select;
wire [99:0] shot_signals;
wire [99:0] is_ship;
wire [99:0] ship_sunk;
wire hit_detected;
wire all_ships_sunk;
wire turns_exhausted;
wire restart_pulse;
wire [4:0] game_state;

// Cursor control instance
cursor_control cursor(
    .clk(clk),
    .reset(reset),
    .btn_up(btn_up),
    .btn_down(btn_down),
    .btn_left(btn_left),
    .btn_right(btn_right),
    .btn_select(btn_select),
    .selected_cell(selected_cell),
    .shot_select(shot_select)
);

// FSM instance
battleship_combined_fsm fsm(
    .clk(clk),
    .reset(reset),
    .start_btn(start_btn),
    .reset_btn(reset_btn),
    .shot_select(shot_select),
    .hit(hit_detected),
    .all_ships_sunk(all_ships_sunk),
    .turns_exhausted(turns_exhausted),
    .current_state(game_state),
    .restart_pulse(restart_pulse)
);
assign shot_signals = (shot_select && game_state == 5'b00100) ? (100'b1 << selected_cell) : 100'b0;

// Grid cells instantiation
genvar i;
generate
    for (i = 0; i < 100; i = i + 1) begin : grid_cells
        grid_cell grid_inst(
            .clk(clk),
            .reset(reset || restart_pulse),
            .shot(shot_signals[i]),
            .is_ship(is_ship[i]),
            .ship_sunk(ship_sunk[i]),
            .cell_state(cell_states[i])
        );
    end
endgenerate

// Hit detection
hit_detector hit_det(
    .shot_signals(shot_signals),
    .is_ship(is_ship),
    .hit_detected(hit_detected)
);

// Ship status logic (determine sunk ships)
ship_status ship_stat(
    .clk(clk),
    .reset(reset || restart_pulse),
    .shot_signals(shot_signals),
    .is_ship(is_ship),
    .ship_sunk(ship_sunk),
    .all_ships_sunk(all_ships_sunk)
);

// Parameters
localparam MAX_TURNS = 15; // or desired number of turns

// Internal registers
reg [7:0] turns_remaining;
reg [99:0] is_ship;

// turns_exhausted signal
assign turns_exhausted = (turns_remaining == 0);

// Sequential logic for turn counting and ship initialization
always @(posedge clk or posedge reset or posedge restart_pulse) begin
    if (reset || restart_pulse) begin
        turns_remaining <= MAX_TURNS;
        is_ship <= 100'b0;  // Clear all ship positions initially
    end
    else begin
        case (game_state)
            5'b00010: begin // SETUP STATE
                turns_remaining <= MAX_TURNS;
                
                // Example hard-coded ship placement (for demonstration):
                is_ship[4:0]   <= 5'b11111;    // Carrier (size 5)
                is_ship[15:12] <= 4'b1111;     // Battleship (size 4)
                is_ship[22:20] <= 3'b111;      // Cruiser (size 3)
                is_ship[33:31] <= 3'b111;      // Submarine (size 3)
                is_ship[44:43] <= 2'b11;       // Destroyer (size 2)
                // Adjust or randomize as needed
            end
            
            5'b01000: begin // EVALUATE_SHOT STATE
                if (shot_select && turns_remaining > 0)
                    turns_remaining <= turns_remaining - 1;
            end
            
            default: begin
                // Maintain current values in other states
                turns_remaining <= turns_remaining;
                is_ship <= is_ship;
            end
        endcase
    end
end

endmodule
