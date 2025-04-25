`timescale 1ns / 1ps

module battleship_tb;

    // Inputs
    reg clk;
    reg reset;
    reg start_btn;
    reg reset_btn;
    reg btn_up;
    reg btn_down;
    reg btn_left;
    reg btn_right;
    reg btn_select;

    // Outputs
    wire [399:0] cell_state_flat;

    // Instantiate the DUT
    battleship_top uut (
        .clk(clk),
        .reset(reset),
        .start_btn(start_btn),
        .reset_btn(reset_btn),
        .btn_up(btn_up),
        .btn_down(btn_down),
        .btn_left(btn_left),
        .btn_right(btn_right),
        .btn_select(btn_select),
        .cell_state_flat(cell_state_flat)
    );

    // Generate a clock: 100 MHz
    always #5 clk = ~clk;

    // Watch selected cell
    wire [6:0] sel_cell = uut.selected_cell;
    wire [3:0] cell_state = cell_state_flat[sel_cell*4 +: 4];
    wire [7:0] turns_remaining = uut.turns_remaining;
    wire [4:0] game_state = uut.game_state;
    wire shot_select = uut.shot_select;
    wire hit = uut.hit_detected;
    wire shot = uut.shot_select;


    // Debug display
initial begin
    $display("Time\tSelCell\tState\tTurnsLeft\tGameState");
    $monitor("%t\t%0d\t%b\t%0d\t%b", $time, sel_cell, cell_state, turns_remaining, game_state);
end

    initial begin
        // Initialize signals
        clk = 0;
        reset = 1;
        start_btn = 0;
        reset_btn = 0;
        btn_up = 0;
        btn_down = 0;
        btn_left = 0;
        btn_right = 0;
        btn_select = 0;

        // Reset pulse
        #20 reset = 0;

        // Start game
        #20 start_btn = 1;
        #10 start_btn = 0;

        // Move to the right 3 times
        #30 btn_right = 1; #10 btn_right = 0;
        #10 btn_right = 1; #10 btn_right = 0;
        #10 btn_right = 1; #10 btn_right = 0;

        // Move down 2 times
        #10 btn_down = 1; #10 btn_down = 0;
        #10 btn_down = 1; #10 btn_down = 0;

        // Fire shot
        #10 btn_select = 1; #10 btn_select = 0;

        // Move and fire again
        #30 btn_left = 1; #10 btn_left = 0;
        #10 btn_up = 1; #10 btn_up = 0;
        #10 btn_select = 1; #10 btn_select = 0;

        // Simulate game restart
        #100 reset_btn = 1; #10 reset_btn = 0;

        // Wait and stop
        #200 $finish;
    end

endmodule
