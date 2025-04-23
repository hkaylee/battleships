`timescale 1ns / 1ps
module cursor_control (
    input  wire        clk,          // System clock
    input  wire        reset,        // Asynchronous reset
    input  wire        btn_up,       // Move cursor up
    input  wire        btn_down,     // Move cursor down
    input  wire        btn_left,     // Move cursor left
    input  wire        btn_right,    // Move cursor right
    input  wire        btn_select,   // Fire shot
    output wire [6:0]  selected_cell,// 0-99 flat index
    output reg         shot_select   // One-cycle pulse on select
);

    // Internal row/col registers
    reg [3:0] cursor_row;
    reg [3:0] cursor_col;
    reg       btn_select_prev;

    // Compute flat index = row*10 + col
    assign selected_cell = cursor_row * 4'd10 + cursor_col;

    // Cursor movement logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            cursor_row <= 4'd0;
            cursor_col <= 4'd0;
        end else begin
            // Vertical
            if      (btn_up    && cursor_row > 0)  cursor_row <= cursor_row - 1;
            else if (btn_down  && cursor_row < 9)  cursor_row <= cursor_row + 1;
            // Horizontal
            if      (btn_left  && cursor_col > 0)  cursor_col <= cursor_col - 1;
            else if (btn_right && cursor_col < 9)  cursor_col <= cursor_col + 1;
        end
    end

    // Generate one-cycle shot_select pulse on btn_select rising edge
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            btn_select_prev <= 1'b0;
            shot_select     <= 1'b0;
        end else begin
            shot_select     <= btn_select & ~btn_select_prev;
            btn_select_prev <= btn_select;
        end
    end

endmodule
