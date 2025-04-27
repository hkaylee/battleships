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

  // temp variables
  integer r, c;
  reg all_hit; // <-- moved here!

  initial begin
    for (r = 0; r < 10; r = r + 1)
      for (c = 0; c < 10; c = c + 1) begin
        ship_map[r][c]    = 0;
        cell_status[r][c] = 2'b00;
      end

    // Hard-coded ship placements
    for (c = 1; c <= 6; c = c + 1) ship_map[1][c] = 1; // Big horizontal ship
    for (r = 3; r <= 7; r = r + 1) ship_map[r][3] = 1; // Medium vertical
    for (c = 5; c <= 9; c = c + 1) ship_map[5][c] = 1; // Medium horizontal
    for (r = 0; r <= 2; r = r + 1) ship_map[r][8] = 1; // Small vertical
    for (r = 7; r <= 9; r = r + 1) ship_map[r][0] = 1; // Small vertical

    turns_left = 5'd15;
    win = 0;
    lose = 0;
  end

  // Edge detect for btn_c
  reg btnc_d;
  wire bomb_edge;
  always @(posedge clk) btnc_d <= btn_c;
  assign bomb_edge = btn_c & ~btnc_d;

  // Game logic
  always @(posedge clk) begin
    if (reset) begin
      turns_left <= 15;
      win <= 0;
      lose <= 0;
      for (r = 0; r < 10; r = r + 1)
        for (c = 0; c < 10; c = c + 1)
          cell_status[r][c] <= 2'b00;
    end else if (bomb_edge && !win && !lose) begin
      if (cell_status[sprite_row][sprite_col] == 2'b00) begin
        if (ship_map[sprite_row][sprite_col]) begin
          cell_status[sprite_row][sprite_col] <= 2'b10; // hit
        end else begin
          cell_status[sprite_row][sprite_col] <= 2'b01; // miss
          turns_left <= turns_left - 1;
        end
      end

      // Check for win
      all_hit = 1;
      for (r = 0; r < 10; r = r + 1)
        for (c = 0; c < 10; c = c + 1)
          if (ship_map[r][c] && cell_status[r][c] != 2'b10)
            all_hit = 0;

      if (all_hit) begin
        for (r = 0; r < 10; r = r + 1)
          for (c = 0; c < 10; c = c + 1)
            if (ship_map[r][c]) cell_status[r][c] <= 2'b11; // sunk
        win <= 1;
      end

      if (turns_left == 1 && !win)
        lose <= 1;
    end
  end

  // Flattening 2D array into 1D output
  always @(*) begin
    for (r = 0; r < 10; r = r + 1)
      for (c = 0; c < 10; c = c + 1)
        cell_status_flat[(r*10 + c)*2 +: 2] = cell_status[r][c];
  end

endmodule
