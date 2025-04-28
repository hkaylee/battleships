`timescale 1ns / 1ps
module game_state(
  input  wire        clk,
  input  wire        reset,        // SW0: cycle through maps
  input  wire        btn_c,        // drop bomb
  input  wire [3:0]  sprite_row,   // cursor row
  input  wire [3:0]  sprite_col,   // cursor col
  input  wire        show_answer,  // SW1: reveal ships
  output reg  [199:0] cell_status_flat,
  output reg  [4:0]  turns_left,
  output reg  [2:0]  ships_remaining
);

  // -----------------------------------------------------------------------
  // Internal cell & ship arrays
  // -----------------------------------------------------------------------
  reg [1:0] cell_status [0:9][0:9];  // 00=water,01=miss,10=hit,11=sunk
  reg       ship_map    [0:9][0:9];  // 1=ship present
  reg [2:0] ship_id     [0:9][0:9];  // 1-5 for the 5 ships, 0 for no ship
  reg       ship1_sunk, ship2_sunk, ship3_sunk, ship4_sunk, ship5_sunk;
  integer   r, c;

  // -----------------------------------------------------------------------
  // Pattern counter: increment on rising edge of reset (SW0)
  // -----------------------------------------------------------------------
  reg reset_d;
  wire reset_rise;
  always @(posedge clk) reset_d <= reset;
  assign reset_rise = reset && !reset_d;

  // Modified to loop from 0 to 4 only
  reg [2:0] patternIndex = 0;
  always @(posedge clk)
    if (reset_rise)
      // Use modulo 5 instead of modulo 10 to keep looping 0-4
      patternIndex <= (patternIndex + 1) % 5;

  // -----------------------------------------------------------------------
  // Bomb-edge detect
  // -----------------------------------------------------------------------
  reg btnc_d;
  wire bomb_edge;
  always @(posedge clk) btnc_d <= btn_c;
  assign bomb_edge = btn_c && !btnc_d;

  // -----------------------------------------------------------------------
  // all_sunk flag 
  // -----------------------------------------------------------------------
  wire all_sunk =
       ship1_sunk
    && ship2_sunk
    && ship3_sunk
    && ship4_sunk
    && ship5_sunk;

  // -----------------------------------------------------------------------
  // Initial block for starting conditions
  // -----------------------------------------------------------------------
  initial begin
    // Initialize counters & sunk flags
    turns_left      = 5'd15;
    ships_remaining = 3'd5;
    ship1_sunk = 1'b0; ship2_sunk = 1'b0;
    ship3_sunk = 1'b0; ship4_sunk = 1'b0;
    ship5_sunk = 1'b0;

    // Clear arrays
    for (r = 0; r < 10; r = r + 1)
      for (c = 0; c < 10; c = c + 1) begin
        ship_map[r][c] = 1'b0;
        cell_status[r][c] = 2'b00;
        ship_id[r][c] = 3'd0;
      end

    // Place ships for pattern 0 (default starting pattern)
    // Ship 1 (length 6) horizontal at row 1, col 1-6
    for (c = 1; c <= 6; c = c + 1) begin
      ship_map[1][c] = 1'b1;
      ship_id[1][c] = 3'd1;
    end

    // Ship 2 (length 5) vertical at col 3, row 3-7
    for (r = 3; r <= 7; r = r + 1) begin
      ship_map[r][3] = 1'b1;
      ship_id[r][3] = 3'd2;
    end

    // Ship 3 (length 5) horizontal at row 5, col 5-9
    for (c = 5; c <= 9; c = c + 1) begin
      ship_map[5][c] = 1'b1;
      ship_id[5][c] = 3'd3;
    end

    // Ship 4 (length 3) vertical at col 8, row 0-2
    for (r = 0; r <= 2; r = r + 1) begin
      ship_map[r][8] = 1'b1;
      ship_id[r][8] = 3'd4;
    end

    // Ship 5 (length 3) vertical at col 0, row 7-9
    for (r = 7; r <= 9; r = r + 1) begin
      ship_map[r][0] = 1'b1;
      ship_id[r][0] = 3'd5;
    end
  end

  // Function to check if a position is valid for ship placement (no adjacency)
  function is_valid_position;
    input [3:0] row, col;
    reg valid;
    integer i, j;
    begin
      valid = 1'b1;
      for (i = -1; i <= 1; i = i + 1) begin
        for (j = -1; j <= 1; j = j + 1) begin
          if (row+i >= 0 && row+i < 10 && col+j >= 0 && col+j < 10) begin
            if (ship_map[row+i][col+j] == 1'b1) valid = 1'b0;
          end
        end
      end
      is_valid_position = valid;
    end
  endfunction

  // -----------------------------------------------------------------------
  // Main sequential: reset & place vs. gameplay
  // -----------------------------------------------------------------------
  always @(posedge clk) begin
    if (reset) begin
      // - reset counters & sunk flags
      turns_left      <= 5'd15;
      ships_remaining <= 3'd5;
      ship1_sunk <= 1'b0; ship2_sunk <= 1'b0;
      ship3_sunk <= 1'b0; ship4_sunk <= 1'b0;
      ship5_sunk <= 1'b0;

      // - clear arrays
      for (r = 0; r < 10; r = r + 1)
        for (c = 0; c < 10; c = c + 1) begin
          ship_map[r][c] <= 1'b0;
          cell_status[r][c] <= 2'b00;
          ship_id[r][c] <= 3'd0;
        end

      // - place ships according to patternIndex (now 0-4 only)
      case (patternIndex)
        // Pattern 0
        3'd0: begin
          // Ship 1 (length 6) horizontal at row 1, col 1-6
          for (c = 1; c <= 6; c = c + 1) begin
            ship_map[1][c] <= 1'b1;
            ship_id[1][c] <= 3'd1;
          end

          // Ship 2 (length 5) vertical at col 3, row 3-7
          for (r = 3; r <= 7; r = r + 1) begin
            ship_map[r][3] <= 1'b1;
            ship_id[r][3] <= 3'd2;
          end

          // Ship 3 (length 5) horizontal at row 5, col 5-9
          for (c = 5; c <= 9; c = c + 1) begin
            ship_map[5][c] <= 1'b1;
            ship_id[5][c] <= 3'd3;
          end

          // Ship 4 (length 3) vertical at col 8, row 0-2
          for (r = 0; r <= 2; r = r + 1) begin
            ship_map[r][8] <= 1'b1;
            ship_id[r][8] <= 3'd4;
          end

          // Ship 5 (length 3) vertical at col 0, row 7-9
          for (r = 7; r <= 9; r = r + 1) begin
            ship_map[r][0] <= 1'b1;
            ship_id[r][0] <= 3'd5;
          end
        end
        // Pattern 1 - ensuring no adjacency
        3'd1: begin
          // Ship 1 (length 6) horizontal at row 0, col 0-5
          for (c = 0; c <= 5; c = c + 1) begin
            ship_map[0][c] <= 1'b1;
            ship_id[0][c] <= 3'd1;
          end

          // Ship 2 (length 5) vertical at col 2, row 2-6
          for (r = 2; r <= 6; r = r + 1) begin
            ship_map[r][2] <= 1'b1;
            ship_id[r][2] <= 3'd2;
          end

          // Ship 3 (length 5) horizontal at row 8, col 4-8
          for (c = 4; c <= 8; c = c + 1) begin
            ship_map[8][c] <= 1'b1;
            ship_id[8][c] <= 3'd3;
          end

          // Ship 4 (length 3) vertical at col 9, row 0-2
          for (r = 0; r <= 2; r = r + 1) begin
            ship_map[r][9] <= 1'b1;
            ship_id[r][9] <= 3'd4;
          end

          // Ship 5 (length 3) vertical at col 0, row 7-9
          for (r = 7; r <= 9; r = r + 1) begin
            ship_map[r][0] <= 1'b1;
            ship_id[r][0] <= 3'd5;
          end
        end
        // Pattern 2 - ensuring no adjacency
        3'd2: begin
          // Ship 1 (length 6) vertical at col 0, row 0-5
          for (r = 0; r <= 5; r = r + 1) begin
            ship_map[r][0] <= 1'b1;
            ship_id[r][0] <= 3'd1;
          end

          // Ship 2 (length 5) horizontal at row 7, col 2-6
          for (c = 2; c <= 6; c = c + 1) begin
            ship_map[7][c] <= 1'b1;
            ship_id[7][c] <= 3'd2;
          end

          // Ship 3 (length 5) vertical at col 9, row 2-6
          for (r = 2; r <= 6; r = r + 1) begin
            ship_map[r][9] <= 1'b1;
            ship_id[r][9] <= 3'd3;
          end

          // Ship 4 (length 3) horizontal at row 0, col 7-9
          for (c = 7; c <= 9; c = c + 1) begin
            ship_map[0][c] <= 1'b1;
            ship_id[0][c] <= 3'd4;
          end

          // Ship 5 (length 3) horizontal at row 9, col 0-2
          for (c = 0; c <= 2; c = c + 1) begin
            ship_map[9][c] <= 1'b1;
            ship_id[9][c] <= 3'd5;
          end
        end
        // Pattern 3 - ensuring no adjacency
        3'd3: begin
          // Ship 1 (length 6) horizontal at row 9, col 4-9
          for (c = 4; c <= 9; c = c + 1) begin
            ship_map[9][c] <= 1'b1;
            ship_id[9][c] <= 3'd1;
          end

          // Ship 2 (length 5) vertical at col 3, row 0-4
          for (r = 0; r <= 4; r = r + 1) begin
            ship_map[r][3] <= 1'b1;
            ship_id[r][3] <= 3'd2;
          end

          // Ship 3 (length 5) horizontal at row 6, col 0-4
          for (c = 0; c <= 4; c = c + 1) begin
            ship_map[6][c] <= 1'b1;
            ship_id[6][c] <= 3'd3;
          end

          // Ship 4 (length 3) vertical at col 7, row 0-2
          for (r = 0; r <= 2; r = r + 1) begin
            ship_map[r][7] <= 1'b1;
            ship_id[r][7] <= 3'd4;
          end

          // Ship 5 (length 3) vertical at col 0, row 0-2
          for (r = 0; r <= 2; r = r + 1) begin
            ship_map[r][0] <= 1'b1;
            ship_id[r][0] <= 3'd5;
          end
        end
        // Pattern 4
        3'd4: begin
          // Ship 1 (length 6) vertical at col 9, row 0-5
          for (r = 0; r <= 5; r = r + 1) begin
            ship_map[r][9] <= 1'b1;
            ship_id[r][9] <= 3'd1;
          end

          // Ship 2 (length 5) horizontal at row 0, col 2-6
          for (c = 2; c <= 6; c = c + 1) begin
            ship_map[0][c] <= 1'b1;
            ship_id[0][c] <= 3'd2;
          end

          // Ship 3 (length 5) vertical at col 4, row 3-7
          for (r = 3; r <= 7; r = r + 1) begin
            ship_map[r][4] <= 1'b1;
            ship_id[r][4] <= 3'd3;
          end

          // Ship 4 (length 3) horizontal at row 8, col 0-2
          for (c = 0; c <= 2; c = c + 1) begin
            ship_map[8][c] <= 1'b1;
            ship_id[8][c] <= 3'd4;
          end

          // Ship 5 (length 3) horizontal at row 2, col 0-2
          for (c = 0; c <= 2; c = c + 1) begin
            ship_map[2][c] <= 1'b1;
            ship_id[2][c] <= 3'd5;
          end
        end
      endcase

    end else begin
      // - gameplay: drop bombs & decrement turns -
      if (bomb_edge && turns_left > 0 && !all_sunk) begin
        if (cell_status[sprite_row][sprite_col] == 2'b00) begin
          if (ship_map[sprite_row][sprite_col])
            cell_status[sprite_row][sprite_col] <= 2'b10;  // hit
          else begin
            cell_status[sprite_row][sprite_col] <= 2'b01;  // miss
            turns_left <= turns_left - 1;
          end
        end
      end

      // - immediate sinking check for each ship -
      
      // Check if ship1 (length 6) is sunk
      if (!ship1_sunk) begin
        ship1_sunk = 1'b1; // Assume sunk initially
        for (r = 0; r < 10; r = r + 1) begin
          for (c = 0; c < 10; c = c + 1) begin
            if (ship_id[r][c] == 3'd1 && cell_status[r][c] != 2'b10)
              ship1_sunk = 1'b0; // Not sunk if any part isn't hit
          end
        end
        
        // If ship is sunk, update all its cells to sunk status (2'b11)
        if (ship1_sunk) begin
          for (r = 0; r < 10; r = r + 1) begin
            for (c = 0; c < 10; c = c + 1) begin
              if (ship_id[r][c] == 3'd1)
                cell_status[r][c] <= 2'b11;
            end
          end
          ships_remaining <= ships_remaining - 1;
        end
      end

      // Check if ship2 (length 5) is sunk
      if (!ship2_sunk) begin
        ship2_sunk = 1'b1; // Assume sunk initially
        for (r = 0; r < 10; r = r + 1) begin
          for (c = 0; c < 10; c = c + 1) begin
            if (ship_id[r][c] == 3'd2 && cell_status[r][c] != 2'b10)
              ship2_sunk = 1'b0; // Not sunk if any part isn't hit
          end
        end
        
        // If ship is sunk, update all its cells to sunk status (2'b11)
        if (ship2_sunk) begin
          for (r = 0; r < 10; r = r + 1) begin
            for (c = 0; c < 10; c = c + 1) begin
              if (ship_id[r][c] == 3'd2)
                cell_status[r][c] <= 2'b11;
            end
          end
          ships_remaining <= ships_remaining - 1;
        end
      end

      // Check if ship3 (length 5) is sunk
      if (!ship3_sunk) begin
        ship3_sunk = 1'b1; // Assume sunk initially
        for (r = 0; r < 10; r = r + 1) begin
          for (c = 0; c < 10; c = c + 1) begin
            if (ship_id[r][c] == 3'd3 && cell_status[r][c] != 2'b10)
              ship3_sunk = 1'b0; // Not sunk if any part isn't hit
          end
        end
        
        // If ship is sunk, update all its cells to sunk status (2'b11)
        if (ship3_sunk) begin
          for (r = 0; r < 10; r = r + 1) begin
            for (c = 0; c < 10; c = c + 1) begin
              if (ship_id[r][c] == 3'd3)
                cell_status[r][c] <= 2'b11;
            end
          end
          ships_remaining <= ships_remaining - 1;
        end
      end

      // Check if ship4 (length 3) is sunk
      if (!ship4_sunk) begin
        ship4_sunk = 1'b1; // Assume sunk initially
        for (r = 0; r < 10; r = r + 1) begin
          for (c = 0; c < 10; c = c + 1) begin
            if (ship_id[r][c] == 3'd4 && cell_status[r][c] != 2'b10)
              ship4_sunk = 1'b0; // Not sunk if any part isn't hit
          end
        end
        
        // If ship is sunk, update all its cells to sunk status (2'b11)
        if (ship4_sunk) begin
          for (r = 0; r < 10; r = r + 1) begin
            for (c = 0; c < 10; c = c + 1) begin
              if (ship_id[r][c] == 3'd4)
                cell_status[r][c] <= 2'b11;
            end
          end
          ships_remaining <= ships_remaining - 1;
        end
      end

      // Check if ship5 (length 3) is sunk
      if (!ship5_sunk) begin
        ship5_sunk = 1'b1; // Assume sunk initially
        for (r = 0; r < 10; r = r + 1) begin
          for (c = 0; c < 10; c = c + 1) begin
            if (ship_id[r][c] == 3'd5 && cell_status[r][c] != 2'b10)
              ship5_sunk = 1'b0; // Not sunk if any part isn't hit
          end
        end
        
        // If ship is sunk, update all its cells to sunk status (2'b11)
        if (ship5_sunk) begin
          for (r = 0; r < 10; r = r + 1) begin
            for (c = 0; c < 10; c = c + 1) begin
              if (ship_id[r][c] == 3'd5)
                cell_status[r][c] <= 2'b11;
            end
          end
          ships_remaining <= ships_remaining - 1;
        end
      end
    end
  end

  // -----------------------------------------------------------------------
  // Flatten & optional reveal of ships
  // -----------------------------------------------------------------------
  always @(*) begin
    for (r = 0; r < 10; r = r + 1) begin
      for (c = 0; c < 10; c = c + 1) begin
        if (show_answer && !all_sunk && ship_map[r][c])
          cell_status_flat[(r*10 + c)*2 +:2] = 2'b11;
        else
          cell_status_flat[(r*10 + c)*2 +:2] = cell_status[r][c];
      end
    end
  end

endmodule