`timescale 1ns / 1ps

module battleship_tb;

    // Inputs
    reg         clk;
    reg         reset;
    reg         start_btn;
    reg         reset_btn;
    reg         btn_up;
    reg         btn_down;
    reg         btn_left;
    reg         btn_right;
    reg         btn_select;

    // Outputs
    wire [399:0] cell_state_flat;
    wire [4:0]   ships_sunk;
    wire [7:0]   hit_count;
    
    // Internal taps
    wire [6:0]   sel_cell    = uut.selected_cell;
    wire [3:0]   cell_state  = cell_state_flat[sel_cell*4 +: 4];
    wire [7:0]   turns_left  = uut.turns_remaining;
    wire [4:0]   game_state  = uut.game_state;
    wire         shot_sel    = uut.shot_select;
    wire         hit         = uut.hit_detected;

    // Instantiate the DUT, now exporting ships_sunk
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
        .cell_state_flat(cell_state_flat),
        .hit_detected(hit_detected),
        .ships_sunk(ships_sunk),
        .hit_count(hit_count)
    );

    // 100 MHz clock
    always #5 clk = ~clk;

    // Helper task: move cursor to `target` (0-99) then fire
    task shoot_at(input [6:0] target);
      integer curr_row, curr_col, tar_row, tar_col, i;
      begin
        // read current cursor position
        curr_row = uut.cursor.cursor_row;
        curr_col = uut.cursor.cursor_col;
        tar_row  = target / 10;
        tar_col  = target % 10;

        // vertical moves
        if (tar_row > curr_row) begin
          for (i = 0; i < tar_row - curr_row; i = i + 1) begin
            btn_down = 1; #10 btn_down = 0; #10;
          end
        end else begin
          for (i = 0; i < curr_row - tar_row; i = i + 1) begin
            btn_up = 1; #10 btn_up = 0; #10;
          end
        end

        // horizontal moves
        if (tar_col > curr_col) begin
          for (i = 0; i < tar_col - curr_col; i = i + 1) begin
            btn_right = 1; #10 btn_right = 0; #10;
          end
        end else begin
          for (i = 0; i < curr_col - tar_col; i = i + 1) begin
            btn_left = 1; #10 btn_left = 0; #10;
          end
        end

        // fire
        #10 btn_select = 1; #10 btn_select = 0; #10;

      end
    endtask

    initial begin
        // init
        clk        = 0;
        reset      = 1;
        start_btn  = 0;
        reset_btn  = 0;
        btn_up     = 0;
        btn_down   = 0;
        btn_left   = 0;
        btn_right  = 0;
        btn_select = 0;

        // reset pulse
        #20 reset = 0;

        // start game and wait for SETUP → SHOOT state
        #20 start_btn = 1; #10 start_btn = 0;
        wait (game_state == 5'b00100);
        // Carrier (0-4)
        for (integer i = 0; i < 5; i = i + 1) shoot_at(i);
        if (!ships_sunk[4]) $error("Carrier (size 5) not sunk!");
        else                $display("Carrier sunk ok.");

        // Battleship (12-15)
        for (integer i = 12; i <= 15; i = i + 1) shoot_at(i);
        if (!ships_sunk[3]) $error("Battleship (size 4) not sunk!");
        else                $display("Battleship sunk ok.");

        // Cruiser (20-22)
        for (integer i = 20; i <= 22; i = i + 1) shoot_at(i);
        if (!ships_sunk[2]) $error("Cruiser (size 3) not sunk!");
        else                $display("Cruiser sunk ok.");

        // Submarine (31-33)
        for (integer i = 31; i <= 33; i = i + 1) shoot_at(i);
        if (!ships_sunk[1]) $error("Submarine (size 3) not sunk!");
        else                $display("Submarine sunk ok.");

        // Destroyer (43-44)
        for (integer i = 43; i <= 44; i = i + 1) shoot_at(i);
        if (!ships_sunk[0]) $error("Destroyer (size 2) not sunk!");
        else                $display("Destroyer sunk ok.");

        // final check: all five ships gone?
        if (ships_sunk != 5'b11111)
          $error("Not all ships sunk! ships_sunk = %b", ships_sunk);
        else
          $display("All ships sunk! Test PASSED.");

        #50 $finish;
    end

    // optional debug
    initial begin
    $dumpfile("battleship.vcd");

  $dumpvars(0, battleship_tb);
      $display("time sel state turns gs   hit ships");
      $monitor("%0t %0d %b %0d %b |%b   %b", 
               $time, sel_cell, cell_state, turns_left, game_state, hit, ships_sunk);
    end

endmodule
