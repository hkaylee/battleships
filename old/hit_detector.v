module hit_detector (
    input  wire       shot,         // Single-bit signal indicating shot fired
    input  wire [99:0] is_ship,     // 100-bit map of ship positions
    input  wire [6:0]  selected_cell, // Encoded 0–99 index of selected cell
    output reg        hit           // High for one cycle if hit
);

    always @(*) begin
        if (shot)
            hit = is_ship[selected_cell];
        else
            hit = 1'b0;
    end

endmodule
