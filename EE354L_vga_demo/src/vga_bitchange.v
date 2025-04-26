`timescale 1ns / 1ps
module vga_bitchange(
    input  wire        clk,
    input  wire        bright,
    input  wire [9:0]  hCount, vCount,
    input  wire        button,
    output reg  [11:0] rgb,
    output reg  [15:0] score
);
    // Colors
    localparam [11:0] BLACK = 12'b0000_0000_0000;
    localparam [11:0] WHITE = 12'b1111_1111_1111;
    localparam [11:0] BLUE  = 12'b0000_0000_1111;

    // Grid parameters
    localparam integer GRID_SIZE = 10;
    
    // Calculate cell sizes based on visible area
    // Visible area is from hCount=144 to 783 (640 pixels) and vCount=35 to 515 (480 pixels)
    localparam integer CELL_WIDTH  = 64;  // 640/10 = 64
    localparam integer CELL_HEIGHT = 48;  // 480/10 = 48
    
    // Grid starts at the beginning of the visible area
    localparam integer GRID_LEFT = 144;
    localparam integer GRID_TOP  = 35;
    
    // Line thickness
    localparam integer LINE_THICKNESS = 1;

    // Grid lines
    wire isVerticalLine = bright && 
                          (hCount >= GRID_LEFT) && 
                          (hCount < GRID_LEFT + (CELL_WIDTH * GRID_SIZE)) &&
                          (((hCount - GRID_LEFT) % CELL_WIDTH) < LINE_THICKNESS);
                          
    wire isHorizontalLine = bright && 
                            (vCount >= GRID_TOP) && 
                            (vCount < GRID_TOP + (CELL_HEIGHT * GRID_SIZE)) &&
                            (((vCount - GRID_TOP) % CELL_HEIGHT) < LINE_THICKNESS);
                            
    // Grid area (used for blue background)
    wire inGridArea = bright && 
                      (hCount >= GRID_LEFT) && 
                      (hCount < GRID_LEFT + (CELL_WIDTH * GRID_SIZE)) &&
                      (vCount >= GRID_TOP) && 
                      (vCount < GRID_TOP + (CELL_HEIGHT * GRID_SIZE));

    // Pixel color assignment
    always @(*) begin
        if (!bright)
            rgb = BLACK;
        else if (isVerticalLine || isHorizontalLine)
            rgb = WHITE;
        else if (inGridArea)
            rgb = BLUE;
        else
            rgb = BLACK;
    end

    // Static score output
    always @(posedge clk) begin
        score <= 0;
    end
endmodule