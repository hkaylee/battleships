
//////////////////////////////////////////////////
// Module: game_restart_control
//////////////////////////////////////////////////
// This module produces a one-cycle pulse that signals a restart (or new game)
// when the external game FSM is in a done/idle state.
// It assumes that the start and reset buttons are debounced and produce a pulse when pressed.
module game_restart_control (
    input  wire clk,          // System clock
    input  wire idle_state,   // High when the game FSM is in idle/done state
    input  wire start_btn,    // Debounced start button (active high)
    input  wire reset_btn,    // Debounced reset button (active high)
    output reg  restart_pulse // One-cycle pulse to indicate game restart
);

    always @(posedge clk) begin
        // When in idle/done state, if either button is pressed,
        // assert restart_pulse for one clock cycle.
        if (idle_state && (start_btn || reset_btn))
            restart_pulse <= 1'b1;
        else
            restart_pulse <= 1'b0;
    end

endmodule