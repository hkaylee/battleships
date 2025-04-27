`timescale 1ns / 1ps
module game_state(
  input  wire        clk,
  input  wire        reset,
  input  wire        btn_c,
  input  wire [3:0]  sprite_row,
  input  wire [3:0]  sprite_col,
  output reg  [199:0] cell_status_flat,  // Flattened 2-bit * 100 cells
  output reg  [4:0]  turns_left,
  output reg         win,
  output reg         lose
);

  // Internal 2D cell status memory
  reg [1:0] cell_status [0:9][0:9];
  reg       ship_map    [0:9][0:9];
  integer r, c;
  reg all_hit;
  reg btnc_d;
  wire bomb_edge;
  always @(posedge clk) btnc_d <= btn_c;
  assign bomb_edge = btn_c & ~btnc_d;

  // Initialize ships and state
  initial begin
    turns_left = 5'd15;
    win        = 1'b0;
    lose       = 1'b0;
    for (r = 0; r < 10; r = r + 1) begin
      for (c = 0; c < 10; c = c + 1) begin
        ship_map[r][c]    = 1'b0;
        cell_status[r][c] = 2'b00;  // water
      end
    end
    // Big ship (6) horizontal row 1, col 1-6
    for (c = 1; c <= 6; c = c + 1) ship_map[1][c] = 1'b1;
    // Medium (5) vertical col 3, row 3-7
    for (r = 3; r <= 7; r = r + 1) ship_map[r][3] = 1'b1;
    // Medium (5) horizontal row 5, col 5-9
    for (c = 5; c <= 9; c = c + 1) ship_map[5][c] = 1'b1;
    // Small (3) vertical col 8, row 0-2
    for (r = 0; r <= 2; r = r + 1) ship_map[r][8] = 1'b1;
    // Small (3) vertical col 0, row 7-9
    for (r = 7; r <= 9; r = r + 1) ship_map[r][0] = 1'b1;
  end

  // Main game logic
  always @(posedge clk) begin
    if (reset) begin
      turns_left <= 5'd15;
      win        <= 1'b0;
      lose       <= 1'b0;
      for (r = 0; r < 10; r = r + 1)
        for (c = 0; c < 10; c = c + 1)
          cell_status[r][c] <= 2'b00;
    end else if (bomb_edge && !win && !lose) begin
      // Drop bomb if not already bombed
      if (cell_status[sprite_row][sprite_col] == 2'b00) begin
        if (ship_map[sprite_row][sprite_col]) begin
          // Hit: mark hit (black)
          cell_status[sprite_row][sprite_col] <= 2'b10;
        end else begin
          // Miss: mark miss (gray) and decrement turns
          cell_status[sprite_row][sprite_col] <= 2'b01;
          if (turns_left == 5'd1) lose <= 1'b1;
          turns_left <= turns_left - 1;
        end
      end

      // Check if all ship squares have been hit
      all_hit = 1'b1;
      for (r = 0; r < 10; r = r + 1) begin
        for (c = 0; c < 10; c = c + 1) begin
          if (ship_map[r][c] && cell_status[r][c] != 2'b10)
            all_hit = 1'b0;
        end
      end
      if (all_hit) begin
        // Mark sunk (red)
        for (r = 0; r < 10; r = r + 1)
          for (c = 0; c < 10; c = c + 1)
            if (ship_map[r][c]) cell_status[r][c] <= 2'b11;
        win <= 1'b1;
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