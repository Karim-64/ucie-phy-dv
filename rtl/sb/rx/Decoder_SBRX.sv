module Decoder_SBRX #(
	parameter DATA_WIDTH 		= 64,
	parameter DESTINATION_SEL 	= 2
)(
    input 								lclk				,
    input 								sys_rst				,
    input 								async_fifo_empty	,
	input 								completion_sel		,
    input 		[DATA_WIDTH-1:0] 		decoder_data_in		,
    output reg 	[DATA_WIDTH:0] 	        decoder_data_out	,
    output reg 							decoder_rd_en		,
    output reg 	[DESTINATION_SEL-1:0] 	dest_sel			,
    output reg 							module_en			,
    output reg 							module_partner_en	,
    output reg 							rdi_en				,
	output reg							decoder_error
);
	
    localparam [4:0]    
		MEMORY_READ32           = 5'b00000, MEMORY_WRITE32          = 5'b00001,
		DMS_REGISTER_READ32		= 5'b00010, DMS_REGISTER_WRITE32 	= 5'b00011,
        CONFIGURATION_READ32    = 5'b00100, CONFIGURATION_WRITE32   = 5'b00101,
        MEMORY_READ64           = 5'b01000, MEMORY_WRITE64          = 5'b01001,
		DMS_REGISTER_READ64		= 5'b01010, DMS_REGISTER_WRITE64 	= 5'b01011,
		CONFIGURATION_READ64    = 5'b01100, CONFIGURATION_WRITE64   = 5'b01101,
        COMPLETION_WO_DATA      = 5'b10000, COMPLETION_W_DATA32     = 5'b10001,
        MESSAGE_WO_DATA         = 5'b10010, MESSAGE_W_DATA64        = 5'b11011,
        COMPLETION_W_DATA64     = 5'b11001, MPM_WO_DATA 			= 5'b10111,
		MPM_W_DATA 				= 5'b11000;

    reg waiting_for_data;    // Flag to indicate waiting for data
    reg dp_reg;              // Register to store last bit of first packet
	reg module_en_next;
	reg module_partner_en_next;
	reg rdi_en_next; 		// Hold values for the second cycle
	reg data_valid;
	reg ignore_flag;
	reg header_flag;
	reg data_flag;
	reg [DESTINATION_SEL-1:0] dest_sel_next;
	reg [DATA_WIDTH-1:0] header_reg;
	
	always @(posedge lclk or negedge sys_rst) begin
		if (~sys_rst) begin
			decoder_rd_en <= 1'b0;
		end else begin
			if (~async_fifo_empty && ~decoder_rd_en) begin
				decoder_rd_en <= 1'b1;
			end else begin
				decoder_rd_en <= 1'b0;
			end
		end
	end
	
	always @(posedge lclk or negedge sys_rst) begin
		if (~sys_rst) begin
			data_valid <= 1'b0;
		end else begin
			if (decoder_rd_en) begin
				data_valid <= 1'b1;
			end else begin
				data_valid <= 1'b0;
			end
		end
	end
	
	always @(posedge lclk or negedge sys_rst) begin
		if (~sys_rst) begin
			waiting_for_data 		<= 1'b0;
			ignore_flag 			<= 1'b0;
			dp_reg 					<= 1'b0;
			module_en 				<= 1'b0;
			module_partner_en 		<= 1'b0;
			rdi_en 					<= 1'b0;
			module_en_next 			<= 1'b0;
			module_partner_en_next 	<= 1'b0;
			rdi_en_next 			<= 1'b0;
			decoder_error 			<= 1'b0;
			header_flag 			<= 1'b0;
			data_flag 				<= 1'b0;
			header_reg 				<= 1'b0;
			dest_sel  				<= 2'b00;
			dest_sel_next  			<= 2'b00;
			decoder_data_out 		<= 0;
		end else if (data_valid || data_flag) begin
			if (~waiting_for_data) begin
				case (decoder_data_in[4:0])
					MESSAGE_WO_DATA: begin
						waiting_for_data 	<= 1'b0;
                        dp_reg 				<= 1'b0;
						case (decoder_data_in[21:14])
							8'h00, 8'h03, 8'h04, 8'h05, 8'h06, 8'h07, 8'h08, 8'h09: begin
								module_en 					<= 1'b0;
								module_partner_en 			<= 1'b0;
								rdi_en 						<= 1'b0;
								module_en_next 				<= 1'b0;
								module_partner_en_next 		<= 1'b0;
								rdi_en_next 				<= 1'b0;
								if (decoder_data_in[62] != (^decoder_data_in[61:0])) begin
									dest_sel  				<= 2'b00;
									dest_sel_next  			<= 2'b00;
									decoder_error 			<= 1'b1;
									decoder_data_out 		<= 0;
								end else begin	
									dest_sel  				<= 2'b10;
									dest_sel_next 			<= 2'b10;
									decoder_error 			<= 1'b0;
									decoder_data_out 		<= {1'b1, decoder_data_in};
								end
							end
							8'h8A, 8'h9A, 8'hAA, 8'hBA, 8'hCA, 8'hEA, 8'hDA: begin
								if (decoder_data_in[21:14] == 8'h8A && decoder_data_in[39:32] == 8'h08) begin
									module_en 				<= 1'b0;
									module_partner_en 		<= 1'b1;
									module_en_next 			<= 1'b0;
									module_partner_en_next 	<= 1'b1;
								end else begin
									module_en 				<= 1'b1;
									module_partner_en 		<= 1'b0;
									module_en_next 			<= 1'b1;
									module_partner_en_next 	<= 1'b0;
								end
								dest_sel  					<= 2'b00;
								rdi_en 						<= 1'b0;
								dest_sel_next  				<= 2'b00;
								rdi_en_next 				<= 1'b0;
								if (decoder_data_in[62] != (^decoder_data_in[61:0])) begin
									module_en 				<= 1'b0;
									module_partner_en 		<= 1'b0;
									module_en_next 			<= 1'b0;
									module_partner_en_next 	<= 1'b0;
									decoder_error 			<= 1'b1;
									decoder_data_out 		<= 0;
								end else begin
									decoder_error 			<= 1'b0;
									decoder_data_out 		<= {1'b0, decoder_data_in};
								end
							end
							8'h85, 8'h95, 8'hA5, 8'hB5, 8'hC5, 8'hE5, 8'hD5: begin
								if (decoder_data_in[21:14] == 8'h85 && decoder_data_in[39:32] == 8'h08) begin
									module_en 				<= 1'b1;
									module_partner_en 		<= 1'b0;
									module_en_next 			<= 1'b1;
									module_partner_en_next 	<= 1'b0;
								end else begin
									module_en 				<= 1'b0;
									module_partner_en 		<= 1'b1;
									module_en_next 			<= 1'b0;
									module_partner_en_next 	<= 1'b1;
								end
								dest_sel  					<= 2'b00;
								rdi_en 						<= 1'b0;
								dest_sel_next  				<= 2'b00;
								rdi_en_next 				<= 1'b0;
								if (decoder_data_in[62] != (^decoder_data_in[61:0])) begin
									module_en 				<= 1'b0;
									module_partner_en 		<= 1'b0;
									module_en_next 			<= 1'b0;
									module_partner_en_next 	<= 1'b0;
									decoder_error 			<= 1'b1;
									decoder_data_out 		<= 0;
								end else begin
									decoder_error 			<= 1'b0;
									decoder_data_out 		<= {1'b0, decoder_data_in};
								end
							end
							8'h01, 8'h02: begin
								dest_sel  					<= 2'b00;
								dest_sel_next  				<= 2'b00;
								if (decoder_data_in[62] != (^decoder_data_in[61:0])) begin
									module_en 				<= 1'b0;
									module_partner_en 		<= 1'b0;
									rdi_en 					<= 1'b0;
									module_en_next 			<= 1'b0;
									module_partner_en_next 	<= 1'b0;
									rdi_en_next 			<= 1'b0;
									decoder_error 			<= 1'b1;
									decoder_data_out 		<= 0;
								end else begin
									module_en 				<= 1'b0;
									module_partner_en 		<= 1'b0;
									rdi_en 					<= 1'b1;
									module_en_next 			<= 1'b0;
									module_partner_en_next 	<= 1'b0;
									rdi_en_next 			<= 1'b1;
									decoder_error 			<= 1'b0;
									decoder_data_out 		<= {1'b0, decoder_data_in};
								end
							end
							8'hFF ,8'h91: begin
								dest_sel  					<= 2'b00;
								module_en 					<= 1'b0;
								module_partner_en 			<= 1'b0;
								rdi_en 						<= 1'b0;
								dest_sel_next  				<= 2'b00;
								module_en_next 				<= 1'b0;
								module_partner_en_next 		<= 1'b0;
								rdi_en_next 				<= 1'b0;
								decoder_error 				<= (decoder_data_in[62] != (^decoder_data_in[61:0]));
								decoder_data_out 			<= 0;
							end
							default: begin
								dest_sel  					<= 2'b00;
								module_en 					<= 1'b0;
								module_partner_en 			<= 1'b0;
								rdi_en 						<= 1'b0;
								dest_sel_next  				<= 2'b00;
								module_en_next 				<= 1'b0;
								module_partner_en_next 		<= 1'b0;
								rdi_en_next 				<= 1'b0;
								decoder_error 				<= 1'b1;
								decoder_data_out 			<= 0;
							end
						endcase
					end
					
					MESSAGE_W_DATA64: begin
						waiting_for_data 	<= 1'b1; // Wait for data
                        dp_reg 				<= decoder_data_in[63];
						case (decoder_data_in[21:14])
							8'h01, 8'h02: begin
								module_en 					<= 1'b0;
								module_partner_en 			<= 1'b0;
								rdi_en 						<= 1'b0;
								module_en_next 				<= 1'b0;
								module_partner_en_next 		<= 1'b0;
								rdi_en_next 				<= 1'b0;
								if (decoder_data_in[62] != (^decoder_data_in[61:0])) begin
									dest_sel  				<= 2'b00;
									dest_sel_next  			<= 2'b00;
									decoder_error 			<= 1'b1;
									decoder_data_out 		<= 0;
								end else begin
									dest_sel  				<= 2'b00;
									dest_sel_next  			<= 2'b10;
									decoder_error 			<= 1'b0;
									decoder_data_out 		<= 0;
									header_reg 				<= decoder_data_in;
									header_flag 			<= 1'b1;
								end
							end
							8'h81, 8'h8A, 8'hAA: begin
								dest_sel  					<= 2'b00;
								dest_sel_next  				<= 2'b00;
								if (decoder_data_in[62] != (^decoder_data_in[61:0])) begin
									module_en 				<= 1'b0;
									module_partner_en 		<= 1'b0;
									rdi_en 					<= 1'b0;
									module_en_next 			<= 1'b0;
									module_partner_en_next 	<= 1'b0;
									rdi_en_next 			<= 1'b0;
									decoder_error 			<= 1'b1;
									decoder_data_out 		<= 0;
								end else begin
									module_en 				<= 1'b1;
									module_partner_en 		<= 1'b0;
									rdi_en 					<= 1'b0;
									module_en_next 			<= 1'b1;
									module_partner_en_next 	<= 1'b0;
									rdi_en_next 			<= 1'b0;
									decoder_error 			<= 1'b0;
									decoder_data_out 		<= {1'b0, decoder_data_in};
								end
							end
							8'h85, 8'hA5, 8'hB5: begin
								dest_sel  					<= 2'b00;
								dest_sel_next  				<= 2'b00;
								if (decoder_data_in[62] != (^decoder_data_in[61:0])) begin
									module_en 				<= 1'b0;
									module_partner_en 		<= 1'b0;
									rdi_en 					<= 1'b0;
									module_en_next 			<= 1'b0;
									module_partner_en_next 	<= 1'b0;
									rdi_en_next 			<= 1'b0;
									decoder_error 			<= 1'b1;
									decoder_data_out 		<= 0;
								end else begin
									module_en 				<= 1'b0;
									module_partner_en 		<= 1'b1;
									rdi_en 					<= 1'b0;
									module_en_next 			<= 1'b0;
									module_partner_en_next 	<= 1'b1;
									rdi_en_next 			<= 1'b0;
									decoder_error 			<= 1'b0;
									decoder_data_out 		<= {1'b0, decoder_data_in};
								end
							end
							8'hFF: begin
								dest_sel  					<= 2'b00;
								module_en 					<= 1'b0;
								module_partner_en 			<= 1'b0;
								rdi_en 						<= 1'b0;
								dest_sel_next  				<= 2'b00;
								module_en_next 				<= 1'b0;
								module_partner_en_next 		<= 1'b0;
								rdi_en_next 				<= 1'b0;
								decoder_error 				<= (decoder_data_in[62] != (^decoder_data_in[61:0]));
								decoder_data_out 			<= 0;
							end
							default: begin
								dest_sel  					<= 2'b00;
								module_en 					<= 1'b0;
								module_partner_en 			<= 1'b0;
								rdi_en 						<= 1'b0;
								dest_sel_next  				<= 2'b00;
								module_en_next 				<= 1'b0;
								module_partner_en_next 		<= 1'b0;
								rdi_en_next 				<= 1'b0;
								decoder_error 				<= 1'b1;
								decoder_data_out 			<= 0;
							end
						endcase
					end
                    
					MEMORY_READ32, MEMORY_READ64,
					CONFIGURATION_READ32, CONFIGURATION_READ64: begin
						waiting_for_data 		<= 1'b0;
						dp_reg 					<= 1'b0;
						module_en 				<= 1'b0;
						module_partner_en 		<= 1'b0;
						rdi_en 					<= 1'b0;
                        module_en_next 			<= 1'b0;
                        module_partner_en_next 	<= 1'b0;
                        rdi_en_next 			<= 1'b0;
						if (decoder_data_in[62] != (^decoder_data_in[61:0])) begin
							dest_sel  			<= 2'b00;
							dest_sel_next  		<= 2'b00;
							decoder_error 		<= 1'b1;
							decoder_data_out 	<= 0;
						end else begin
							dest_sel  			<= 2'b01;
							dest_sel_next  		<= 2'b01;
							decoder_error 		<= 1'b0;
							decoder_data_out 	<= {1'b1, decoder_data_in};
						end
					end
					
					MEMORY_WRITE32, MEMORY_WRITE64,
					CONFIGURATION_WRITE32, CONFIGURATION_WRITE64: begin
						waiting_for_data 		<= 1'b1;
                        dp_reg 					<= decoder_data_in[63];
						module_en 				<= 1'b0;
						module_partner_en 		<= 1'b0;
						rdi_en 					<= 1'b0;
                        module_en_next 			<= 1'b0;
                        module_partner_en_next 	<= 1'b0;
                        rdi_en_next 			<= 1'b0;
						if (decoder_data_in[62] != (^decoder_data_in[61:0])) begin
							dest_sel  			<= 2'b00;
							dest_sel_next  		<= 2'b00;
							decoder_error 		<= 1'b1;
							decoder_data_out 	<= 0;
						end else begin
							dest_sel  			<= 2'b00;
							dest_sel_next  		<= 2'b01;
							decoder_error 		<= 1'b0;
							decoder_data_out 	<= 0;
							header_reg 			<= decoder_data_in;
							header_flag 		<= 1'b1;
						end
					end
					
					COMPLETION_W_DATA32, COMPLETION_W_DATA64: begin
						waiting_for_data 		<= 1'b1;
                        dp_reg 					<= decoder_data_in[63];
						module_en 				<= 1'b0;
						module_partner_en 		<= 1'b0;
						rdi_en 					<= 1'b0;
                        module_en_next 			<= 1'b0;
                        module_partner_en_next 	<= 1'b0;
                        rdi_en_next 			<= 1'b0;
						if (decoder_data_in[62] != (^decoder_data_in[61:0])) begin
							dest_sel  			<= 2'b00;
							dest_sel_next  		<= 2'b00;
							decoder_error 		<= 1'b1;
							decoder_data_out 	<= 0;
						end else begin
							dest_sel  			<= 2'b00;
							dest_sel_next  		<= 2'b11;
							decoder_error 		<= 1'b0;
							decoder_data_out 	<= 0;
							header_reg 			<= decoder_data_in;
							header_flag 		<= 1'b1;
						end
					end
					
					COMPLETION_WO_DATA: begin
						waiting_for_data 		<= 1'b0;
                        dp_reg 					<= 1'b0;
						module_en 				<= 1'b0;
						module_partner_en 		<= 1'b0;
						rdi_en 					<= 1'b0;
                        module_en_next 			<= 1'b0;
                        module_partner_en_next 	<= 1'b0;
                        rdi_en_next 			<= 1'b0;
						if (decoder_data_in[62] != (^decoder_data_in[61:0])) begin
							dest_sel  			<= 2'b00;
							dest_sel_next  		<= 2'b00;
							decoder_error 		<= 1'b1;
							decoder_data_out 	<= 0;
						end else begin
							dest_sel  			<= 2'b11;
							dest_sel_next  		<= 2'b11;
							decoder_error 		<= 1'b0;
							decoder_data_out 	<= {1'b0, decoder_data_in};
						end
					end
					
					DMS_REGISTER_READ32, DMS_REGISTER_READ64,
					MPM_WO_DATA: begin
						waiting_for_data 		<= 1'b0;
                        decoder_error 			<= (decoder_data_in[62] != (^decoder_data_in[61:0]));
                        dp_reg 					<= 1'b0;
						dest_sel  				<= 2'b00;
						module_en 				<= 1'b0;
						module_partner_en 		<= 1'b0;
						rdi_en 					<= 1'b0;
						dest_sel_next  			<= 2'b00;
                        module_en_next 			<= 1'b0;
                        module_partner_en_next 	<= 1'b0;
                        rdi_en_next 			<= 1'b0;
						decoder_data_out 		<= 0;
					end
					
					DMS_REGISTER_WRITE32, DMS_REGISTER_WRITE64,
					MPM_W_DATA: begin
						ignore_flag 			<= 1'b1;
						waiting_for_data 		<= 1'b1; // Wait for data
                        decoder_error 			<= (decoder_data_in[62] != (^decoder_data_in[61:0]));
                        dp_reg 					<= decoder_data_in[63];
						dest_sel  				<= 2'b00;
						module_en 				<= 1'b0;
						module_partner_en 		<= 1'b0;
						rdi_en 					<= 1'b0;
						dest_sel_next  			<= 2'b00;
                        module_en_next 			<= 1'b0;
                        module_partner_en_next 	<= 1'b0;
                        rdi_en_next 			<= 1'b0;
						decoder_data_out 		<= 0;
					end
					
					default: begin
						waiting_for_data 		<= 1'b0;
                        dp_reg 					<= 1'b0;
						dest_sel  				<= 2'b00;
						module_en 				<= 1'b0;
						module_partner_en 		<= 1'b0;
						rdi_en 					<= 1'b0;
						dest_sel_next  			<= 2'b00;
                        module_en_next 			<= 1'b0;
                        module_partner_en_next 	<= 1'b0;
                        rdi_en_next 			<= 1'b0;
						decoder_error 			<= 1'b1;
						decoder_data_out 		<= 0;
					end
				endcase
			end else begin
				if (decoder_error || dp_reg != (^decoder_data_in[63:0])) begin
					dest_sel 					<= 2'b00;
					module_en 					<= 1'b0;
					module_partner_en 			<= 1'b0;
					rdi_en 						<= 1'b0;
					decoder_error 				<= 1'b1;
					decoder_data_out 			<= 0;
					dp_reg 						<= 1'b0;
					header_flag 				<= 1'b0;
					data_flag 					<= 1'b0;
					header_reg 					<= 1'b0;			
					waiting_for_data 			<= 1'b0;
				end else if (header_flag) begin
					dest_sel 					<= dest_sel_next;
					module_en 					<= module_en_next;
					module_partner_en 			<= module_partner_en_next;
					rdi_en 						<= rdi_en_next;
					decoder_error 				<= 1'b0;
					decoder_data_out 			<= {1'b0, header_reg};
					header_flag					<= 1'b0;
					data_flag 					<= 1'b1;
					header_reg 					<= decoder_data_in;
					waiting_for_data 			<= 1'b1;
				end else if (data_flag) begin
					dest_sel 					<= dest_sel_next;
					module_en 					<= module_en_next;
					module_partner_en 			<= module_partner_en_next;
					rdi_en 						<= rdi_en_next;
					decoder_error 				<= 1'b0;
					decoder_data_out 			<= {1'b1, header_reg};
					dp_reg 						<= 1'b0;
					header_flag					<= 1'b0;
					data_flag 					<= 1'b0;
					header_reg 					<= 1'b0;
					waiting_for_data 			<= 1'b0;
				end else begin
					dest_sel 					<= dest_sel_next;
					module_en 					<= module_en_next;
					module_partner_en 			<= module_partner_en_next;
					rdi_en 						<= rdi_en_next;
					decoder_error 				<= 1'b0;
					dp_reg 						<= 1'b0;
					header_flag					<= 1'b0;
					data_flag 					<= 1'b0;
					header_reg 					<= 1'b0;
					waiting_for_data 			<= 1'b0;
					if (ignore_flag) begin
						decoder_data_out 		<= 0;
						ignore_flag 			<= 1'b0;
					end else begin
						decoder_data_out 		<= {1'b0, decoder_data_in};
					end
				end 
			end 
		end else begin
			if (completion_sel && dest_sel == 2'b11) begin
				module_en 				<= 1'b0;
				module_partner_en 		<= 1'b0;
				rdi_en 					<= 1'b0;
				decoder_error 			<= 1'b0;
			end 
			else begin
				dest_sel 				<= 2'b00;
				decoder_data_out 		<= 0;
				module_en 				<= 1'b0;
				module_partner_en 		<= 1'b0;
				rdi_en 					<= 1'b0;
				decoder_error 			<= 1'b0;
			end
		end
	end 

endmodule
