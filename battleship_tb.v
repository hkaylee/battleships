`timescale 1ns / 1ps

module battleship_tb;

    reg clk;
    reg reset;
    reg start_btn;
    reg reset_btn;
    reg btn_up;
    reg btn_down;
    reg btn_left;
    reg btn_right;
    reg btn_select;

    wire [399:0] cell_state_flat;

    // Instantiate the Battleship Top Module
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

    // Monitor selected cell state for debug
    wire [6:0] sel_cell = uut.selected_cell;
    wire [3:0] current_cell_state = cell_state_flat[sel_cell*4 +: 4];

    initial begin
        $monitor("Time=%0t | Selected Cell=%0d | State=%b", $time, sel_cell, current_cell_state);
    end

    // Clock generation
    always #5 clk = ~clk; // 100MHz clock frequency

    initial begin
        // Initial reset
        clk = 0;
        reset = 1;
        start_btn = 0;
        reset_btn = 0;
        btn_up = 0;
        btn_down = 0;
        btn_left = 0;
        btn_right = 0;
        btn_select = 0;

        // Release reset
        #20 reset = 0;

        // Start game
        #20 start_btn = 1;
        #10 start_btn = 0;

        // Simulate cursor movements and selections
        #30 btn_right = 1; #10 btn_right = 0;
        #10 btn_right = 1; #10 btn_right = 0;
        #10 btn_down = 1;  #10 btn_down = 0;
        #10 btn_select = 1; #10 btn_select = 0; // Fire shot at selected cell

        // Additional moves/shots
        #50 btn_left = 1;  #10 btn_left = 0;
        #10 btn_up = 1;    #10 btn_up = 0;
        #10 btn_select = 1; #10 btn_select = 0;

        // Wait and then restart
        #200 reset_btn = 1; #10 reset_btn = 0;

        #100 $stop; // End simulation
    end

endmodule
