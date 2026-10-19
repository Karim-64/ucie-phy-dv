module PHY_module #(
    parameter DATA_WIDTH = 64,
    parameter ADDR_WIDTH = 24
)(
    input 						lclk,
	input 						sys_rst,
	
	// SB_Rx_Decoder & SB_Rx_Decoder & MP_Module
	input 						error,
	
	// SB_Rx_Decoder
	input 						module_en,
	input 	   [DATA_WIDTH-1:0] data_in,
	
	// SB_Rx_Pattern_Detector
	input 						pattern_detected,
	input 						sb_o_detected,
	output reg 					path_sel,
	
	// SB_Tx_Serializer
	input 						ser_done,
	
	// SB_Tx_Decoder
	output reg [1:0] 			decoder_mode,
	output reg 					progress_stop,
	
	// SB_Tx_Parity_Checker
	output reg 					encoder_en_m,
	output reg 					sb_pattern,
	output reg [DATA_WIDTH-1:0] data_out_m,
	
	// LTSM 
	input 	   [2:0] 			cs,
	input 	   [2:0] 			mbinit_cs,
	input 	   [3:0] 			mbtrain_cs,
	output reg [2:0] 			retrain_encoding_ltsm,
	output reg 					trainerror_hs_m,
	output reg 					speed_idle_req_m,
	output reg 					repair_req_m,
	output reg 					sb_p_done,
	
	// Memory_Controller
	output reg 					mem_wr_en,
	output reg [ADDR_WIDTH-1:0] mem_addr,
	output reg [DATA_WIDTH-1:0] mem_data,
	
    // MB
	input 						end_mb,
	output reg 					start_mb_m,
	output reg 					start_rx,
	output reg 					lane_reverse,
	output reg 	[2:0] 			width_degrade,
	
	// RDI interface
	output reg 	[2:0] 			pl_speedmode,
	output reg 	[2:0] 			pl_lnk_cfg,
	
	// MP_Module 
	output reg 	[2:0] 			max_speed,
	output reg 	[2:0] 			retrain_encoding,
	output reg 					sb_exit_m,
	
	// RDI_Module
	output reg  				module_error
);

	/* LTSM states */
	localparam  RESET 		= 3'b000,   SBINIT 		= 3'b001,
				MBINIT 		= 3'b010,   MBTRAIN 	= 3'b011,
				LINKINIT 	= 3'b100,   ACTIVE 		= 3'b101,
				PHYRETRAIN 	= 3'b110,	TRAINERROR 	= 3'b111;
	
	/* MBINIT states */
    localparam  PARAM 		= 3'b000, 	CAL 		= 3'b001,
				REPAIRCLK 	= 3'b010,   REPAIRVAL 	= 3'b011,
				REVERSALMB 	= 3'b100,   REPAIRMB 	= 3'b101;
	
	/* MBTRAIN states */
    localparam  VALVREF 			= 4'b0000, 	DATAVREF 			= 4'b0001,
                SPEEDIDLE 			= 4'b0010, 	TXSELFCAL 			= 4'b0011,
                RXCLKCAL 			= 4'b0100, 	VALTRAINCENTER 		= 4'b0101,
                VALTRAINVREF 		= 4'b0110, 	DATATRAINCENTER1 	= 4'b0111,
                DATATRAINVREF 		= 4'b1000, 	RXDESKEW 			= 4'b1001,
                DATATRAINCENTER2 	= 4'b1010, 	LINKSPEED 			= 4'b1011,
                REPAIR 				= 4'b1100;
	
	/*Max IO Speed: 
		0h: 4 GT/s
		1h: 8 GT/s
		2h: 12 GT/s
		3h: 16 GT/s
		4h: 24 GT/s
		5h: 32 GT/s
	*/
	reg speed_degrade_flag;
	reg repair_flag;
	
	/* error if we don't in the deticated cycle*/
	reg internal_error;
	/* Flag if Msgsubcode or MsgInfo isn't true detected */
	reg packet_error;
	/* lanes are correctly detected for REPAIRCLK*/
	reg correct_detection;
	reg correct_detection_cummulative;
	
	reg lane_reverse_error_count;
	assign lane_error = (countones(data_in) < 8);
	
	/* Registers for previous states to detect changes */
	reg [2:0] prev_cs, prev_mbinit_cs;
	reg [3:0] prev_mbtrain_cs;
	bit flag;
	
	assign module_error = internal_error || packet_error;
	
	always @(*) begin
		case (width_degrade)
			3'b000: begin
				pl_lnk_cfg = 3'b000;
			end 
			3'b001: begin
				pl_lnk_cfg = 3'b001;
			end
			3'b010: begin
				pl_lnk_cfg = 3'b001;
			end 
			3'b011: begin
				pl_lnk_cfg = 3'b010;
			end 
			3'b100: begin
				pl_lnk_cfg = 3'b000;
			end
			3'b101: begin
				pl_lnk_cfg = 3'b000;
			end
			default: begin
				pl_lnk_cfg = 3'b010;
			end 
		endcase
	end 
	/* FSM States for cycle handling */
	typedef enum logic [4:0] {
		CYCLE1_TX, CYCLE2_TX, CYCLE3_TX, CYCLE4_TX, CYCLE5_TX,
		CYCLE6_TX, CYCLE7_TX, CYCLE8_TX, CYCLE9_TX,
		CYCLE1TE_WAIT, CYCLE1_WAIT, CYCLE2_WAIT, CYCLE3_WAIT, CYCLE4_WAIT, CYCLE5_WAIT,
		CYCLE6_WAIT, CYCLE7_WAIT, CYCLE8_WAIT, CYCLE9_WAIT
	} cycle_state_t;
	
	cycle_state_t cycle_state;
	
	/* State Change Monitoring */
	always @(posedge lclk or negedge sys_rst) begin
		if (~sys_rst) begin
			prev_cs 		<= 3'b000;
			prev_mbinit_cs 	<= 3'b000;
			prev_mbtrain_cs <= 4'b0000;
		end else begin
			// Update previous states for the next cycle
			prev_cs 		<= cs;
			prev_mbinit_cs 	<= mbinit_cs;
			prev_mbtrain_cs <= mbtrain_cs;
		end
	end	
			
	/* Module FSM */
	/* Main LTSM states */

	assign flag = (cs != prev_cs) || (mbinit_cs != prev_mbinit_cs) || (mbtrain_cs != prev_mbtrain_cs)? 1 : 0;
	always @(posedge lclk or negedge sys_rst) begin
		if (~sys_rst) begin
			path_sel 						<= 1'b1;
			sb_pattern 						<= 1'b0;
			sb_exit_m 						<= 1'b0;
			packet_error 					<= 1'b0;
			internal_error 					<= 1'b0;
			progress_stop 					<= 1'b0;
			sb_p_done 						<= 1'b0;
			encoder_en_m 					<= 1'b0;
			retrain_encoding_ltsm 			<= 3'b001;
			max_speed 						<= 4'h5;
			pl_speedmode             		<= 4'h5;
				
			mem_addr 						<= 24'h000000;
			mem_data 						<= 64'h00000000_00000000;
			mem_wr_en 						<= 1'b0;
				
			start_mb_m 						<= 1'b0;
			start_rx 						<= 1'b0;
			correct_detection 				<= 1'b0;
			correct_detection_cummulative 	<= 1'b0;
			trainerror_hs_m 				<= 1'b0;
	
				
			lane_reverse_error_count 		<= 1'b0;
			lane_reverse 					<= 1'b0;
			
			repair_flag 					<= 1'b0;
			repair_req_m 						<= 1'b0;
			speed_degrade_flag 				<= 1'b0;
			speed_idle_req_m 					<= 1'b0;
			
			width_degrade 					<= 3'b011;
			data_out_m 						<= 64'h00000000_00000000;
			cycle_state 					<= CYCLE1_TX;
		end else if ((error || packet_error || internal_error)&& !(cycle_state==CYCLE1TE_WAIT)) begin
			cycle_state 	<= CYCLE1TE_WAIT;
			data_out_m 		<= 64'h06000000_40394012;
			encoder_en_m 		<= 1'b1;
			packet_error	<=1'b0;
			internal_error	<=1'b0;
		end else if (cycle_state == CYCLE1TE_WAIT) begin
			data_out_m 		<= 64'h0;
			encoder_en_m 		<= 1'b0;
			if (module_en) begin
				if (data_in[61:0] == 62'h06000000_403A8012) begin
					trainerror_hs_m 	<= 1'b1;
					cycle_state 	<= CYCLE1_TX;
				end
			end
		end else begin
			case (cs) 
				/* In RESET state, Module Partner may be enter SBINIT before our module and send Pattern , So 
					1. we open the path to the pattern detector
					2. if pattern_detected then we send sb_exit_m to LTSM 
				*/
				RESET: begin
					sb_p_done 				<= 1'b0;
					progress_stop 			<= 1'b0;
					path_sel 				<= 1'b1;
					sb_pattern 				<= 1'b0;
					sb_exit_m 				<= (pattern_detected) ? 1'b1 : 1'b0;
					packet_error 			<= 1'b0;
					encoder_en_m 				<= 1'b0;
					retrain_encoding_ltsm 	<= 3'b001;
					data_out_m 				<= 64'h00000000_00000000;
				    progress_stop 			<= 1'b0;
				    lane_reverse            <= 1'b0;

				end
				
				/* In SBINIT state, We enable pattern_detector block to detect both the pattern and SBINIT Out of Reset,
					once SBINIT Out of Reset detected, we have two cycles:
					1st cycle: send header message of SBINIT done req 
					2nd cycle: wait for the header of SBINIT done resp and send sb_exit_m to LTSM if detected or flag an error if not detected
				*/
				/* We add sb_pattern_count to make sb_pattern to be pulse first time and then not to be asserted till ser_done be asserted in */
				SBINIT: begin
					case (cycle_state)
						CYCLE1_TX: begin
							packet_error 	<= 1'b0;
							if (sb_o_detected) begin
								path_sel 	<= 1'b0;
								sb_pattern 	<= 1'b0;
								encoder_en_m 	<= 1'b1;
								data_out_m 	<= 64'h06000001_40254012;
								cycle_state <= CYCLE1_WAIT;
							end else begin
								if (flag) begin 
								path_sel 	<= 1'b1;
								sb_pattern 	<= 1'b1;
								encoder_en_m 	<= 1'b0;
								data_out_m 	<= 64'h00000000_00000000;
							end 
							end
						end
						CYCLE1_WAIT: begin
							path_sel 			<= 1'b0;
							sb_pattern 			<= 1'b0;
							encoder_en_m 			<= 1'b0;
							data_out_m 			<= 64'h00000000_00000000;
							if(module_en) begin
								if (data_in[61:0] == 62'h06000001_40268012) begin
									sb_exit_m 		<= 1'b1;
									packet_error 	<= 1'b0;
									cycle_state 	<= CYCLE1_TX;
								end else begin
									sb_exit_m 		<= 1'b0;
									packet_error 	<= 1'b1;
								end
							end
						end
						default: begin 
							path_sel 			<= 1'b0;
							sb_pattern 			<= 1'b0;
							packet_error 		<= 1'b0;
							sb_exit_m 			<= 1'b0;
							encoder_en_m 			<= 1'b0;
							data_out_m 			<= 64'h00000000_00000000;
						end
					endcase
				end
				
				MBINIT: begin
					path_sel <= 1'b0;
					case (mbinit_cs) 
					/* In PARAM state:
						1st cycle: send header message of MBINIT.PARAM configuration req 
						2nd cycle: send data of MBINIT.PARAM configuration req
						3rd cycle: wait for the header of MBINIT.PARAM configuration resp and flag an error if not detected
						4th cycle: get the data of MBINIT.PARAM configuration resp and send sb_exit_m to LTSM and send data to MEMORY 
					*/
					PARAM: begin
						case (cycle_state)
							CYCLE1_TX: begin
								if (flag) begin
									sb_exit_m 		<= 1'b0;
									packet_error 	<= 1'b0;
									encoder_en_m 		<= 1'b1;
									data_out_m 		<= 64'h06000000_4029401B;
									cycle_state 	<= CYCLE2_TX;
								end
							end
							CYCLE2_TX: begin
								sb_exit_m 		<= 1'b0;
								packet_error 	<= 1'b0;
								encoder_en_m 		<= 1'b1;
								data_out_m 		<= 64'h00000000_00000215;   ///// GET DATA FROM MEMORY ///////
								cycle_state 	<= CYCLE1_WAIT;
							end
							CYCLE1_WAIT: begin
								sb_exit_m 		<= 1'b0;
								encoder_en_m 		<= 1'b0;
								data_out_m 		<= 64'h00000000_00000000;
								if (module_en) begin
									if (data_in[61:0] == 62'h06000000_402A801B) begin
										packet_error 	<= 1'b0;
										cycle_state 	<= CYCLE2_WAIT;
									end else begin
										packet_error 	<= 1'b1;
									end
								end
							end
							CYCLE2_WAIT: begin
								encoder_en_m 		<= 1'b0;
								data_out_m 		<= 64'h00000000_00000000;
								mem_wr_en 		<= 1'b0;
								mem_addr 		<= 24'h000000;
								mem_data 		<= 64'h00000000_00000000;
								if (module_en) begin								
									///////// WRITE DATA TO THE MEMORY //////
									if (data_in[10:9] != 2'b01) begin
										packet_error 	<= 1'b1;
										sb_exit_m 		<= 1'b0;
									end else if (data_in[3:0] != 4'h5) begin
										packet_error 	<= 1'b0;
										max_speed 		<= data_in[3:0];
										mem_wr_en 		<= 1'b1;
										mem_addr 		<= 24'h00000C;
										mem_data 		<= {56'h000000, data_in[3:0], 4'h0};
										sb_exit_m 		<= 1'b1;
										cycle_state 	<= CYCLE1_TX;
									end else if (data_in[10:9] == 2'b01 && data_in[3:0] == 4'h5) begin 
										sb_exit_m 		<= 1'b1;
										cycle_state 	<= CYCLE1_TX;
									end 
								end 
							end
							default: begin
								sb_exit_m 		<= 1'b0;
								packet_error 	<= 1'b0;
								encoder_en_m 		<= 1'b0;
								data_out_m 		<= 64'h00000000_00000000;
							end
						endcase
					end 
					
					/* In CAL state:
						1st cycle: send header message of MBINIT.CAL Done req
						2nd cycle: wait for the header of MBINIT.CAL Done resp and send sb_exit_m to LTSM if detected or flag an error if not detected 
					*/
					CAL: begin
						case (cycle_state)
							CYCLE1_TX: begin
								if (flag) begin
									sb_exit_m 		<= 1'b0;
									packet_error 	<= 1'b0;
									encoder_en_m 		<= 1'b1;
									data_out_m 		<= 64'h06000002_40294012;
									cycle_state 	<= CYCLE1_WAIT;
								end
							end
							CYCLE1_WAIT: begin
								encoder_en_m 		<= 1'b0;
								data_out_m 		<= 64'h00000000_00000000;
								if (module_en) begin
									if (data_in[61:0] == 62'h06000002_402A8012) begin
										sb_exit_m 		<= 1'b1;
										packet_error 	<= 1'b0;
										cycle_state     <= CYCLE1_TX;
									end else begin
										sb_exit_m 		<= 1'b0;
										packet_error 	<= 1'b1;
									end
								end
							end
							default: begin
								sb_exit_m 		<= 1'b0;
								packet_error 	<= 1'b0;
								encoder_en_m 		<= 1'b0;
								data_out_m 		<= 64'h00000000_00000000;
							end
						endcase
					end
					
					/* In REPAIRCLK state:
						1st cycle: send header message of MBINIT.REPAIRCLK init req
						2nd cycle: wait for the header of MBINIT.REPAIRCLK init resp and send start_mb_m to MB ig detected and flag an error if not detected
						3rd cycle: wait for end_mb and then send header message of MBINIT.REPAIRCLK result req
						4th cycle: wait for the header of MBINIT.REPAIRCLK result resp and raise the correct_detection if result is detected successfully or flag an error if packet is not detected successfully
										if result is detected successfully, send MBINIT.REPAIRCLK done req.
										if not, send TRAINERROR Entry req 
						5th cycle: if result is detected successfully, wait for MBINIT.REPAIRCLK done resp.
										if not, wait for TRAINERROR Entry resp and if the resp isn't detected for 8ms we will move to TRAINERROR state directly 
					*/
					REPAIRCLK: begin
						case (cycle_state)
							CYCLE1_TX: begin
								if (flag) begin
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									correct_detection 		<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									encoder_en_m 				<= 1'b1;
									data_out_m 				<= 64'h06000003_40294012;
									cycle_state 			<= CYCLE1_WAIT;
								end
							end
							CYCLE1_WAIT: begin
								sb_exit_m 				<= 1'b0;
								correct_detection 		<= 1'b0;
								trainerror_hs_m			<= 1'b0;
								encoder_en_m 				<= 1'b0;
								start_mb_m 				<= 1'b0;
								data_out_m 				<= 64'h00000000_00000000;
								if (module_en) begin
									if (data_in[61:0] == 62'h06000003_402A8012) begin
										packet_error 	<= 1'b0;
										cycle_state 	<= CYCLE2_TX;
									end else begin
										packet_error 	<= 1'b1;
									end
								end
							end
							CYCLE2_TX: begin
								sb_exit_m 				<= 1'b0;
								packet_error 			<= 1'b0;
								start_mb_m 				<= 1'b0;
								correct_detection 		<= 1'b0;
								trainerror_hs_m			<= 1'b0;
								encoder_en_m 				<= 1'b1;
								data_out_m 				<= 64'h06000004_40294012;
								cycle_state 			<= CYCLE2_WAIT;
							end
							CYCLE2_WAIT: begin
								data_out_m                <= 1'b0;
								encoder_en_m              <= 1'b0;
								sb_exit_m 				<= 1'b0;
								start_mb_m 				<= 1'b0;
								trainerror_hs_m			<= 1'b0;
								correct_detection 		<= 1'b0;
								if (module_en) begin
									if (data_in[61:0] == 62'h06000004_402A8012) begin
										packet_error 			<= 1'b0;
										cycle_state 			<= CYCLE3_TX;
									end else begin
										packet_error 			<= 1'b1;
									end
								end
							end
							CYCLE3_TX: begin
								sb_exit_m 			<= 1'b0;
								start_mb_m 			<= 1'b0;
								trainerror_hs_m 		<= 1'b0;
								packet_error 		<= 1'b0;
								correct_detection 	<= 1'b0;
								encoder_en_m 			<= 1'b1;
								data_out_m 			<= 64'h06000008_40294012;
								cycle_state 		<= CYCLE3_WAIT;
							end
							CYCLE3_WAIT: begin
								start_mb_m 			<= 1'b0;
								correct_detection 	<= 1'b0;
								trainerror_hs_m 		<= 1'b0;
								encoder_en_m 			<= 1'b0;
								data_out_m 			<= 64'h00000000_00000000;
								if (module_en) begin
									if (data_in[61:0] == 62'h06000008_402A8012) begin
										sb_exit_m 		<= 1'b1;
										packet_error 	<= 1'b0;
										cycle_state 	<= CYCLE1_TX;
									end else begin
										sb_exit_m 		<= 1'b0;
										packet_error 	<= 1'b1;
									end
								end
							end
							default: begin
								data_out_m 				<= 64'h00000000_00000000;
								encoder_en_m 				<= 1'b0;
								sb_exit_m 				<= 1'b0;
								packet_error 			<= 1'b0;
								start_mb_m 				<= 1'b0;
								correct_detection 		<= 1'b0;
								trainerror_hs_m			<= 1'b0;
								cycle_state 			<= CYCLE1_TX;
							end
						endcase
					end
					
					/* In REPAIRVAL state:
						1st cycle: send header message of MBINIT.REPAIRVAL init req
						2nd cycle: wait for the header of MBINIT.REPAIRVAL init resp and send start_mb_m to MB or flag an error if not detected
						3rd cycle: wait for end_mb and then send header message of MBINIT.REPAIRVAL result req
						4th cycle: wait for the header of MBINIT.REPAIRVAL result resp and rise the correct_detection if result is detected successfully 
										if result is detected successfully, send MBINIT.REPAIRVAL done req.
										if not, send TRAINERROR Entry req.
						5th cycle: if result is detected successfully, wait for MBINIT.REPAIRVAL done resp.
										if not, wait for TRAINERROR Entry resp and if the resp isn't detected for 8ms we will move to TRAINERROR state directly 
					*/
					REPAIRVAL: begin
						case (cycle_state)
							CYCLE1_TX: begin
								if (flag) begin
									encoder_en_m 				<= 1'b1;
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									correct_detection 		<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									data_out_m 				<= 64'h06000009_40294012;
									cycle_state 			<= CYCLE1_WAIT;
								end
							end
							CYCLE1_WAIT: begin
								encoder_en_m 				<= 1'b0;
								sb_exit_m 				<= 1'b0;
								correct_detection 		<= 1'b0;
								trainerror_hs_m			<= 1'b0;
								data_out_m 				<= 64'h00000000_00000000;
								if (module_en) begin
									if (data_in[61:0] == 62'h06000009_402A8012) begin
										packet_error 	<= 1'b0;
										start_mb_m 		<= 1'b1;
										cycle_state 	<= CYCLE2_TX;
									end else begin
										packet_error 	<= 1'b1;
										start_mb_m 		<= 1'b0;
									end
								end
							end
							CYCLE2_TX: begin
								sb_exit_m 				<= 1'b0;
								packet_error 			<= 1'b0;
								start_mb_m 				<= 1'b0;
								correct_detection 		<= 1'b0;
								trainerror_hs_m			<= 1'b0;
								if (end_mb) begin
									encoder_en_m 	<= 1'b1;
									data_out_m 	<= 64'h0600000A_40294012;
									cycle_state <= CYCLE2_WAIT;
								end else begin
									encoder_en_m 	<= 1'b0;
									data_out_m 	<= 64'h00000000_00000000;
								end
							end
							CYCLE2_WAIT: begin
								sb_exit_m 				<= 1'b0;
								start_mb_m 				<= 1'b0;
								trainerror_hs_m			<= 1'b0;
								encoder_en_m 	            <= 1'b0;
								data_out_m 	            <= 64'h00000000_00000000;

								if (module_en) begin
									if (data_in[61:0] == 62'h0600010A_402A8012) begin
										correct_detection 		<= 1'b1;
										packet_error 			<= 1'b0;
										cycle_state 			<= CYCLE3_TX;
									end else if (data_in[61:0] == 62'h0600000A_402A8012) begin
										correct_detection 		<= 1'b0;
										packet_error 			<= 1'b0;
										cycle_state 			<= CYCLE3_TX;
									end else  begin
										correct_detection 		<= 1'b0;
										packet_error 			<= 1'b1;
									end
								end
							end
							CYCLE3_TX: begin
								packet_error 	<= 1'b0;
								sb_exit_m 		<= 1'b0;
								start_mb_m 		<= 1'b0;
								trainerror_hs_m 	<= 1'b0;
								if (correct_detection) begin
									encoder_en_m 	<= 1'b1;
									data_out_m 	<= 64'h0600000C_40294012;
								end else begin
									encoder_en_m 	<= 1'b1;
									data_out_m 	<= 64'h06000000_40394012;
								end
								cycle_state 	<= CYCLE3_WAIT;
							end
							CYCLE3_WAIT: begin
								encoder_en_m 	<= 1'b0;
								start_mb_m 	<= 1'b0;
								data_out_m 	<= 64'h00000000_00000000;
								if (module_en) begin
									if (correct_detection) begin
										if (data_in[61:0] == 62'h0600000C_402A8012) begin
											packet_error 	<= 1'b0;
											sb_exit_m 		<= 1'b1;
											cycle_state 	<= CYCLE1_TX;
										end else begin
											packet_error 	<= 1'b1;
											sb_exit_m 		<= 1'b0;
										end
										trainerror_hs_m 		<= 1'b0;
									end else begin
										sb_exit_m 		<= 1'b0;
										packet_error 	<= 1'b0;
										if (data_in[61:0] == 62'h06000000_403A8012) begin
											trainerror_hs_m 	<= 1'b1;
											cycle_state 	<= CYCLE1_TX;
										end
									end
								end
							end
							default: begin
								data_out_m 				<= 64'h00000000_00000000;
								encoder_en_m 				<= 1'b0;
								sb_exit_m 				<= 1'b0;
								packet_error 			<= 1'b0;
								start_mb_m 				<= 1'b0;
								correct_detection 		<= 1'b0;
								trainerror_hs_m			<= 1'b0;
							end
						endcase
					end
					
					/* In REVERSALMB state:
						1st cycle: send header message of MBINIT.REVERSALMB init req
						2nd cycle: wait for the header of MBINIT.REVERSALMB init resp and if not detected raise error flag
						3rd cycle: send header message of MBINIT.REVERSALMB clear error req
						4th cycle: wait for the header of MBINIT.REVERSALMB clear error resp and send start_mb_m to MB if detected and flag an error if not detected
						5th cycle: wait for end_mb and then send header message of MBINIT.REVERSALMB result req
						6th cycle: wait for the header of MBINIT.REVERSALMB result resp 
						7th cycle: get the data of MBINIT.REVERSALMB result resp and ckeck on the successful lanes 
									if they are more than 50%, then the detection is successfully, 
									if not, then we will reverse and do the steps again, after that if the detection is successful we move,
									if not, we will reverse again and proceed to trainerror_hs_m
						8th cycle: if result is detected successfully, send MBINIT.REVERSALMB done req.
									if not, send TRAINERROR Entry req.
						9th cycle: if result is detected successfully, wait for MBINIT.REVERSALMB done resp.
									if not, wait for TRAINERROR Entry resp and if the resp isn't detected for 8ms we will move to TRAINERROR state directly 
					*/
					REVERSALMB: begin
						case (cycle_state)
							CYCLE1_TX: begin
								if (flag) begin
									encoder_en_m 				<= 1'b1;
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									correct_detection 		<= 1'b0;
									trainerror_hs_m 			<= 1'b0;
									data_out_m 				<= 64'h0600000D_40294012;
									cycle_state 			<= CYCLE1_WAIT;
								end
							end
							CYCLE1_WAIT: begin
								encoder_en_m 				<= 1'b0;
								sb_exit_m 				<= 1'b0;
								start_mb_m 				<= 1'b0;
								correct_detection 		<= 1'b0;
								trainerror_hs_m 			<= 1'b0;
								data_out_m 				<= 64'h00000000_00000000;
								if (module_en) begin
									if (data_in[61:0] == 62'h0600000D_402A8012) begin
										packet_error 	<= 1'b0;
										cycle_state 	<= CYCLE2_TX;
									end else begin
										packet_error 	<= 1'b1;
									end
								end
							end
							CYCLE2_TX: begin
								encoder_en_m 				<= 1'b1;
								sb_exit_m 				<= 1'b0;
								packet_error 			<= 1'b0;
								start_mb_m 				<= 1'b0;
								correct_detection 		<= 1'b0;
								trainerror_hs_m 			<= 1'b0;
								data_out_m 				<= 64'h0600000E_40294012;
								cycle_state 			<= CYCLE2_WAIT;
							end
							CYCLE2_WAIT: begin
								encoder_en_m 				<= 1'b0;
								sb_exit_m 				<= 1'b0;
								correct_detection 		<= 1'b0;
								trainerror_hs_m 			<= 1'b0;
								data_out_m 				<= 64'h00000000_00000000;
								if (module_en) begin
									if (data_in[61:0] == 62'h0600000E_402A8012) begin
										packet_error 	<= 1'b0;
										start_mb_m 		<= 1'b1;
										cycle_state 	<= CYCLE3_TX;
									end else begin
										packet_error 	<= 1'b1;
										start_mb_m 		<= 1'b0;
									end
								end
							end
							CYCLE3_TX: begin
								sb_exit_m 				<= 1'b0;
								packet_error 			<= 1'b0;
								start_mb_m 				<= 1'b0;
								correct_detection 		<= 1'b0;
								trainerror_hs_m 			<= 1'b0;
								if (end_mb) begin
									encoder_en_m 	<= 1'b1;
									data_out_m 	<= 64'h0600000F_40294012;
									cycle_state <= CYCLE3_WAIT;
								end else begin
									encoder_en_m 	<= 1'b0;
									data_out_m 	<= 64'h00000000_00000000;
								end
							end
							CYCLE3_WAIT: begin
								encoder_en_m 				<= 1'b0;
								sb_exit_m 				<= 1'b0;
								start_mb_m 				<= 1'b0;
								correct_detection 		<= 1'b0;
								trainerror_hs_m 			<= 1'b0;
								data_out_m 				<= 64'h00000000_00000000;
								if (module_en) begin
									if (data_in[61:0] == 62'h0600000F_402A801b) begin
										packet_error 	<= 1'b0;
										cycle_state 	<= CYCLE4_WAIT;
									end else  begin
										packet_error 	<= 1'b1;
									end
								end
							end
							CYCLE4_WAIT: begin
								encoder_en_m 				<= 1'b0;
								sb_exit_m 				<= 1'b0;
								packet_error 			<= 1'b0;
								start_mb_m 				<= 1'b0;
								trainerror_hs_m 			<= 1'b0;
								data_out_m 				<= 64'h00000000_00000000;
								if (module_en) begin
									if (lane_error && ~lane_reverse_error_count) begin 
										lane_reverse_error_count 	<= 1'b1;
										lane_reverse 				<= 1'b1;
										correct_detection 			<= 1'b0;
										cycle_state 				<= CYCLE2_TX;
									end else if (lane_reverse_error_count) begin
										lane_reverse_error_count 	<= 1'b0;
										cycle_state 				<= CYCLE5_TX;
										if (lane_error) begin
											correct_detection 	<= 1'b0;
											lane_reverse 		<= 1'b0;
										end else begin
											correct_detection 	<= 1'b1;
											lane_reverse 		<= 1'b1;
										end
									end else begin
										lane_reverse_error_count 	<= 1'b0;
										// lane_reverse 				<= 1'b0;
										correct_detection 			<= 1'b1;
										cycle_state 				<= CYCLE5_TX;
									end
								end else begin
									lane_reverse_error_count 	<= 1'b0;
									// lane_reverse 				<= 1'b0;
									correct_detection 			<= 1'b0;
								end 
							end
							CYCLE5_TX: begin
								encoder_en_m 				<= 1'b1;
								sb_exit_m 				<= 1'b0;
								packet_error 			<= 1'b0;
								start_mb_m 				<= 1'b0;
								trainerror_hs_m 			<= 1'b0;
								cycle_state 			<= CYCLE5_WAIT;
								if (correct_detection) begin
									data_out_m <= 64'h06000010_40294012;
								end else begin
									data_out_m <= 64'h06000000_40394012;
								end	
							end
							CYCLE5_WAIT: begin
								encoder_en_m 					<= 1'b0;
								data_out_m 					<= 64'h00000000_00000000;
								start_mb_m 					<= 1'b0;
								if (module_en) begin
									if (correct_detection) begin
										if (data_in[61:0] == 62'h06000010_402A8012) begin
											packet_error 	<= 1'b0;
											sb_exit_m 		<= 1'b1;
											cycle_state 	<= CYCLE1_TX;
										end else begin
											packet_error 	<= 1'b1;
											sb_exit_m 		<= 1'b0;
										end
									end else begin
										if (data_in[61:0] == 62'h06000000_403A8012) begin
											trainerror_hs_m 	<= 1'b1;
											cycle_state 	<= CYCLE1_TX;
										end
									end
								end
							end
							default: begin
								data_out_m 				<= 64'h00000000_00000000;
								encoder_en_m 				<= 1'b0;
								sb_exit_m 				<= 1'b0;
								packet_error 			<= 1'b0;
								start_mb_m 				<= 1'b0;
								correct_detection 		<= 1'b0;
								trainerror_hs_m			<= 1'b0;
								lane_reverse_error_count<= 1'b0;
								lane_reverse 			<= 1'b0;
							end
						endcase
					end
					
					/* In REPAIRMB State:
						1st cycle: send header message of MBINIT.REPAIRMB start req
						2nd cycle: wait for the header of MBINIT.REPAIRMB start resp and flag an error if not detected
						3rd cycle: send header message of Start Tx Init D to C point test req
						4th cycle: send data message of Start Tx Init D to C point test req
						5th cycle: wait for the header of Start Tx Init D to C point test resp and flag an error if not detected
						6th cycle: send header message of LFSR clear error req
						7th cycle: wait for the header of LFSR clear error resp and send start_mb_m and flag an error if not detected
						8th cycle: send header message of Tx Init D to C results req if end_mb has been sent
						9th cycle: wait for the header of Tx Init D to C results resp and flag an error if not detected
						10th cycle: wait for the data of Tx Init D to C results resp 
					*/
					REPAIRMB: begin
						case (cycle_state)
							CYCLE1_TX: begin
								if (flag) begin
									data_out_m 				<= 64'h06000011_40294012;
									encoder_en_m 				<= 1'b1;
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									correct_detection 		<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									cycle_state 			<= CYCLE1_WAIT;
								end
							end
							CYCLE1_WAIT: begin
								data_out_m 				<= 64'h00000000_00000000;
								encoder_en_m 				<= 1'b0;
								sb_exit_m 				<= 1'b0;
								start_mb_m 				<= 1'b0;
								correct_detection 		<= 1'b0;
								trainerror_hs_m			<= 1'b0;
								if (module_en) begin
									if (data_in[61:0] == 62'h06000011_402A8012) begin
										packet_error 	<= 1'b0;
										cycle_state 	<= CYCLE2_TX;
									end else begin
										packet_error 	<= 1'b1;
									end
								end
							end
							CYCLE2_TX: begin
								// Maximum Error Threshold "Default = 0" 
								data_out_m 				<= {12'h060, 12'h000, 40'h014021401B};
								encoder_en_m 				<= 1'b1;
								sb_exit_m 				<= 1'b0;
								packet_error 			<= 1'b0;
								start_mb_m 				<= 1'b0;
								correct_detection 		<= 1'b0;
								trainerror_hs_m			<= 1'b0;
								cycle_state 			<= CYCLE3_TX;
							end
							CYCLE3_TX: begin
								data_out_m 				<= 64'h2001000000000020;
								encoder_en_m 				<= 1'b1;
								sb_exit_m 				<= 1'b0;
								packet_error 			<= 1'b0;
								start_mb_m 				<= 1'b0;
								correct_detection 		<= 1'b0;
								trainerror_hs_m			<= 1'b0;
								cycle_state 			<= CYCLE3_WAIT;
							end
							CYCLE3_WAIT: begin
								data_out_m 				<= 64'h00000000_00000000;
								encoder_en_m 				<= 1'b0;
								sb_exit_m 				<= 1'b0;
								start_mb_m 				<= 1'b0;
								correct_detection 		<= 1'b0;
								trainerror_hs_m			<= 1'b0;
								if (module_en) begin
									if (data_in[61:0] == 62'h06000001_40228012) begin
										packet_error 	<= 1'b0;
										cycle_state 	<= CYCLE4_TX;
									end else begin
										packet_error 	<= 1'b1;
									end
								end
							end
							CYCLE4_TX: begin
								data_out_m 				<= 64'h06000002_40214012;
								encoder_en_m 				<= 1'b1;
								sb_exit_m 				<= 1'b0;
								packet_error 			<= 1'b0;
								start_mb_m 				<= 1'b0;
								correct_detection 		<= 1'b0;
								trainerror_hs_m			<= 1'b0;
								cycle_state 			<= CYCLE4_WAIT;
							end 
							CYCLE4_WAIT: begin
								data_out_m 				<= 64'h00000000_00000000;
								encoder_en_m 				<= 1'b0;
								sb_exit_m 				<= 1'b0;
								correct_detection 		<= 1'b0;
								trainerror_hs_m			<= 1'b0;
								if (module_en) begin
									if (data_in[61:0] == 62'h06000002_40228012) begin
										start_mb_m 		<= 1'b1;
										packet_error 	<= 1'b0;
										cycle_state 	<= CYCLE5_TX;
									end else begin
										start_mb_m 		<= 1'b0;
										packet_error 	<= 1'b1;
									end
								end
							end
							CYCLE5_TX: begin
								if (end_mb) begin
									encoder_en_m 	<= 1'b1;
									data_out_m 	<= 64'h06000003_40214012;
									cycle_state <= CYCLE5_WAIT;
								end else begin
									encoder_en_m 	<= 1'b0;
									data_out_m 	<= 64'h00000000_00000000;
								end
								sb_exit_m 				<= 1'b0;
								packet_error 			<= 1'b0;
								start_mb_m 				<= 1'b0;
								correct_detection 		<= 1'b0;
								trainerror_hs_m			<= 1'b0;
							end 
							CYCLE5_WAIT: begin
								data_out_m 				<= 64'h00000000_00000000;
								encoder_en_m 				<= 1'b0;
								sb_exit_m 				<= 1'b0;
								start_mb_m 				<= 1'b0;
								correct_detection 		<= 1'b0;
								trainerror_hs_m			<= 1'b0;
								if (module_en) begin
									if (data_in[39:0] == 40'h03_4022801B &&data_in[58:56] == 3'b110) begin
										packet_error 	<= 1'b0;
										cycle_state 	<= CYCLE6_WAIT;
									end else begin
										packet_error 	<= 1'b1;
									end
								end
							end
							CYCLE6_WAIT: begin
								data_out_m 				<= 64'h00000000_00000000;
								encoder_en_m 				<= 1'b0;
								sb_exit_m 				<= 1'b0;
								start_mb_m 				<= 1'b0;
								trainerror_hs_m			<= 1'b0;
								packet_error 			<= 1'b0;
								if (module_en) begin
									if (data_in[7:0] == 8'hFF && data_in[15:8] == 8'hFF) begin
										correct_detection <= 1'b1;
										width_degrade <= 3'b011;
									end else if (data_in[7:0] != 8'hFF && data_in[15:8] == 8'hFF) begin
										correct_detection <= 1'b1;
										width_degrade <= 3'b010;
									end else if (data_in[7:0] == 8'hFF && data_in[15:8] != 8'hFF) begin
										correct_detection <= 1'b1;
										width_degrade <= 3'b001;
									end else begin
										correct_detection <= 1'b0;
										width_degrade <= 3'b000;
									end
									cycle_state <= CYCLE7_TX;
								end
							end
							CYCLE7_TX: begin 
								data_out_m 				<= 64'h06000004_40214012;
								encoder_en_m 				<= 1'b1;
								sb_exit_m 				<= 1'b0;
								packet_error 			<= 1'b0;
								start_mb_m 				<= 1'b0;
								trainerror_hs_m			<= 1'b0;
								cycle_state 			<= CYCLE7_WAIT;
							end
							CYCLE7_WAIT: begin
								data_out_m 				<= 64'h00000000_00000000;
								encoder_en_m 				<= 1'b0;
								sb_exit_m 				<= 1'b0;
								start_mb_m 				<= 1'b0;
								trainerror_hs_m			<= 1'b0;
								if (module_en) begin
									if (data_in[61:0] == 62'h06000004_40228012) begin
										packet_error 	<= 1'b0;
										cycle_state 	<= CYCLE8_TX;
									end else begin
										packet_error 	<= 1'b1;
									end
								end
							end
							CYCLE8_TX: begin
								data_out_m <= {20'h06000,1'b0, width_degrade,40'h14_40294012};
								encoder_en_m 				<= 1'b1;
								sb_exit_m 				<= 1'b0;
								packet_error 			<= 1'b0;
								start_mb_m 				<= 1'b0;
								trainerror_hs_m			<= 1'b0;
								cycle_state 			<= CYCLE8_WAIT;
							end 
							CYCLE8_WAIT: begin
								data_out_m 				<= 64'h00000000_00000000;
								encoder_en_m 				<= 1'b0;
								sb_exit_m 				<= 1'b0;
								start_mb_m 				<= 1'b0;
								trainerror_hs_m			<= 1'b0;
								if (module_en) begin
									if (data_in[61:0] == 62'h06000014_402A8012) begin
										packet_error 	<= 1'b0;
										cycle_state 	<= CYCLE9_TX;
									end else begin
										packet_error 	<= 1'b1;
									end
								end
							end
							CYCLE9_TX: begin
								encoder_en_m 				<= 1'b1;
								sb_exit_m 				<= 1'b0;
								packet_error 			<= 1'b0;
								start_mb_m 				<= 1'b0;
								trainerror_hs_m 			<= 1'b0;
								cycle_state 			<= CYCLE9_WAIT;
								if (correct_detection) begin
									data_out_m <= 64'h06000013_40294012;
								end else begin
									data_out_m <= 64'h06000000_40394012;
								end	
							end
							CYCLE9_WAIT: begin
								encoder_en_m 					<= 1'b0;
								data_out_m 					<= 64'h00000000_00000000;
								start_mb_m 					<= 1'b0;
								if (module_en) begin
									if (correct_detection) begin
										if (data_in[61:0] == 62'h06000013_402A8012) begin
											packet_error 	<= 1'b0;
											sb_exit_m 		<= 1'b1;
											cycle_state 	<= CYCLE1_TX;
										end else begin
											packet_error 	<= 1'b1;
											sb_exit_m 		<= 1'b0;
										end
										trainerror_hs_m 		<= 1'b0;
									end else begin
										if (data_in[61:0] == 62'h06000000_403A8012) begin
											trainerror_hs_m 	<= 1'b1;
											cycle_state 	<= CYCLE1_TX;
										end
									end
								end
							end
							default: begin
								data_out_m 				<= 64'h00000000_00000000;
								encoder_en_m 				<= 1'b0;
								sb_exit_m 				<= 1'b0;
								packet_error 			<= 1'b0;
								start_mb_m 				<= 1'b0;
								correct_detection 		<= 1'b0;
								trainerror_hs_m			<= 1'b0;
								cycle_state 			<= CYCLE1_TX;
							end
						endcase
					end
					endcase
				end 
				
				MBTRAIN: begin
					path_sel <= 1'b0;
					case (mbtrain_cs)
						VALVREF: begin
							case (cycle_state)
								CYCLE1_TX: begin
									if (flag) begin
										data_out_m 				<= 64'h06000000_402D4012;
										encoder_en_m 				<= 1'b1;
										sb_exit_m 				<= 1'b0;
										packet_error 			<= 1'b0;
										start_mb_m 				<= 1'b0;
										trainerror_hs_m			<= 1'b0;
										cycle_state 			<= CYCLE1_WAIT;
									end
								end 
								CYCLE1_WAIT: begin 
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									sb_exit_m 				<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									if (module_en) begin
										if (data_in[61:0] == 62'h06000000_402E8012) begin
											packet_error 	<= 1'b0;
											cycle_state 	<= CYCLE2_TX;
										end else begin
											packet_error 	<= 1'b1;
										end
									end
								end
								CYCLE2_TX: begin
									// Maximum Error Threshold "Default = 0" 
									data_out_m 				<= {12'h060, 12'h000, 40'h07_4021401B};
									encoder_en_m 				<= 1'b1;
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									cycle_state 			<= CYCLE3_TX;
								end
								CYCLE3_TX: begin
									data_out_m 				<= 64'h800000000020;
									encoder_en_m 				<= 1'b1;
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									cycle_state 			<= CYCLE3_WAIT;
								end
								CYCLE3_WAIT: begin
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									sb_exit_m 				<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									if (module_en) begin
										if (data_in[61:0] == 62'h06000007_40228012) begin
											packet_error 	<= 1'b0;
											cycle_state 	<= CYCLE4_TX;
										end else begin
											packet_error 	<= 1'b1;
										end
									end
								end
								CYCLE4_TX: begin
									start_rx 				<= 1'b1;
									data_out_m 				<= 64'h06000002_40214012;
									encoder_en_m 				<= 1'b1;
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									cycle_state 			<= CYCLE4_WAIT;
								end 
								CYCLE4_WAIT: begin
									start_rx 				<= 1'b0;
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									sb_exit_m 				<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									if (module_en) begin
										if (data_in[61:0] == 62'h06000002_40228012) begin
											packet_error 	<= 1'b0;
											cycle_state 	<= CYCLE5_WAIT;
										end else begin
											packet_error 	<= 1'b1;
										end
									end
								end
								CYCLE5_WAIT: begin
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									sb_exit_m 				<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									if (module_en) begin
										if (data_in[61:0] == 62'h06000008_40214012) begin
											packet_error 	<= 1'b0;
											cycle_state 	<= CYCLE5_TX;
										end else begin
											packet_error 	<= 1'b1;
										end
									end
								end
								CYCLE5_TX: begin
									data_out_m 				<= 64'h06000008_40228012;
									encoder_en_m 				<= 1'b1;
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									cycle_state 			<= CYCLE6_TX;
								end
								CYCLE6_TX: begin
									data_out_m 				<= 64'h06000009_40214012;
									encoder_en_m 				<= 1'b1;
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									cycle_state 			<= CYCLE6_WAIT;
								end
								CYCLE6_WAIT: begin
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									sb_exit_m 				<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									if (module_en) begin
										if (data_in[61:0] == 62'h06000009_40228012) begin
											packet_error 	<= 1'b0;
											cycle_state 	<= CYCLE7_TX;
										end else begin
											packet_error 	<= 1'b1;
										end
									end
								end
								CYCLE7_TX: begin
									data_out_m 				<= 64'h06000001_402D4012;
									encoder_en_m 				<= 1'b1;
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									cycle_state 			<= CYCLE7_WAIT;
								end
								CYCLE7_WAIT: begin
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									if (module_en) begin
										if (data_in[61:0] == 62'h06000001_402E8012) begin
											packet_error 	<= 1'b0;
											sb_exit_m 		<= 1'b1;
											cycle_state 	<= CYCLE1_TX;
										end else begin
											packet_error 	<= 1'b1;
											sb_exit_m 		<= 1'b0;
										end
									end
								end
								default: begin
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
								end
							endcase
						end
						DATAVREF: begin
							case (cycle_state)
								CYCLE1_TX: begin
									if (flag) begin
										data_out_m 				<= 64'h06000002_402D4012;
										encoder_en_m 				<= 1'b1;
										sb_exit_m 				<= 1'b0;
										packet_error 			<= 1'b0;
										start_mb_m 				<= 1'b0;
										trainerror_hs_m			<= 1'b0;
										cycle_state 			<= CYCLE1_WAIT;
									end
								end 
								CYCLE1_WAIT: begin 
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									sb_exit_m 				<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									if (module_en) begin
										if (data_in[61:0] == 62'h06000002_402E8012) begin
											packet_error 	<= 1'b0;
											cycle_state 	<= CYCLE2_TX;
										end else begin
											packet_error 	<= 1'b1;
										end
									end
								end
								CYCLE2_TX: begin
									// Maximum Error Threshold "Default = 0" 
									data_out_m 				<= {12'h060, 12'h000, 40'h07_4021401B};
									encoder_en_m 				<= 1'b1;
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									cycle_state 			<= CYCLE3_TX;
								end
								CYCLE3_TX: begin
									data_out_m 				<= 64'h2001000000000020;
									encoder_en_m 				<= 1'b1;
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									cycle_state 			<= CYCLE3_WAIT;
								end
								CYCLE3_WAIT: begin
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									sb_exit_m 				<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									if (module_en) begin
										if (data_in[61:0] == 62'h06000007_40228012) begin
											packet_error 	<= 1'b0;
											cycle_state 	<= CYCLE4_TX;
										end else begin
											packet_error 	<= 1'b1;
										end
									end
								end
								CYCLE4_TX: begin
									start_rx 				<= 1'b1;
									data_out_m 				<= 64'h06000002_40214012;
									encoder_en_m 				<= 1'b1;
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									cycle_state 			<= CYCLE4_WAIT;
								end
								CYCLE4_WAIT: begin
									start_rx 				<= 1'b0;
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									sb_exit_m 				<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									if (module_en) begin
										if (data_in[61:0] == 62'h06000002_40228012) begin
											packet_error 	<= 1'b0;
											cycle_state 	<= CYCLE5_WAIT;
										end else begin
											packet_error 	<= 1'b1;
										end
									end
								end 
								CYCLE5_WAIT: begin
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									sb_exit_m 				<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									if (module_en) begin
										if (data_in[61:0] == 62'h06000008_40214012) begin
											packet_error 	<= 1'b0;
											cycle_state 	<= CYCLE5_TX;
										end else begin
											packet_error 	<= 1'b1;
										end
									end
								end
								CYCLE5_TX: begin
									data_out_m 				<= 64'h06000008_40228012;
									encoder_en_m 				<= 1'b1;
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									cycle_state 			<= CYCLE6_TX;
								end
								CYCLE6_TX: begin
									data_out_m 				<= 64'h06000009_40214012;
									encoder_en_m 				<= 1'b1;
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									cycle_state 			<= CYCLE6_WAIT;
								end
								CYCLE6_WAIT: begin
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									sb_exit_m 				<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									if (module_en) begin
										if (data_in[61:0] == 62'h06000009_40228012) begin
											packet_error 	<= 1'b0;
											cycle_state 	<= CYCLE7_TX;
										end else begin
											packet_error 	<= 1'b1;
										end
									end 
								end
								CYCLE7_TX: begin
									data_out_m 				<= 64'h06000003_402D4012;
									encoder_en_m 				<= 1'b1;
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									cycle_state 			<= CYCLE7_WAIT;
								end
								CYCLE7_WAIT: begin
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									if (module_en) begin
										if (data_in[61:0] == 62'h06000003_402E8012) begin
											packet_error 	<= 1'b0;
											sb_exit_m 		<= 1'b1;
											cycle_state 	<= CYCLE1_TX;
										end else begin
											packet_error 	<= 1'b1;
											sb_exit_m 		<= 1'b0;
										end
									end
								end
								default: begin
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
								end
							endcase
						end
						SPEEDIDLE: begin
							case (cycle_state) 
								CYCLE1_TX: begin
									if (flag) begin
										sb_exit_m 		<= 1'b0;
										packet_error 	<= 1'b0;
										start_mb_m 		<= 1'b0;
										trainerror_hs_m 	<= 1'b0;
										speed_idle_req_m 	<= 1'b0;
										if (prev_mbtrain_cs == DATAVREF) begin
											pl_speedmode <= max_speed;
											internal_error <= 1'b0;
											data_out_m <= 64'h06000004_402D4012;
											encoder_en_m <= 1'b1;
											cycle_state 	<= CYCLE1_WAIT;
										end else if (prev_mbtrain_cs == LINKSPEED || prev_cs == PHYRETRAIN) begin
											if (max_speed != 4'h0) begin
												pl_speedmode <= pl_speedmode - 1;
												internal_error <= 1'b0;
												data_out_m <= 64'h06000004_402D4012;
												encoder_en_m <= 1'b1;
												cycle_state 	<= CYCLE1_WAIT;
											end else begin
												internal_error <= 1'b1;
												data_out_m <= 64'h00000000_00000000;
												encoder_en_m <= 1'b0;
											end
										end else begin
											internal_error <= 1'b1;
											data_out_m <= 64'h00000000_00000000;
											encoder_en_m <= 1'b0;
										end
									end
								end
								CYCLE1_WAIT: begin
									start_mb_m <= 1'b0;
									encoder_en_m <= 1'b0;
									trainerror_hs_m 	<= 1'b0;
									data_out_m <= 64'h00000000_00000000;
									if (module_en) begin
										if (data_in[61:0] == 62'h06000004_402E8012) begin
											packet_error 	<= 1'b0;
											sb_exit_m 		<= 1'b1;
											cycle_state 	<= CYCLE1_TX;
										end else begin
											packet_error 	<= 1'b1;
											sb_exit_m 		<= 1'b0;
										end
									end
								end
								default: begin
									data_out_m 		<= 64'h00000000_00000000;
									encoder_en_m 		<= 1'b0;
									packet_error 	<= 1'b0;
									internal_error 	<= 1'b0;
									sb_exit_m 		<= 1'b0;
									start_mb_m 		<= 1'b0;
									trainerror_hs_m 	<= 1'b0;
								end
							endcase
						end
						TXSELFCAL: begin
							case (cycle_state)
								CYCLE1_TX: begin
									if (flag) begin
										data_out_m 				<= 64'h06000005_402D4012;
										encoder_en_m 				<= 1'b1;
										sb_exit_m 				<= 1'b0;
										packet_error 			<= 1'b0;
										start_mb_m 				<= 1'b0;
										trainerror_hs_m			<= 1'b0;
										cycle_state 			<= CYCLE1_WAIT;
									end
								end
								CYCLE1_WAIT: begin
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									if (module_en) begin
										if (data_in[61:0] == 62'h06000005_402E8012) begin
											sb_exit_m 		<= 1'b1;
											packet_error 	<= 1'b0;
											cycle_state 	<= CYCLE1_TX;
										end else begin
											sb_exit_m 		<= 1'b0;
											packet_error 	<= 1'b1;
										end
									end
								end
								default: begin
									data_out_m 		<= 64'h00000000_00000000;
									encoder_en_m 		<= 1'b0;
									sb_exit_m 		<= 1'b0;
									packet_error 	<= 1'b0;
									start_mb_m 		<= 1'b0;
									trainerror_hs_m 	<= 1'b0;
								end 
							endcase
						end
						
						RXCLKCAL: begin
							case (cycle_state)
								CYCLE1_TX: begin
									if (flag) begin
										data_out_m 				<= 64'h06000006_402D4012;
										encoder_en_m 				<= 1'b1;
										sb_exit_m 				<= 1'b0;
										packet_error 			<= 1'b0;
										start_mb_m 				<= 1'b0;
										trainerror_hs_m			<= 1'b0;
										cycle_state 			<= CYCLE1_WAIT;
									end
								end
								CYCLE1_WAIT: begin
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									sb_exit_m 				<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									if (module_en) begin
										if (data_in[61:0] == 62'h06000006_402E8012) begin
											packet_error 	<= 1'b0;
											cycle_state 	<= CYCLE2_TX;
										end else begin
											packet_error 	<= 1'b1;
										end
									end
								end
								CYCLE2_TX: begin
									data_out_m 				<= 64'h06000007_402D4012;
									encoder_en_m 				<= 1'b1;
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									cycle_state 			<= CYCLE2_WAIT;
								end
								CYCLE2_WAIT: begin
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									if (module_en) begin
										if (data_in[61:0] == 62'h06000007_402E8012) begin
											sb_exit_m 		<= 1'b1;
											packet_error 	<= 1'b0;
											cycle_state 	<= CYCLE1_TX;
										end else begin
											sb_exit_m 		<= 1'b0;
											packet_error 	<= 1'b1;
										end
									end
								end
								default: begin
									data_out_m 		<= 64'h00000000_00000000;
									encoder_en_m 		<= 1'b0;
									sb_exit_m 		<= 1'b0;
									packet_error 	<= 1'b0;
									start_mb_m 		<= 1'b0;
									trainerror_hs_m 	<= 1'b0;
								end
							endcase
						end
						
						VALTRAINCENTER: begin
							case (cycle_state)
								CYCLE1_TX: begin
									if (flag) begin
										data_out_m 				<= 64'h06000008_402D4012;
										encoder_en_m 				<= 1'b1;
										sb_exit_m 				<= 1'b0;
										packet_error 			<= 1'b0;
										start_mb_m 				<= 1'b0;
										trainerror_hs_m			<= 1'b0;
										cycle_state 			<= CYCLE1_WAIT;
									end
								end 
								CYCLE1_WAIT: begin 
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									sb_exit_m 				<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									if (module_en) begin
										if (data_in[61:0] == 62'h06000008_402E8012) begin
											packet_error 	<= 1'b0;
											cycle_state 	<= CYCLE2_TX;
										end else begin
											packet_error 	<= 1'b1;
										end
									end
								end
								CYCLE2_TX: begin
									// Maximum Error Threshold "Default = 0" 
									data_out_m 				<= {12'h060, 12'h000, 40'h014021401B};
									encoder_en_m 				<= 1'b1;
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									correct_detection 		<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									cycle_state 			<= CYCLE3_TX;
								end
								CYCLE3_TX: begin
									data_out_m 				<= 64'h800000000020;
									encoder_en_m 				<= 1'b1;
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									cycle_state 			<= CYCLE3_WAIT;
								end
								CYCLE3_WAIT: begin
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									sb_exit_m 				<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									if (module_en) begin
										if (data_in[61:0] == 62'h06000001_40228012) begin
											packet_error 	<= 1'b0;
											cycle_state 	<= CYCLE4_TX;
										end else begin
											packet_error 	<= 1'b1;
										end
									end
								end
								CYCLE4_TX: begin
									data_out_m 				<= 64'h06000002_40214012;
									encoder_en_m 				<= 1'b1;
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									cycle_state 			<= CYCLE4_WAIT;
								end 
								CYCLE4_WAIT: begin
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									sb_exit_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									if (module_en) begin
										if (data_in[61:0] == 62'h06000002_40228012) begin
											start_mb_m 		<= 1'b1;
											packet_error 	<= 1'b0;
											cycle_state 	<= CYCLE5_TX;
										end else begin
											start_mb_m 		<= 1'b0;
											packet_error 	<= 1'b1;
										end
									end
								end
								CYCLE5_TX: begin
									if (end_mb) begin
										encoder_en_m 	<= 1'b1;
										data_out_m 	<= 64'h06000003_40214012;
										cycle_state <= CYCLE5_WAIT;
									end 
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
								end 
								CYCLE5_WAIT: begin
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									sb_exit_m 				<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									if (module_en) begin
										if (data_in[39:0] == 40'h03_4022801B && data_in[58:56] =='b110) begin
											if (data_in[45] == 1'b1) begin
												correct_detection <= 1'b1;
											end else begin
												correct_detection <= 1'b0;
											end
											packet_error 	<= 1'b0;
											cycle_state 	<= CYCLE6_WAIT;
										end else begin
											packet_error 	<= 1'b1;
										end
									end
								end
								CYCLE6_WAIT: begin
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									sb_exit_m 				<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									packet_error 			<= 1'b0;
									if (module_en) begin
										cycle_state <= CYCLE7_TX;
									end
								end
								CYCLE7_TX: begin 
									data_out_m 				<= 64'h06000004_40214012;
									encoder_en_m 				<= 1'b1;
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									cycle_state 			<= CYCLE7_WAIT;
								end
								CYCLE7_WAIT: begin
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									sb_exit_m 				<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									if (module_en) begin
										if (data_in[61:0] == 62'h06000004_40228012) begin
											packet_error 	<= 1'b0;
											cycle_state 	<= CYCLE8_TX;
										end else begin
											packet_error 	<= 1'b1;
										end
									end
								end
								CYCLE8_TX: begin
									encoder_en_m 				<= 1'b1;
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m 			<= 1'b0;
									cycle_state 			<= CYCLE8_WAIT;
									if (correct_detection) begin
										data_out_m <= 64'h06000009_402D4012;
									end else begin
										data_out_m <= 64'h06000000_40394012;
									end	
								end
								CYCLE8_WAIT: begin
									data_out_m 					<= 64'h00000000_00000000;
									encoder_en_m 					<= 1'b0;
									start_mb_m 					<= 1'b0;
									if (module_en) begin
										if (correct_detection) begin
											if (data_in[61:0] == 62'h06000009_402E8012) begin
												packet_error 	<= 1'b0;
												sb_exit_m 		<= 1'b1;
												cycle_state 	<= CYCLE1_TX;
											end else begin
												packet_error 	<= 1'b1;
												sb_exit_m 		<= 1'b0;
											end
											trainerror_hs_m 		<= 1'b0;
										end else begin
											packet_error 	<= 1'b0;
											sb_exit_m 		<= 1'b0;
											if (data_in[61:0] == 62'h06000000_403A8012) begin
												trainerror_hs_m 	<= 1'b1;
												cycle_state 	<= CYCLE1_TX;
											end
										end
									end
								end
								default: begin
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									correct_detection 		<= 1'b0;
									trainerror_hs_m			<= 1'b0;
								end
							endcase
						end
						
						VALTRAINVREF: begin
							case (cycle_state)
								CYCLE1_TX: begin
									if (flag) begin
										data_out_m 				<= 64'h0600000A_402D4012;
										encoder_en_m 				<= 1'b1;
										sb_exit_m 				<= 1'b0;
										packet_error 			<= 1'b0;
										start_mb_m 				<= 1'b0;
										trainerror_hs_m			<= 1'b0;
										cycle_state 			<= CYCLE1_WAIT;
									end
								end 
								CYCLE1_WAIT: begin 
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									sb_exit_m 				<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									if (module_en) begin
										if (data_in[61:0] == 62'h0600000A_402E8012) begin
											packet_error 	<= 1'b0;
											cycle_state 	<= CYCLE2_TX;
										end else begin
											packet_error 	<= 1'b1;
										end
									end
								end
								CYCLE2_TX: begin
									// Maximum Error Threshold "Default = 0" 
									data_out_m 				<= {12'h060, 12'h000, 40'h07_4021401B};
									encoder_en_m 				<= 1'b1;
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									cycle_state 			<= CYCLE3_TX;
								end
								CYCLE3_TX: begin
									data_out_m 				<= 64'h800000000020;
									encoder_en_m 				<= 1'b1;
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									cycle_state 			<= CYCLE3_WAIT;
								end
								CYCLE3_WAIT: begin
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									sb_exit_m 				<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									if (module_en) begin
										if (data_in[61:0] == 62'h06000007_40228012) begin
											packet_error 	<= 1'b0;
											cycle_state 	<= CYCLE4_TX;
										end else begin
											packet_error 	<= 1'b1;
										end
									end 
								end
								CYCLE4_TX: begin
									start_rx 				<= 1'b1;
									data_out_m 				<= 64'h06000002_40214012;
									encoder_en_m 				<= 1'b1;
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									cycle_state 			<= CYCLE4_WAIT;
								end 
								CYCLE4_WAIT: begin
									start_rx 				<= 1'b0;
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									sb_exit_m 				<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									if (module_en) begin
										if (data_in[61:0] == 62'h06000002_40228012) begin
											packet_error 	<= 1'b0;
											cycle_state 	<= CYCLE5_WAIT;
										end else begin
											packet_error 	<= 1'b1;
										end
									end
								end
								CYCLE5_WAIT: begin
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									sb_exit_m 				<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									if (module_en) begin
										if (data_in[61:0] == 62'h06000008_40214012) begin
											packet_error 	<= 1'b0;
											cycle_state 	<= CYCLE5_TX;
										end else begin
											packet_error 	<= 1'b1;
										end
									end
								end
								CYCLE5_TX: begin
									data_out_m 				<= 64'h06000008_40228012;
									encoder_en_m 				<= 1'b1;
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									cycle_state 			<= CYCLE6_TX;
								end
								CYCLE6_TX: begin
									data_out_m 				<= 64'h06000009_40214012;
									encoder_en_m 				<= 1'b1;
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									cycle_state 			<= CYCLE6_WAIT;
								end
								CYCLE6_WAIT: begin
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									sb_exit_m 				<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									if (module_en) begin
										if (data_in[61:0] == 62'h06000009_40228012) begin
											packet_error 	<= 1'b0;
											cycle_state 	<= CYCLE7_TX;
										end else begin
											packet_error 	<= 1'b1;
										end
									end 
								end
								CYCLE7_TX: begin
									data_out_m 				<= 64'h0600000B_402D4012;
									encoder_en_m 				<= 1'b1;
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									cycle_state 			<= CYCLE7_WAIT;
								end
								CYCLE7_WAIT: begin
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									if (module_en) begin
										if (data_in[61:0] == 62'h0600000B_402E8012) begin
											packet_error 	<= 1'b0;
											sb_exit_m 		<= 1'b1;
											cycle_state 	<= CYCLE1_TX;
										end else begin
											packet_error 	<= 1'b1;
											sb_exit_m 		<= 1'b0;
										end
									end
								end
								default: begin
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
								end
							endcase
						end
						
						DATATRAINCENTER1: begin
							case (cycle_state)
								CYCLE1_TX: begin
									if (flag) begin
										data_out_m 				<= 64'h0600000C_402D4012;
										encoder_en_m 				<= 1'b1;
										sb_exit_m 				<= 1'b0;
										packet_error 			<= 1'b0;
										start_mb_m 				<= 1'b0;
										trainerror_hs_m			<= 1'b0;
										cycle_state 			<= CYCLE1_WAIT;
									end
								end 
								CYCLE1_WAIT: begin 
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									sb_exit_m 				<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									if (module_en) begin
										if (data_in[61:0] == 62'h0600000C_402E8012) begin
											packet_error 	<= 1'b0;
											cycle_state 	<= CYCLE2_TX;
										end else begin
											packet_error 	<= 1'b1;
										end
									end
								end
								CYCLE2_TX: begin
									// Maximum Error Threshold "Default = 0" 
									data_out_m 				<= {12'h060, 12'h000, 40'h014021401B};
									encoder_en_m 				<= 1'b1;
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									cycle_state 			<= CYCLE3_TX;
								end
								CYCLE3_TX: begin
									//////// read data from memory
									data_out_m 				<= 64'h800000000020;
									encoder_en_m 				<= 1'b1;
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									cycle_state 			<= CYCLE3_WAIT;
								end
								CYCLE3_WAIT: begin
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									sb_exit_m 				<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									if (module_en) begin
										if (data_in[61:0] == 62'h06000001_40228012) begin
											packet_error 	<= 1'b0;
											cycle_state 	<= CYCLE4_TX;
										end else begin
											packet_error 	<= 1'b1;
										end
									end
								end
								CYCLE4_TX: begin
									data_out_m 				<= 64'h06000002_40214012;
									encoder_en_m 				<= 1'b1;
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									cycle_state 			<= CYCLE4_WAIT;
								end 
								CYCLE4_WAIT: begin
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									sb_exit_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									if (module_en) begin
										if (data_in[61:0] == 62'h06000002_40228012) begin
											start_mb_m 		<= 1'b1;
											packet_error 	<= 1'b0;
											cycle_state 	<= CYCLE5_TX;
										end else begin
											start_mb_m 		<= 1'b0;
											packet_error 	<= 1'b1;
										end
									end
								end
								CYCLE5_TX: begin
									if (end_mb) begin
										encoder_en_m 	<= 1'b1;
										data_out_m 	<= 64'h06000003_40214012;
										cycle_state <= CYCLE5_WAIT;
									end
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
								end 
								CYCLE5_WAIT: begin
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									sb_exit_m 				<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									if (module_en) begin
										if (data_in[39:0] == 40'h03_4022801B && data_in[58:56] == 'b110) begin
											if (data_in[44] == 1'b1) begin
												correct_detection <= 1'b1;
											end else begin
												correct_detection <= 1'b0;
											end
											packet_error 	<= 1'b0;
											cycle_state 	<= CYCLE6_WAIT;
										end else begin
											packet_error 	<= 1'b1;
										end
									end
								end
								CYCLE6_WAIT: begin
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									sb_exit_m 				<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									packet_error 			<= 1'b0;
									if (module_en) begin
										cycle_state <= CYCLE7_TX;
									end
								end
								CYCLE7_TX: begin 
									data_out_m 				<= 64'h06000004_40214012;
									encoder_en_m 				<= 1'b1;
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									cycle_state 			<= CYCLE7_WAIT;
								end
								CYCLE7_WAIT: begin
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									sb_exit_m 				<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									if (module_en) begin
										if (data_in[61:0] == 62'h06000004_40228012) begin
											packet_error 	<= 1'b0;
											cycle_state 	<= CYCLE8_TX;
										end else begin
											packet_error 	<= 1'b1;
										end
									end
								end
								CYCLE8_TX: begin
									encoder_en_m 				<= 1'b1;
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m 			<= 1'b0;
									cycle_state 			<= CYCLE8_WAIT;
									if (correct_detection) begin
										data_out_m <= 64'h0600000D_402D4012;
									end else begin
										data_out_m <= 64'h06000000_40394012;
									end	
								end
								CYCLE8_WAIT: begin
									encoder_en_m 					<= 1'b0;
									data_out_m 					<= 64'h00000000_00000000;
									start_mb_m 					<= 1'b0;
									if (module_en) begin
										if (correct_detection) begin
											if (data_in[61:0] == 62'h0600000D_402E8012) begin
												packet_error 	<= 1'b0;
												sb_exit_m 		<= 1'b1;
												cycle_state 	<= CYCLE1_TX;
											end else begin
												packet_error 	<= 1'b1;
												sb_exit_m 		<= 1'b0;
											end
											trainerror_hs_m 		<= 1'b0;
										end else begin
											packet_error 		<= 1'b0;
											sb_exit_m 			<= 1'b0;
											if (data_in[61:0] == 62'h06000000_403A8012) begin
												trainerror_hs_m 	<= 1'b1;
												cycle_state 	<= CYCLE1_TX;
											end
										end
									end
								end
								default: begin
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									correct_detection 		<= 1'b0;
									trainerror_hs_m			<= 1'b0;
								end
							endcase
						end
						
						DATATRAINVREF: begin
							case (cycle_state)
								CYCLE1_TX: begin
									if (flag) begin
										data_out_m 				<= 64'h0600000E_402D4012;
										encoder_en_m 				<= 1'b1;
										sb_exit_m 				<= 1'b0;
										packet_error 			<= 1'b0;
										start_mb_m 				<= 1'b0;
										trainerror_hs_m			<= 1'b0;
										cycle_state 			<= CYCLE1_WAIT;
									end
								end 
								CYCLE1_WAIT: begin 
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									sb_exit_m 				<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									if (module_en) begin
										if (data_in[61:0] == 62'h0600000E_402E8012) begin
											packet_error 	<= 1'b0;
											cycle_state 	<= CYCLE2_TX;
										end else begin
											packet_error 	<= 1'b1;
										end
									end
								end
								CYCLE2_TX: begin
									// Maximum Error Threshold "Default = 0" 
									data_out_m 				<= {12'h060, 12'h000, 40'h07_4021401B};
									encoder_en_m 				<= 1'b1;
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									cycle_state 			<= CYCLE3_TX;
								end
								CYCLE3_TX: begin
									data_out_m 				<= 64'h2000000000020;
									encoder_en_m 				<= 1'b1;
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									cycle_state 			<= CYCLE3_WAIT;
								end
								CYCLE3_WAIT: begin
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									sb_exit_m 				<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									if (module_en) begin
										if (data_in[61:0] == 62'h06000007_40228012) begin
											packet_error 	<= 1'b0;
											cycle_state 	<= CYCLE4_TX;
										end else begin
											packet_error 	<= 1'b1;
										end
									end
								end
								CYCLE4_TX: begin
									start_rx 				<= 1'b1;
									data_out_m 				<= 64'h06000002_40214012;
									encoder_en_m 				<= 1'b1;
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									cycle_state 			<= CYCLE4_WAIT;
								end
								CYCLE4_WAIT: begin
									start_rx 				<= 1'b0;
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									sb_exit_m 				<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									if (module_en) begin
										if (data_in[61:0] == 62'h06000002_40228012) begin
											packet_error 	<= 1'b0;
											cycle_state 	<= CYCLE5_WAIT;
										end else begin
											packet_error 	<= 1'b1;
										end
									end
								end
								CYCLE5_WAIT: begin
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									sb_exit_m 				<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									if (module_en) begin
										if (data_in[61:0] == 62'h06000008_40214012) begin
											packet_error 	<= 1'b0;
											cycle_state 	<= CYCLE5_TX;
										end else begin
											packet_error 	<= 1'b1;
										end
									end
								end
								CYCLE5_TX: begin
									data_out_m 				<= 64'h06000008_40228012;
									encoder_en_m 				<= 1'b1;
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									cycle_state 			<= CYCLE6_TX;
								end
								CYCLE6_TX: begin
									data_out_m 				<= 64'h06000009_40214012;
									encoder_en_m 				<= 1'b1;
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									cycle_state 			<= CYCLE6_WAIT;
								end
								CYCLE6_WAIT: begin
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									sb_exit_m 				<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									if (module_en) begin
										if (data_in[61:0] == 62'h06000009_40228012) begin
											packet_error 	<= 1'b0;
											cycle_state 	<= CYCLE7_TX;
										end else begin
											packet_error 	<= 1'b1;
										end
									end
								end
								CYCLE7_TX: begin
									data_out_m 				<= 64'h06000010_402D4012;
									encoder_en_m 				<= 1'b1;
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									cycle_state 			<= CYCLE7_WAIT;
								end
								CYCLE7_WAIT: begin
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									if (module_en) begin
										if (data_in[61:0] == 62'h06000010_402E8012) begin
											packet_error 	<= 1'b0;
											sb_exit_m 		<= 1'b1;
											cycle_state 	<= CYCLE1_TX;
										end else begin
											packet_error 	<= 1'b1;
											sb_exit_m 		<= 1'b0;
										end
									end
								end
								default: begin
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
								end
							endcase
						end
						
						RXDESKEW: begin
							case (cycle_state)
								CYCLE1_TX: begin
									if (flag) begin
										data_out_m 				<= 64'h06000011_402D4012;
										encoder_en_m 				<= 1'b1;
										sb_exit_m 				<= 1'b0;
										packet_error 			<= 1'b0;
										start_mb_m 				<= 1'b0;
										trainerror_hs_m			<= 1'b0;
										cycle_state 			<= CYCLE1_WAIT;
									end
								end 
								CYCLE1_WAIT: begin 
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									sb_exit_m 				<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									if (module_en) begin
										if (data_in[61:0] == 62'h06000011_402E8012) begin
											packet_error 	<= 1'b0;
											cycle_state 	<= CYCLE2_TX;
										end else begin
											packet_error 	<= 1'b1;
										end
									end
								end
								CYCLE2_TX: begin
									// Maximum Error Threshold "Default = 0" 
									data_out_m 				<= {12'h060, 12'h000, 40'h07_4021401B};
									encoder_en_m 				<= 1'b1;
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									cycle_state 			<= CYCLE3_TX;
								end
								CYCLE3_TX: begin
									//////// read data from memory
									data_out_m 				<= 64'h2001000000000020;
									encoder_en_m 				<= 1'b1;
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									cycle_state 			<= CYCLE3_WAIT;
								end
								CYCLE3_WAIT: begin
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									sb_exit_m 				<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									if (module_en) begin
										if (data_in[61:0] == 62'h06000007_40228012) begin
											packet_error 	<= 1'b0;
											cycle_state 	<= CYCLE4_TX;
										end else begin
											packet_error 	<= 1'b1;
										end
									end
								end
								CYCLE4_TX: begin
									start_rx 				<= 1'b1;
									data_out_m 				<= 64'h06000002_40214012;
									encoder_en_m 				<= 1'b1;
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									cycle_state 			<= CYCLE4_WAIT;
								end 
								CYCLE4_WAIT: begin
									start_rx 				<= 1'b0;
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									sb_exit_m 				<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									if (module_en) begin
										if (data_in[61:0] == 62'h06000002_40228012) begin
											packet_error 	<= 1'b0;
											cycle_state 	<= CYCLE5_WAIT;
										end else begin
											packet_error 	<= 1'b1;
										end
									end
								end
								CYCLE5_WAIT: begin
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									sb_exit_m 				<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									if (module_en) begin
										if (data_in[61:0] == 62'h06000008_40214012) begin
											packet_error 	<= 1'b0;
											cycle_state 	<= CYCLE5_TX;
										end else begin
											packet_error 	<= 1'b1;
										end
									end
								end
								CYCLE5_TX: begin
									data_out_m 				<= 64'h06000008_40228012;
									encoder_en_m 				<= 1'b1;
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									cycle_state 			<= CYCLE6_TX;
								end
								CYCLE6_TX: begin
									data_out_m 				<= 64'h06000009_40214012;
									encoder_en_m 				<= 1'b1;
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									cycle_state 			<= CYCLE6_WAIT;
								end
								CYCLE6_WAIT: begin
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									sb_exit_m 				<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									if (module_en) begin
										if (data_in[61:0] == 62'h06000009_40228012) begin
											packet_error 	<= 1'b0;
											cycle_state 	<= CYCLE7_TX;
										end else begin
											packet_error 	<= 1'b1;
										end
									end
								end
								CYCLE7_TX: begin
									data_out_m 				<= 64'h06000012_402D4012;
									encoder_en_m 				<= 1'b1;
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									cycle_state 			<= CYCLE7_WAIT;
								end
								CYCLE7_WAIT: begin
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									if (module_en) begin
										if (data_in[61:0] == 62'h06000012_402E8012) begin
											packet_error 	<= 1'b0;
											sb_exit_m 		<= 1'b1;
											cycle_state 	<= CYCLE1_TX;
										end else begin
											packet_error 	<= 1'b1;
											sb_exit_m 		<= 1'b0;
										end
									end
								end
								default: begin
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
								end
							endcase
						end
						
						DATATRAINCENTER2: begin
							case (cycle_state)
								CYCLE1_TX: begin
									if (flag) begin
										data_out_m 				<= 64'h06000013_402D4012;
										encoder_en_m 				<= 1'b1;
										sb_exit_m 				<= 1'b0;
										packet_error 			<= 1'b0;
										start_mb_m 				<= 1'b0;
										trainerror_hs_m			<= 1'b0;
										cycle_state 			<= CYCLE1_WAIT;
									end
								end 
								CYCLE1_WAIT: begin 
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									sb_exit_m 				<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									if (module_en) begin
										if (data_in[61:0] == 62'h06000013_402E8012) begin
											packet_error 	<= 1'b0;
											cycle_state 	<= CYCLE2_TX;
										end else begin
											packet_error 	<= 1'b1;
										end
									end
								end
								CYCLE2_TX: begin
									// Maximum Error Threshold "Default = 0" 
									data_out_m 				<= {12'h060, 12'h000, 40'h014021401B};
									encoder_en_m 				<= 1'b1;
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									cycle_state 			<= CYCLE3_TX;
								end
								CYCLE3_TX: begin
									//////// read data from memory
									data_out_m 				<= 64'h2000000000020;
									encoder_en_m 				<= 1'b1;
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									cycle_state 			<= CYCLE3_WAIT;
								end
								CYCLE3_WAIT: begin
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									sb_exit_m 				<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									if (module_en) begin
										if (data_in[61:0] == 62'h06000001_40228012) begin
											packet_error 	<= 1'b0;
											cycle_state 	<= CYCLE4_TX;
										end else begin
											packet_error 	<= 1'b1;
										end
									end
								end
								CYCLE4_TX: begin
									data_out_m 				<= 64'h06000002_40214012;
									encoder_en_m 				<= 1'b1;
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									cycle_state 			<= CYCLE4_WAIT;
								end 
								CYCLE4_WAIT: begin
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									sb_exit_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									if (module_en) begin
										if (data_in[61:0] == 62'h06000002_40228012) begin
											start_mb_m 		<= 1'b1;
											packet_error 	<= 1'b0;
											cycle_state 	<= CYCLE5_TX;
										end else begin
											start_mb_m 		<= 1'b0;
											packet_error 	<= 1'b1;
										end
									end
								end
								CYCLE5_TX: begin
									if (end_mb) begin
										encoder_en_m 	<= 1'b1;
										data_out_m 	<= 64'h06000003_40214012;
										cycle_state <= CYCLE5_WAIT;
									end
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
								end 
								CYCLE5_WAIT: begin
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									sb_exit_m 				<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									if (module_en) begin
										if (data_in[39:0] == 40'h03_4022801B && data_in[58:56] == 'b110) begin
											if (data_in[44] == 1'b1) begin
												correct_detection <= 1'b1;
											end else begin
												correct_detection <= 1'b0;
											end
											packet_error 	<= 1'b0;
											cycle_state 	<= CYCLE6_WAIT;
										end else begin
											packet_error 	<= 1'b1;
										end
									end
								end
								CYCLE6_WAIT: begin
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									sb_exit_m 				<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									packet_error 			<= 1'b0;
									if (module_en) begin
										cycle_state <= CYCLE7_TX;
									end
								end
								CYCLE7_TX: begin 
									data_out_m 				<= 64'h06000004_40214012;
									encoder_en_m 				<= 1'b1;
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									cycle_state 			<= CYCLE7_WAIT;
								end
								CYCLE7_WAIT: begin
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									sb_exit_m 				<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									if (module_en) begin
										if (data_in[61:0] == 62'h06000004_40228012) begin
											packet_error 	<= 1'b0;
											cycle_state 	<= CYCLE8_TX;
										end else begin
											packet_error 	<= 1'b1;
										end
									end
								end
								CYCLE8_TX: begin
									encoder_en_m 				<= 1'b1;
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m 			<= 1'b0;
									cycle_state 			<= CYCLE8_WAIT;
									if (correct_detection) begin
										data_out_m <= 64'h06000014_402D4012;
									end else begin
										data_out_m <= 64'h06000000_40394012;
									end	
								end
								CYCLE8_WAIT: begin
									data_out_m 					<= 64'h00000000_00000000;
									encoder_en_m 					<= 1'b0;
									start_mb_m 					<= 1'b0;
									if (module_en) begin
										if (correct_detection) begin
											if (data_in[61:0] == 62'h06000014_402E8012) begin
												packet_error 	<= 1'b0;
												sb_exit_m 		<= 1'b1;
												cycle_state 	<= CYCLE1_TX;
											end else begin
												packet_error 	<= 1'b1;
												sb_exit_m 		<= 1'b0;
											end
											trainerror_hs_m 		<= 1'b0;
										end else begin
											packet_error 		<= 1'b0;
											sb_exit_m 			<= 1'b0;
											if (data_in[61:0] == 62'h06000000_403A8012) begin
												trainerror_hs_m 	<= 1'b1;
												cycle_state 	<= CYCLE1_TX;
											end
										end
									end
								end
								default: begin
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
								end
							endcase
						end
						
						LINKSPEED: begin
							case (cycle_state)
								CYCLE1_TX: begin
									if (flag) begin
										data_out_m 				<= 64'h06000015_402D4012;
										encoder_en_m 				<= 1'b1;
										sb_exit_m 				<= 1'b0;
										packet_error 			<= 1'b0;
										start_mb_m 				<= 1'b0;
										trainerror_hs_m			<= 1'b0;
										cycle_state 			<= CYCLE1_WAIT;
									end
								end 
								CYCLE1_WAIT: begin 
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									sb_exit_m 				<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									if (module_en) begin
										if (data_in[61:0] == 62'h06000015_402E8012) begin
											packet_error 	<= 1'b0;
											cycle_state 	<= CYCLE2_TX;
										end else begin
											packet_error 	<= 1'b1;
										end
									end
								end
								CYCLE2_TX: begin
									// Maximum Error Threshold "Default = 0" 
									data_out_m 				<= {12'h060, 12'h000, 40'h014021401B};
									encoder_en_m 				<= 1'b1;
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									cycle_state 			<= CYCLE3_TX;
								end
								CYCLE3_TX: begin
									data_out_m 				<= 64'h2000000000020;
									encoder_en_m 				<= 1'b1;
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									cycle_state 			<= CYCLE3_WAIT;
								end
								CYCLE3_WAIT: begin
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									sb_exit_m 				<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									if (module_en) begin
										if (data_in[61:0] == 62'h06000001_40228012) begin
											packet_error 	<= 1'b0;
											cycle_state 	<= CYCLE4_TX;
										end else begin
											packet_error 	<= 1'b1;
										end
									end
								end
								CYCLE4_TX: begin
									data_out_m 				<= 64'h06000002_40214012;
									encoder_en_m 				<= 1'b1;
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									cycle_state 			<= CYCLE4_WAIT;
								end 
								CYCLE4_WAIT: begin
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									sb_exit_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									if (module_en) begin
										if (data_in[61:0] == 62'h06000002_40228012) begin
											start_mb_m 		<= 1'b1;
											packet_error 	<= 1'b0;
											cycle_state 	<= CYCLE5_TX;
										end else begin
											start_mb_m 		<= 1'b0;
											packet_error 	<= 1'b1;
										end
									end
								end
								CYCLE5_TX: begin
									if (end_mb) begin
										encoder_en_m 	<= 1'b1;
										data_out_m 	<= 64'h06000003_40214012;
										cycle_state <= CYCLE5_WAIT;
									end
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
								end 
								CYCLE5_WAIT: begin
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									sb_exit_m 				<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									if (module_en) begin
										if (data_in[39:0] == 40'h03_4022801B && data_in[58:56] == 'b110) begin										
											packet_error 	<= 1'b0;
											cycle_state 	<= CYCLE6_WAIT;
										end else begin
											packet_error 	<= 1'b1;
										end
									end
								end
								CYCLE6_WAIT: begin
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									sb_exit_m 				<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									packet_error 			<= 1'b0;
									if (module_en) begin
										if (data_in[7:0] == 8'hFF && data_in[15:8] == 8'hFF ) begin
											correct_detection <= 1'b1;
										    correct_detection_cummulative<=1;
											width_degrade <= 3'b011;
										end else if (data_in[7:0] != 8'hFF&&data_in[15:8] == 8'hFF) begin
											correct_detection <= 1'b1;
								        	if (width_degrade=='b10)
											 correct_detection_cummulative<=1;
											else width_degrade <= 3'b010;
										end else if (data_in[7:0] == 8'hFF &&data_in[15:8] != 8'hFF) begin
											correct_detection <= 1'b1;
											width_degrade <= 3'b001;
											if (width_degrade=='b1)
												correct_detection_cummulative<=1;
											else 	width_degrade <= 3'b1;
										end else begin
											correct_detection <= 1'b0;
											width_degrade <= 3'b000;
										end
										cycle_state <= CYCLE7_TX;
									end
								end
								CYCLE7_TX: begin 
									data_out_m 				<= 64'h06000004_40214012;
									encoder_en_m 				<= 1'b1;
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									cycle_state 			<= CYCLE7_WAIT;
								end
								CYCLE7_WAIT: begin
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									sb_exit_m 				<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									if (module_en) begin
										if (data_in[61:0] == 62'h06000004_40228012) begin
											packet_error 	<= 1'b0;
											cycle_state 	<= CYCLE8_TX;
										end else begin
											packet_error 	<= 1'b1;
										end
									end
								end
								CYCLE8_TX: begin
									encoder_en_m 				<= 1'b1;
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m 			<= 1'b0;
									cycle_state 			<= CYCLE8_WAIT;
									if (correct_detection_cummulative ) begin
										data_out_m <= 64'h06000019_402D4012;
									end else begin
										data_out_m <= 64'h06000016_402D4012;
									end	
								end
								CYCLE8_WAIT: begin
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									start_mb_m 				<= 1'b0;
									if (module_en) begin
										if (correct_detection_cummulative ) begin
											if (data_in[61:0] == 62'h06000019_40_2E8_012) begin
												packet_error 	<= 1'b0;
												sb_exit_m 		<= 1'b1;
												cycle_state 	<= CYCLE1_TX;
											end else begin
												packet_error 	<= 1'b1;
												sb_exit_m 		<= 1'b0;
											end
											trainerror_hs_m 		<= 1'b0;
										end else begin
											packet_error 		<= 1'b0;
											sb_exit_m 			<= 1'b0;
											trainerror_hs_m 		<= 1'b0;
											if (data_in[61:0] == 62'h06000016_402E8012) begin
												if (~correct_detection) begin
													data_out_m 	<= 64'h06000018_402D4012;
													encoder_en_m 	<= 1'b1;
													speed_degrade_flag <= 1'b1;
													cycle_state <= CYCLE9_WAIT;
												end else begin
													data_out_m 	<= 64'h06000017_402D4012;
													encoder_en_m 	<= 1'b1;
													repair_flag <= 1'b1;
													cycle_state <= CYCLE9_WAIT;
												end
											end else begin
												packet_error <= 1'b1;
											end
										end
									end
								end
								CYCLE9_WAIT: begin
									data_out_m 		<= 64'h00000000_00000000;
									encoder_en_m 		<= 1'b0;
									start_mb_m 		<= 1'b0;
									trainerror_hs_m 	<= 1'b0;
									sb_exit_m 		<= 1'b0;
									speed_idle_req_m 	<= 1'b0;
									repair_req_m 		<= 1'b0;
									if (module_en) begin
										if (speed_degrade_flag) begin
											if(data_in[61:0] == 62'h06000018_402E8012) begin
												packet_error 	<= 1'b0;
												speed_idle_req_m 	<= 1'b1;
												cycle_state 			<= CYCLE1_TX;
											end else begin
												packet_error 	<= 1'b1;
												speed_idle_req_m 	<= 1'b0;
											end
										end else if (repair_flag) begin
											if(data_in[61:0] == 62'h06000017_402E8012) begin
												packet_error 	<= 1'b0;
												repair_req_m 		<= 1'b1;
												cycle_state 			<= CYCLE1_TX;
											end else begin
												packet_error 	<= 1'b1;
												repair_req_m 		<= 1'b0;
											end
										end
									end 
								end
								default: begin
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
								end
							endcase
						end
						
						REPAIR: begin
							case (cycle_state)
								CYCLE1_TX: begin
									if (flag) begin
										data_out_m 				<= 64'h0600001B_402D4012;
										encoder_en_m 				<= 1'b1;
										sb_exit_m 				<= 1'b0;
										packet_error 			<= 1'b0;
										start_mb_m 				<= 1'b0;
										correct_detection 		<= 1'b0;
										trainerror_hs_m			<= 1'b0;
										repair_req_m 				<= 1'b0;
										cycle_state 			<= CYCLE1_WAIT;
									end
								end
								CYCLE1_WAIT: begin
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									sb_exit_m 				<= 1'b0;
									start_mb_m 				<= 1'b0;
									correct_detection 		<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									if (module_en) begin
										if (data_in[61:0] == 62'h0600001B_402E8012) begin
											packet_error 	<= 1'b0;
											cycle_state 	<= CYCLE2_TX;
										end else begin
											packet_error 	<= 1'b1;
										end
									end
											
								end
								CYCLE2_TX: begin
									data_out_m 				<= {1'b0, 20'h0C000, width_degrade, 40'h1E402D4012};
									encoder_en_m 				<= 1'b1;
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									correct_detection 		<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									cycle_state 			<= CYCLE2_WAIT;
								end
								CYCLE2_WAIT: begin
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									sb_exit_m 				<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									packet_error 			<= 1'b0;
									if (module_en) begin
										if (data_in[61:0] == 62'h0600001E_402E8012) begin
											packet_error 	<= 1'b0;
											cycle_state 	<= CYCLE3_TX;
										end else begin
											packet_error 	<= 1'b1;
										end
									end
								end
								CYCLE3_TX: begin
									data_out_m 				<= 64'h0600001D_402D4012;
									encoder_en_m 				<= 1'b1;
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									cycle_state 			<= CYCLE3_WAIT;
								end
								CYCLE3_WAIT: begin
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									start_mb_m 				<= 1'b0;
									trainerror_hs_m			<= 1'b0;
									if (module_en) begin
										if (data_in[61:0] == 62'h0600001D_402E8012) begin
											packet_error 	<= 1'b0;
											sb_exit_m 		<= 1'b1;
											cycle_state 	<= CYCLE1_TX;
										end else begin
											packet_error 	<= 1'b1;
											sb_exit_m 		<= 1'b0;
										end
									end
								end
								default: begin
									data_out_m 				<= 64'h00000000_00000000;
									encoder_en_m 				<= 1'b0;
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b0;
									start_mb_m 				<= 1'b0;
									correct_detection 		<= 1'b0;
									trainerror_hs_m			<= 1'b0;
								end
							endcase
						end
					endcase
				end
				
				PHYRETRAIN: begin
					path_sel <= 1'b0;
					case (cycle_state)
						CYCLE1_TX: begin
							if (flag) begin
								path_sel 				<= 1'b0;
								sb_pattern 				<= 1'b0;
								packet_error 			<= 1'b0;
								sb_exit_m 				<= 1'b0;
								encoder_en_m 				<= 1'b1;
								retrain_encoding_ltsm 	<= 3'b001;
								data_out_m 				<= {1'b0, 20'h0C000, retrain_encoding, 40'h0140314012};
								cycle_state 			<= CYCLE1_WAIT;
							end
						end
						CYCLE1_WAIT: begin
							path_sel 		<= 1'b0;
							sb_pattern 		<= 1'b0;
							encoder_en_m 		<= 1'b0;
							data_out_m 		<= 64'h00000000_00000000;
							if (module_en) begin
								if (data_in[39:0] == 40'h0140328012 && data_in[58:43] == 16'hC000) begin
									retrain_encoding_ltsm 	<= data_in[42:40];

									sb_exit_m 				<= 1'b1;
									packet_error 			<= 1'b0;
									cycle_state 			<= CYCLE1_TX;
								end else begin
									sb_exit_m 				<= 1'b0;
									packet_error 			<= 1'b1;
								end
							end
						end
						default: begin
							path_sel 			<= 1'b0;
							sb_pattern 			<= 1'b0;
							packet_error 		<= 1'b0;
							sb_exit_m 			<= 1'b0;
							encoder_en_m 			<= 1'b0;
							data_out_m 			<= 64'h00000000_00000000;
						end
					endcase
				end
				
				TRAINERROR: begin
					path_sel <= 1'b0;
					trainerror_hs_m <= 1'b0;
					sb_pattern <= 1'b0;
					progress_stop <= 1'b1;
					if (ser_done) begin
						sb_p_done <= 1'b1;
					end
				end
				
				default: begin
					path_sel 			<= 1'b0;
					sb_pattern 			<= 1'b0;
					packet_error 		<= 1'b0;
					sb_exit_m 			<= 1'b0;
					encoder_en_m 		<= 1'b0;
					data_out_m 			<= 64'h00000000_00000000;
				end
			endcase
		end
	end
	
	


	always @(*) begin	
		if (repair_flag) begin
			retrain_encoding = 3'b100;
		end else if (speed_degrade_flag) begin
			retrain_encoding = 3'b010;
		end else begin
			retrain_encoding = 3'b001;
		end 
	end
	
	// This logic to enable decoder to handle register access requests and completions during RESET and SBINIT states 
	always @ (posedge lclk or negedge sys_rst) begin
		if (~sys_rst) begin
			decoder_mode <= 2'b10;
		end else begin
			case (cs) 
				RESET: begin
					decoder_mode <= 2'b10;
				end
				SBINIT: begin
					decoder_mode <= 2'b10;
				end
				ACTIVE: begin
					decoder_mode <= 2'b00;
				end 
				default: begin
					decoder_mode <= 2'b01;
				end
			endcase
		end
	end
	
	function integer countones;
		input [DATA_WIDTH-1:0] data;
		integer i;
		begin
			countones = 0;
			for (i = 0; i < DATA_WIDTH; i = i + 1) begin
				if (data[i]) countones = countones + 1;
			end
		end
	endfunction
	
endmodule

/* Synthesis:
	1. remove cycle_error
	2. make pl_speedmode initiated with 4'h5 not with max_speed
	3. retrain_encoding_ltsm wasn't initiated after sys_rst
*/