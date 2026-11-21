module PriorityRegisterBlock_SBRX #(
    parameter DATA_WIDTH 	= 64, 	// Width of input data
    parameter CHUNK_WIDTH 	= 32 	// Width of output data (must be a factor of DATA_WIDTH)
)(
    input wire 						lclk 				, 	// System Clock
    input wire 						sys_rst 			, 	// Reset Signal
    input wire [DATA_WIDTH:0] 		sync_fifo_data 		, 	// Data from Sync_fifo
    input wire [DATA_WIDTH:0] 		completion_pkt_data ,	// Data from Completion_packet_buffer
    input wire [DATA_WIDTH:0] 		request_pkt_data 	,   // Data from Request_packet_buffer
    input wire 						sync_fifo_empty 	, 	// Empty flag for Sync_fifo
    input wire 						completion_pkt_empty, 	// Empty flag for Completion_packet_buffer
    input wire 						request_pkt_empty 	,	// Empty flag for Request_packet_buffer
    input wire 						avail_credit 		, 	// Credit available
	input wire 						active_flag 		,
	input wire 						lp_clk_ack 			,
	output reg 						clk_hs_start 		,
    output reg 						sync_rd_en 			, 	// Read Enable for Sync_fifo
    output reg 						completion_rd_en 	, 	// Read Enable for Completion_packet_buffer
    output reg 						request_rd_en 		, 	// Read Enable for Request_packet_buffer
	output reg [CHUNK_WIDTH-1:0] 	reg_out 			, 	// 32-bit Register Output
	output reg 						data_valid 			,
	output reg 						credit_decr
);
	
	reg [CHUNK_WIDTH-1:0] data_reg;  // Stores the 64-bit read value
    reg select_half;
	reg valid;
	reg sync_data_valid, sync_valid;
	reg completion_data_valid, completion_valid;
	reg request_data_valid, request_valid;
	
	
	always @(posedge lclk or negedge sys_rst) begin
		if (~sys_rst) begin
			data_reg 	<= {CHUNK_WIDTH{1'b0}};
			reg_out 	<= {CHUNK_WIDTH{1'b0}};
			credit_decr <= 1'b0;
			data_valid 	<= 1'b0;
			valid 		<= 1'b0;
		end else begin 
			if (valid) begin
				data_reg 	<= {CHUNK_WIDTH{1'b0}};
				reg_out 	<= data_reg; 
				credit_decr <= 1'b0;
				data_valid  <= 1'b1;
				valid 		<= 1'b0;
			end else if(sync_data_valid) begin
				if (sync_fifo_data[64] == 1'b1) begin
					credit_decr <= 1'b1;
				end else begin
					credit_decr <= 1'b0;
				end 
				data_reg 	<= sync_fifo_data[63:32];
                reg_out 	<= sync_fifo_data[31:0];
				data_valid 	<= 1'b1;
				valid 		<= 1'b1;
			end else if (completion_data_valid) begin
			/*	if (completion_pkt_data[64] == 1'b1) begin
					credit_decr <= 1'b1;
				end else begin
					credit_decr <= 1'b0;
				end */
				credit_decr <= 1'b0;
				data_reg 	<= completion_pkt_data[63:32];
                reg_out 	<= completion_pkt_data[31:0];
				data_valid 	<= 1'b1;
				valid 		<= 1'b1;
			end else if (request_data_valid) begin
				if (request_pkt_data[64] == 1'b1) begin
					credit_decr <= 1'b1;
				end else begin
					credit_decr <= 1'b0;
				end 
				data_reg 	<= request_pkt_data[63:32];
                reg_out 	<= request_pkt_data[31:0];
				data_valid 	<= 1'b1;
				valid 		<= 1'b1;
			end else begin
				data_reg 	<= {CHUNK_WIDTH{1'b0}};
                reg_out 	<= {CHUNK_WIDTH{1'b0}};
				credit_decr <= 1'b0;
				data_valid 	<= 1'b0;
				valid 		<= 1'b0;
			end 
		end
	end
	
	always @(posedge lclk or negedge sys_rst) begin
		if (~sys_rst) begin
			sync_rd_en 				<= 1'b0;
			completion_rd_en 		<= 1'b0;
			request_rd_en 			<= 1'b0;
			select_half 			<= 1'b0;
			sync_data_valid 		<= 1'b0;
			sync_valid 				<= 1'b0;
			completion_data_valid 	<= 1'b0;
			completion_valid 		<= 1'b0;
			request_data_valid 		<= 1'b0;
			request_valid 			<= 1'b0;
			clk_hs_start 			<= 1'b0;
		end else begin
			if (~select_half) begin
				// Clear data valid signals
				sync_data_valid 		<= 1'b0;
				completion_data_valid 	<= 1'b0;
				request_data_valid 		<= 1'b0;
				// Check read conditions in order of priority
				if (avail_credit && ~sync_fifo_empty ) begin
					sync_rd_en 			<= 1'b1;
					completion_rd_en 	<= 1'b0;
					request_rd_en 		<= 1'b0;
					select_half 		<= 1'b1;
				end else if (~completion_pkt_empty ) begin
					sync_rd_en 			<= 1'b0;
					completion_rd_en 	<= 1'b1;
					request_rd_en 		<= 1'b0;
					select_half 		<= 1'b1;
				end else if (avail_credit && ~request_pkt_empty) begin
					sync_rd_en 			<= 1'b0;
					completion_rd_en 	<= 1'b0;
					request_rd_en 		<= 1'b1;
					select_half 		<= 1'b1;
				end else begin
					sync_rd_en 			<= 1'b0;
					completion_rd_en 	<= 1'b0;
					request_rd_en 		<= 1'b0;
					select_half 		<= 1'b0;
				end
			end else begin
				if (active_flag) begin
					sync_rd_en       	<= 1'b0;
					completion_rd_en 	<= 1'b0;
					request_rd_en    	<= 1'b0;
					clk_hs_start     	<= 1'b0;
					// Reset select_half
					select_half 		<= 1'b0;
					// Capture which source was valid in the last cycle
					sync_data_valid       <= sync_rd_en;
					completion_data_valid <= completion_rd_en;
					request_data_valid    <= request_rd_en;
				end else if (lp_clk_ack) begin
					// Reset select_half
					select_half 		<= 1'b0;
					if (~clk_hs_start) begin
						// Disable all read enables
						sync_rd_en       <= 1'b0;
						completion_rd_en <= 1'b0;
						request_rd_en    <= 1'b0;
					
						// Capture which source was valid in the last cycle
						sync_data_valid       <= sync_rd_en;
						completion_data_valid <= completion_rd_en;
						request_data_valid    <= request_rd_en;
					end else begin
						clk_hs_start <= 1'b0;
						sync_data_valid       <= sync_valid;
						completion_data_valid <= completion_valid;
						request_data_valid    <= request_valid;
						sync_valid 			  <= 1'b0;
						completion_valid 	  <= 1'b0;
						completion_valid 	  <= 1'b0;
					end 
				end else begin
					if (~clk_hs_start) begin
						// Disable all read enables
						sync_rd_en       <= 1'b0;
						completion_rd_en <= 1'b0;
						request_rd_en    <= 1'b0;
					
						// Capture which source was valid in the last cycle
						if (sync_rd_en) begin
							sync_valid <= 1'b1;
						end else if (completion_rd_en) begin
							completion_valid <= 1'b1;
						end else if (request_rd_en) begin
							request_valid <= 1'b1;
						end
					
						// Mark the start of high-speed clock
						clk_hs_start <= 1'b1;
					end
				end
			end
		end
	end

endmodule