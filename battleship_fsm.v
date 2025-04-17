//////////////////////////////////////////////////
// Module: battleship_fsm
//////////////////////////////////////////////////
module battleship_fsm (
    input  wire       clk,
    input  wire       reset,           // Asynchronous reset signal
    input  wire       start,           // Switch to start/restart game
    input  wire       shot_select,     // Player selects a cell
    input  wire       hit,             // Outcome: 1 = hit, 0 = miss (may be used for additional logic)
    input  wire       all_ships_sunk,  // Indicates win
    input  wire       turns_exhausted, // No turns remaining 
    output reg  [4:0] current_state    // One-hot encoding for the game state
);

    // One-hot encoded states (5 states)
    localparam STATE_IDLE         = 5'b00001;
    localparam STATE_SETUP        = 5'b00010;
    localparam STATE_PLAYER_TURN  = 5'b00100;
    localparam STATE_EVALUATE_SHOT= 5'b01000;
    localparam STATE_GAME_OVER    = 5'b10000;

    reg [4:0] next_state;

    // Sequential logic: update state on rising clock edge or asynchronous reset
    always @(posedge clk or posedge reset) begin
        if (reset)
            current_state <= STATE_IDLE;
        else
            current_state <= next_state;
    end

    always @(*) begin
        // Default stays in the same state
        next_state = current_state;
        case (current_state)
            STATE_IDLE: begin
                if (start)
                    next_state = STATE_SETUP;
                else
                    next_state = STATE_IDLE;
            end

            STATE_SETUP: begin
                // Assume immediate setup (grid initialization, ship placement, reset turn count)
                next_state = STATE_PLAYER_TURN;
            end

            STATE_PLAYER_TURN: begin
                // Wait for the player to select a cell
                if (shot_select)
                    next_state = STATE_EVALUATE_SHOT;
                else
                    next_state = STATE_PLAYER_TURN;
            end

            STATE_EVALUATE_SHOT: begin
                // Evaluate the shot result. Check for win or loss conditions.
                if (all_ships_sunk)
                    next_state = STATE_GAME_OVER;  // Win condition
                else if (turns_exhausted)
                    next_state = STATE_GAME_OVER;  // Loss condition
                else
                    next_state = STATE_PLAYER_TURN; // Continue the game
            end

            STATE_GAME_OVER: begin
                // Wait for a restart command
                if (start)
                    next_state = STATE_IDLE;
                else
                    next_state = STATE_GAME_OVER;
            end

            default: next_state = STATE_IDLE;
        endcase
    end

endmodule
