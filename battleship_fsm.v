module battleship_fsm (
    input  wire       clk,
    input  wire       reset,           // Asynchronous reset signal
    input  wire       start_btn,       // Debounced start button (active high)
    input  wire       reset_btn,       // Debounced reset button (active high)
    input  wire       shot_select,     // Player selects a cell
    input  wire       hit,             // Outcome: 1 = hit, 0 = miss
    input  wire       all_ships_sunk,  // Indicates win
    input  wire       turns_exhausted, // No turns remaining
    output reg  [4:0] current_state,   // One-hot encoding for the game state
    output reg        restart_pulse    // One-cycle pulse to indicate game restart
    output wire [4:0] current_state,
    output wire restart_pulse

);

    // One-hot encoded states
    localparam STATE_IDLE          = 5'b00001;
    localparam STATE_SETUP         = 5'b00010;
    localparam STATE_PLAYER_TURN   = 5'b00100;
    localparam STATE_EVALUATE_SHOT = 5'b01000;
    localparam STATE_GAME_OVER     = 5'b10000;

    reg [4:0] next_state;

    // Sequential logic: update state on rising clock edge or asynchronous reset
    always @(posedge clk or posedge reset) begin
        if (reset)
            current_state <= STATE_IDLE;
        else
            current_state <= next_state;
    end

    always @(*) begin
        next_state = current_state;
        case (current_state)
            STATE_IDLE: begin
                if (start_btn || reset_btn)
                    next_state = STATE_SETUP;
            end

            STATE_SETUP: begin
                next_state = STATE_PLAYER_TURN;
            end

            STATE_PLAYER_TURN: begin
                if (shot_select)
                    next_state = STATE_EVALUATE_SHOT;
            end

            STATE_EVALUATE_SHOT: begin
                if (all_ships_sunk || turns_exhausted)
                    next_state = STATE_GAME_OVER;
                else
                    next_state = STATE_PLAYER_TURN;
            end

            STATE_GAME_OVER: begin
                if (start_btn || reset_btn)
                    next_state = STATE_IDLE;
            end

            default: next_state = STATE_IDLE;
        endcase
    end

    // Game restart pulse logic
    always @(posedge clk) begin
        restart_pulse <= (current_state == STATE_IDLE && (start_btn || reset_btn));
    end

endmodule
