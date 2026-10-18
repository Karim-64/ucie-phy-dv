module Pattern_detector_SBRX #(
    parameter DATA_WIDTH = 64
)(
    input 							sb_clk			, 	// Clock input
    input 							sb_sys_rst		, 	// Active-low reset
    input		[DATA_WIDTH-1:0] 	pattern_data_in	, 	// Input data
    input 							data_valid		, 	// Enable signal
    output reg 						pattern_detected, 	// Output flag
	output reg 						sb_o_detected
);

    localparam [DATA_WIDTH-1:0] PATTERN = 64'h5555555555555555;
    
    reg pattern_count;

    always @(posedge sb_clk or negedge sb_sys_rst) begin
        if (~sb_sys_rst) begin
            pattern_count    <= 1'b0;
            pattern_detected <= 1'b0;
        end else if (data_valid) begin
            if (pattern_data_in == PATTERN) begin
                if (pattern_count == 1'b1) begin
                    pattern_detected <= 1'b1; // Assert on 2nd detection
                    pattern_count    <= 1'b0; // Reset counter
                end else begin
                    pattern_count 	 <= pattern_count + 1;
                    pattern_detected <= 1'b0; // Ensure detection is only asserted once
                end
            end
        end else begin
            pattern_detected <= 1'b0;
        end
    end
	
	always @(posedge sb_clk or negedge sb_sys_rst) begin
		if (~sb_sys_rst) begin
			sb_o_detected <= 1'b0;
		end else if (data_valid) begin
			if (pattern_data_in[4:0] == 5'b10010 && pattern_data_in[21:14] == 8'h91 && pattern_data_in[40] && pattern_data_in[58:56] == 3'b110) begin
				if (pattern_data_in[62] != (^pattern_data_in[61:0])) begin
					sb_o_detected <= 1'b0;
				end else begin
					sb_o_detected <= 1'b1;
				end
			end else begin
				sb_o_detected <= 1'b0;
			end
		end else begin
			sb_o_detected <= 1'b0;
		end
	end

endmodule
