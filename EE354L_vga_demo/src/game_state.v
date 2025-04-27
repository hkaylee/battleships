`timescale 1ns / 1ps
module game_state(
  input  wire        clk,
  input  wire        reset,
  input  wire        btn_c,
  input  wire [3:0]  sprite_row,
  input  wire [3:0]  sprite_col,
  output reg  [199:0] cell_status_flat,  // Flattened 2-bit * 100 cells
  output reg  [4:0]  turns_left
);

  // Internal 2D cell status memory and ship sunk flags
  reg [1:0] cell_status [0:9][0:9];
  reg       ship_map    [0:9][0:9];
  reg       ship1_sunk, ship2_sunk, ship3_sunk, ship4_sunk, ship5_sunk;
  integer r, c;
  reg btnc_d;
  wire bomb_edge;
  always @(posedge clk) btnc_d <= btn_c;
  assign bomb_edge = btn_c & ~btnc_d;

  // Initialize ships and state
  initial begin
    turns_left   = 5'd15;
    ship1_sunk   = 1'b0;
    ship2_sunk   = 1'b0;
    ship3_sunk   = 1'b0;
    ship4_sunk   = 1'b0;
    ship5_sunk   = 1'b0;
    for (r = 0; r < 10; r = r + 1) begin
      for (c = 0; c < 10; c = c + 1) begin
        ship_map[r][c]    = 1'b0;
        cell_status[r][c] = 2'b00;  // water
      end
    end
    // Define ships
    for (c = 1; c <= 6; c = c + 1) ship_map[1][c] = 1'b1; // ship1 length6
    for (r = 3; r <= 7; r = r + 1) ship_map[r][3] = 1'b1; // ship2 length5
    for (c = 5; c <= 9; c = c + 1) ship_map[5][c] = 1'b1; // ship3 length5
    for (r = 0; r <= 2; r = r + 1) ship_map[r][8] = 1'b1; // ship4 length3
    for (r = 7; r <= 9; r = r + 1) ship_map[r][0] = 1'b1; // ship5 length3
  end

  // Main game logic
  always @(posedge clk) begin
    if (reset) begin
      turns_left   <= 5'd15;
      ship1_sunk   <= 1'b0;
      ship2_sunk   <= 1'b0;
      ship3_sunk   <= 1'b0;
      ship4_sunk   <= 1'b0;
      ship5_sunk   <= 1'b0;
      for (r = 0; r < 10; r = r + 1)
        for (c = 0; c < 10; c = c + 1)
          cell_status[r][c] <= 2'b00;
    end else if (bomb_edge && turns_left > 0) begin
      // Drop bomb if square not yet bombed
      if (cell_status[sprite_row][sprite_col] == 2'b00) begin
        if (ship_map[sprite_row][sprite_col]) begin
          // Hit: mark hit (black)
          cell_status[sprite_row][sprite_col] <= 2'b10;
        end else begin
          // Miss: mark miss (gray) and decrement turns
          cell_status[sprite_row][sprite_col] <= 2'b01;
          turns_left <= turns_left - 1;
        end
      end
      // Check each ship for sunk status
      // Ship1 (row1, col1-6)
      if (!ship1_sunk) begin
        if (&{cell_status[1][1]==2'b10, cell_status[1][2]==2'b10,
              cell_status[1][3]==2'b10, cell_status[1][4]==2'b10,
              cell_status[1][5]==2'b10, cell_status[1][6]==2'b10}) begin
          for (c = 1; c <= 6; c = c + 1)
            cell_status[1][c] <= 2'b11;
          ship1_sunk <= 1'b1;
        end
      end
      // Ship2 (col3, row3-7)
      if (!ship2_sunk) begin
        if (&{cell_status[3][3]==2'b10, cell_status[4][3]==2'b10,
              cell_status[5][3]==2'b10, cell_status[6][3]==2'b10,
              cell_status[7][3]==2'b10}) begin
          for (r = 3; r <= 7; r = r + 1)
            cell_status[r][3] <= 2'b11;
          ship2_sunk <= 1'b1;
        end
      end
      // Ship3 (row5, col5-9)
      if (!ship3_sunk) begin
        if (&{cell_status[5][5]==2'b10, cell_status[5][6]==2'b10,
              cell_status[5][7]==2'b10, cell_status[5][8]==2'b10,
              cell_status[5][9]==2'b10}) begin
          for (c = 5; c <= 9; c = c + 1)
            cell_status[5][c] <= 2'b11;
          ship3_sunk <= 1'b1;
        end
      end
      // Ship4 (col8, row0-2)
      if (!ship4_sunk) begin
        if (&{cell_status[0][8]==2'b10, cell_status[1][8]==2'b10,
              cell_status[2][8]==2'b10}) begin
          for (r = 0; r <= 2; r = r + 1)
            cell_status[r][8] <= 2'b11;
          ship4_sunk <= 1'b1;
        end
      end
      // Ship5 (col0, row7-9)
      if (!ship5_sunk) begin
        if (&{cell_status[7][0]==2'b10, cell_status[8][0]==2'b10,
              cell_status[9][0]==2'b10}) begin
          for (r = 7; r <= 9; r = r + 1)
            cell_status[r][0] <= 2'b11;
          ship5_sunk <= 1'b1;
        end
      end
    end
  end

  // Flatten 2D cell_status into 1D bus
  always @(*) begin
    for (r = 0; r < 10; r = r + 1)
      for (c = 0; c < 10; c = c + 1)
        cell_status_flat[(r*10+c)*2 +: 2] = cell_status[r][c];
  end
endmodule