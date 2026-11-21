module up_down_counter #(
    parameter WIDTH = 5  // Counter bit width
) (
    input                   lclk, 		// Clock signal
    input                   sys_rst, 	// Active-low reset
    input                   up, 		// Count up signal
    input                   down, 		// Count down signal
    output reg [WIDTH-1:0]  count 		// Counter output
);

    always @(posedge lclk or negedge sys_rst) begin
        if (~sys_rst)
            count <= {WIDTH{1'b1}};  // initializes count to maximum (all credits available)
        else begin
            if (up && ~down && (count != {WIDTH{1'b1}}))     // Count Up
                count <= count + 1;
            else if (down && ~up && (count != 0)) // Count Down
                count <= count - 1;
            // If both up and down are high, it does nothing
        end
    end

endmodule
