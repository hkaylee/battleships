module battleship_top(
    input  wire        clk,
    input  wire        reset,
    input  wire        start_btn,
    input  wire        reset_btn,
    input  wire        btn_up, 
    input  wire        btn_down, 
    input  wire        btn_left, 
    input  wire        btn_right, 
    input  wire        btn_select,
    output wire [399:0] cell_state_flat,
    output wire        hit_detected,
    output wire [4:0]   ships_sunk,   // One bit per ship: {Carrier, Battleship, Cruiser, Sub, Destroyer}
    output wire [7:0]  hit_count
);

  // Internal Signals
  wire  [6:0]   selected_cell;
  wire          shot_select;
  wire  [99:0]  shot_signals;
  reg   [99:0]  is_ship;
  reg   [7:0]   turns_remaining;
  wire          turns_exhausted;
  wire  [4:0]   game_state;

  // New: map of all hits so far
  reg [7:0]     hit_count_reg;
  assign hit_count = hit_count_reg;
  reg   [99:0]  hit_map;
  wire  [99:0]  hit_signals = shot_signals & is_ship;
  
  localparam TOTAL_SEGMENTS = 17;

  wire all_segments_hit = (hit_count == TOTAL_SEGMENTS);
  wire game_over = all_segments_hit || turns_exhausted;


  // Per-ship slices of hit_map
  wire [4:0]  carrier_hits    = hit_map[4:0];        // size 5
  wire [3:0]  battleship_hits = hit_map[15:12];     // size 4
  wire [2:0]  cruiser_hits    = hit_map[22:20];     // size 3
  wire [2:0]  submarine_hits  = hit_map[33:31];     // size 3
  wire [1:0]  destroyer_hits  = hit_map[44:43];     // size 2

  // Sunk when *all* of their segments are hit
  wire carrier_sunk    = &carrier_hits;
  wire battleship_sunk = &battleship_hits;
  wire cruiser_sunk    = &cruiser_hits;
  wire submarine_sunk  = &submarine_hits;
  wire destroyer_sunk  = &destroyer_hits;

  assign ships_sunk = { carrier_sunk,
                        battleship_sunk,
                        cruiser_sunk,
                        submarine_sunk,
                        destroyer_sunk };

  // instantiate cursor, FSM, grid as before
  cursor_control cursor(
    .clk(clk), .reset(reset),
    .btn_up(btn_up), .btn_down(btn_down), .btn_left(btn_left),
    .btn_right(btn_right), .btn_select(btn_select),
    .selected_cell(selected_cell),
    .shot_select(shot_select)
  );

  battleship_fsm fsm(
    .clk(clk), .reset(reset),
    .start_btn(start_btn), .reset_btn(reset_btn),
    .shot_select(shot_select),
    .hit(|hit_signals),               // high if *any* segment was hit
    .all_ships_sunk(game_over),     // when all five are sunk
    .turns_exhausted(turns_exhausted),
    .current_state(game_state)
  );

  hit_detector hit_det (
    .shot(shot_select),
    .is_ship(is_ship),
    .selected_cell(selected_cell),
    .hit(hit_detected)       // this now drives the top-level port
  );


  // only fire a one-hot shot vector in the SHOOT state
  assign shot_signals = (shot_select && game_state == 5'b00100)
                        ? (100'b1 << selected_cell)
                        : 100'b0;

  grid_array grid_inst (
    .clk(clk), .reset(reset),
    .shot(shot_signals),
    .is_ship(is_ship),
    .cell_state_flat(cell_state_flat)
    // remove old ship_sunk port here
  );

  // Sequential logic: reset, setup, and hit-tracking
  localparam MAX_TURNS = 15;

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      turns_remaining <= MAX_TURNS;
      is_ship         <= 100'b0;
      hit_map         <= 100'b0;
    end else begin
      case (game_state)
        5'b00010: begin  // SETUP
          turns_remaining <= MAX_TURNS;
          hit_map         <= 100'b0;
          // hardcoded ship positions:
          is_ship[4:0]   <= 5'b11111;    // Carrier
          is_ship[15:12]<= 4'b1111;     // Battleship
          is_ship[22:20]<= 3'b111;      // Cruiser
          is_ship[33:31]<= 3'b111;      // Submarine
          is_ship[44:43]<= 2'b11;       // Destroyer
        end

        5'b01000: begin  // EVALUATE_SHOT
          if (shot_select) begin
            hit_map <= hit_map | hit_signals;
            if (turns_remaining > 0 && hit_signals == 0)
              turns_remaining <= turns_remaining - 1;
          end
        end

        default: begin
          turns_remaining <= turns_remaining;
          is_ship         <= is_ship;
          hit_map         <= hit_map;
        end
      endcase
    end
  end

  assign turns_exhausted = (turns_remaining == 0);

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      hit_count_reg <= 8'd0;
    end
    else if (shot_select && hit_detected) begin
      hit_count_reg <= hit_count_reg + 1;
    end
    // else: hold value
  end

endmodule
