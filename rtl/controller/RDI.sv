module rdi_interface #(
	parameter DATA_WIDTH = 64,
	parameter ADDR_WIDTH = 24
)(
	// inputs and outputs related to RDI interface
	input 							lclk,
	input 							sys_rst,
			
	input 							lp_stallack,
	input 							lp_wake_req,
	input 							lp_clk_ack,
	input [3:0]						lp_state_req,
	input 							lp_linkerror,
					
	output reg 						pl_stallreq,
	output reg 						pl_wake_ack,
	output reg 						pl_clk_req,
	output reg 						pl_inband_pres,
	output reg 	[3:0]				pl_state_sts,
	output reg 						pl_phyinrecenter,
	output 							pl_trainerror,
	output 							pl_nferror,
	output 							pl_cerror,
	output reg  					trainerror_hs_rdi, 				
	input 							clk_hs_start,
					
	input 							pl_error,
	
	// inputs & outputs related to LTSM
	input [2:0] 					cs,
	input 							ltsm_timeout,
	output reg 						sb_exit_rdi,
	
	// inputs related to decoder in SBRX
	input [DATA_WIDTH-3 : 0] 		data_in,
	input 							rdi_en,
	
	// inputs & outputs related to encoder in SBTX
	output reg [DATA_WIDTH-1 : 0] 	data_out_rdi,
	output reg						encoder_en_rdi,
	
	// inputs and outputs related to controller
	input 							internal_error,
	output reg 	 					phy_retrain,
	output reg  					rdi_packet_error,
	
	// inputs related to MB
	input 							mb_tx_done,
	input 							mb_rx_done,
	
	output reg [ADDR_WIDTH-1:0] 	mem_addr,
	output reg 			 			mem_wr_en,
	output reg [DATA_WIDTH-1:0]		mem_data
);
	assign pl_trainerror = internal_error | ltsm_timeout;
	assign pl_nferror 	= 1'b0;
	assign pl_cerror 	= 1'b0;
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
	
	localparam 	Nop 		= 4'b0000, Active 		= 4'b0001,
				LinkReset 	= 4'b1001, Retrain 		= 4'b1011,
				Disable 	= 4'b1100, LinkError 	= 4'b1010;
	
	typedef enum bit { 
		CYCLE1_TX,
		CYCLE1_WAIT
	} timeout_state_e ;
	timeout_state_e timeout_state;
	
	reg internal_clk_hs_start;
	wire timeout_flag;
	
	// logic related to pl_phyinrecenter: indicate that the Physical Layer is training or retraining.
	always @(posedge lclk or negedge sys_rst) begin
		if (~sys_rst) begin
			internal_clk_hs_start 	<= 1'b0;
			pl_phyinrecenter 		<= 1'b0;
			pl_inband_pres 			<= 1'b0;
		end else begin
			if (cs == SBINIT || cs == MBINIT || cs == MBTRAIN || cs == PHYRETRAIN) begin
				if (lp_clk_ack) begin
					internal_clk_hs_start 	<= 1'b0;
					pl_phyinrecenter 		<= 1'b1;
					pl_inband_pres 		<= 1'b0;
				end else begin
					internal_clk_hs_start 	<= 1'b1;
					pl_phyinrecenter 		<= 1'b0;
					pl_inband_pres 		<= 1'b0;
				end
			end
			else if (cs == LINKINIT) begin
				if (lp_clk_ack) begin
					internal_clk_hs_start 	<= 1'b0;
					pl_inband_pres 		<= 1'b1;
					pl_phyinrecenter 	<= 1'b0;
				end else begin
					internal_clk_hs_start 	<= 1'b1;
					pl_inband_pres 		<= 1'b0;
					pl_phyinrecenter 	<= 1'b0;
				end
			end else begin
				internal_clk_hs_start 		<= 1'b0;
				pl_phyinrecenter 			<= 1'b0;
				pl_inband_pres 				<= 1'b0;
			end
		end
	end
	
	/* Timer Logic */
	// Compute required cycles for 8 & 16ms residency
	localparam 	MS_TO_CLK 	= 1_000;
	localparam integer LINKERROR_TIMEOUT_CYCLES 	= MS_TO_CLK * 16;
	localparam integer LINKERROR_TIMEOUT_CYCLES2 	= MS_TO_CLK * 8;

    reg [$clog2(LINKERROR_TIMEOUT_CYCLES)-1:0] 	linkerror_counter;
	reg [$clog2(LINKERROR_TIMEOUT_CYCLES2):0] linkerror_counter2;
	reg linkerror_timer_start;
	reg linkerror_timer_start2;
	reg timer_update;
    //___________________________________________________________________________________________________________
    always @(posedge lclk or negedge sys_rst) begin
		if (~sys_rst) begin
			linkerror_counter  <= 0;
			linkerror_counter2 <= 0;
		end else begin
			if (linkerror_timer_start) begin
				linkerror_counter <= (linkerror_counter < (LINKERROR_TIMEOUT_CYCLES-1)) ? linkerror_counter + 1 : (LINKERROR_TIMEOUT_CYCLES-1);
			end else begin
				linkerror_counter <= 0;
			end
			
			if (linkerror_timer_start2) begin
				linkerror_counter2 <= (timer_update) ? 4'b0001 : (linkerror_counter2 < (LINKERROR_TIMEOUT_CYCLES2)) ? linkerror_counter2 + 1 : (LINKERROR_TIMEOUT_CYCLES2);
			end else begin
				linkerror_counter2 <= 0;
			end
		end
	end
	
	assign timeout_flag = (linkerror_counter2 == (LINKERROR_TIMEOUT_CYCLES2-1));
	//___________________________________________________________________________________________________________
	/* Logic related to RDI interface */
	// Stall Request Handshake Logic
	typedef enum logic [1:0] {IDLE, STALL_REQ, STALL_ACK, STALL_DONE} phase_t;
    phase_t stall_phase;
	reg stall_start;
	reg stall_done;
	
    always @(posedge lclk or negedge sys_rst) begin
        if (~sys_rst) begin
            pl_stallreq <= 1'b0;
			stall_done 	<= 1'b0;
            stall_phase <= IDLE;
        end else begin
            case (stall_phase)
                IDLE: begin
					pl_stallreq <= 1'b0;
					stall_done  <= 1'b0;
					if (stall_start && ~(lp_stallack)) begin
						stall_phase <= STALL_REQ;
					end
                end

                STALL_REQ: begin
                    pl_stallreq <= 1'b1;
                    if (lp_stallack) begin
                        stall_phase <= STALL_ACK;
					end
                end
				STALL_ACK: begin
					if (~lp_stallack) begin
                        stall_done  <= 1'b1; // Handshake complete
                        stall_phase <= STALL_DONE;
                    end
					pl_stallreq <= 1'b0;
                end

                STALL_DONE: begin
                    stall_phase <= IDLE;
                end
            endcase
        end
    end
	//___________________________________________________________________________________________________________
	// Wake Request Handshake Logic (pl_wake_ack)
	reg wake_state; // State tracking for 1-cycle delay

	always @(posedge lclk or negedge sys_rst) begin
		if (~sys_rst) begin
			pl_wake_ack <= 1'b0;
			wake_state  <= 1'b0;
		end else begin
			case (wake_state)
				1'b0: begin
					if (lp_wake_req) begin 
						wake_state <= 1'b1;  // First cycle after request\
					end
				end
	
				1'b1: begin
					pl_wake_ack <= 1'b1;  // Acknowledge after 1 cycle
					if (~lp_wake_req) begin
						pl_wake_ack <= 1'b0;  // Ensure proper de-assertion
						wake_state  <= 1'b0; // Reset state
					end
				end
			endcase
		end
	end
	//___________________________________________________________________________________________________________
	// Clock Request Handshake Logic (pl_clk_req)
	reg clk_state;
	
	always @(posedge lclk or negedge sys_rst) begin
		if (~sys_rst) begin
			pl_clk_req 		<= 1'b0;
			clk_state 		<= 1'b0;
		end else begin
			case (clk_state)
				1'b0: begin
					if (internal_clk_hs_start || clk_hs_start) begin
						pl_clk_req <= 1'b1;
						clk_state <= 1'b1;
					end
				end
				1'b1: begin
					if(lp_clk_ack && (pl_state_sts != Nop)) begin
						pl_clk_req <= 1'b0;
					end

					if (~pl_clk_req && (lp_state_req == Nop && pl_state_sts == Nop)) begin
                    clk_state 		<= 1'b0;
					end	
				end
			endcase
		end
	end
	//___________________________________________________________________________________________________________
	wire packet_req, packet_resp;
	
	assign packet_req = (rdi_en && (data_in[21:14] == 8'h01)) ? 1'b1 : 1'b0 ;
	assign packet_resp = (rdi_en && (data_in[21:14] == 8'h02)) ? 1'b1 : 1'b0 ;
	
	//___________________________________________________________________________________________________________
	// RDI FSM Logic
	reg observed_reset;
	reg linkerror_cycle_state;
	reg linkreset_cycle_state;
	reg disable_cycle_state;
	reg active_cycle_state;
	reg retrain_cycle_state;
	reg active_hs;
	reg active_req;
	reg clear_en;
	reg req_en;
	reg resp_en;
	reg retrain_complete;
	reg disable_complete;
	reg linkreset_complete;
	reg linkerror_complete;
	reg waiting_for_active;
	
	reg [3:0] prev_lp_state_req;
	reg [3:0] prev_pl_state_sts;
	reg prev_active_cycle_state;

	always @(posedge lclk or negedge sys_rst) begin
		if (~sys_rst) begin
			prev_lp_state_req <= Nop;
			prev_pl_state_sts <= Nop;
			prev_active_cycle_state <= 1'b0;
		end else begin
			prev_lp_state_req <= lp_state_req;
			prev_pl_state_sts <= pl_state_sts;
			prev_active_cycle_state <= active_cycle_state;
		end
	end
	
	reg reg_pl_error;
	reg reg_mb_rx_done;
	reg reg_mb_tx_done;
	reg reg_stall_done;
	reg internal_error_reg;
	reg clear_reg_signals;
	
	// Update the input assignments to use these registers
	always @(posedge lclk or negedge sys_rst) begin
		if (~sys_rst) begin
			reg_stall_done <= 1'b0;
			reg_pl_error <= 1'b0;
			reg_mb_rx_done <= 1'b0;
			reg_mb_tx_done <= 1'b0;
			internal_error_reg <= 1'b0;
		end else begin
			if (internal_error) begin
				internal_error_reg <= 1'b1;
			end
			if (stall_done) begin
				reg_stall_done <= 1'b1;
			end
			if (pl_error) begin
				reg_pl_error <= 1'b1;
			end
			if (mb_rx_done && cs == ACTIVE) begin
				reg_mb_rx_done <= 1'b1;
			end
			if (mb_tx_done && cs == ACTIVE) begin
				reg_mb_tx_done <= 1'b1;
			end
			if (clear_reg_signals) begin
				reg_stall_done <= 1'b0;
				reg_pl_error <= 1'b0;
				reg_mb_rx_done <= 1'b0;
				reg_mb_tx_done <= 1'b0;
				internal_error_reg <= 1'b0;
			end
		end
	end
	
	reg linkerror_resp_wait;
	wire state_change = (pl_state_sts != prev_pl_state_sts);
	wire complete_stall = stall_start && (stall_done || reg_stall_done) && (mb_tx_done || reg_mb_tx_done) && (mb_rx_done || reg_mb_rx_done);
	wire complete_retrain = (retrain_complete && complete_stall);
	wire complete_disable = (disable_complete && complete_stall);
	wire complete_linkreset = (linkreset_complete && complete_stall);
	wire error = lp_linkerror || internal_error || internal_error_reg || rdi_packet_error || linkerror_complete;
	wire conflict = (((lp_state_req != prev_lp_state_req) || error) && packet_req) || (stall_done && (complete_retrain || complete_disable || complete_linkreset || (pl_error || reg_pl_error)));
	
	wire linkerror_condition 	= (error && data_in[61:0] == 62'h0600000A_40004012);
	wire disable_condition 		= (lp_state_req == Disable 		&& data_in[61:0] == 62'h0600000C_40004012);
	wire linkreset_condition 	= (lp_state_req == LinkReset 	&& data_in[61:0] == 62'h06000009_40004012);
	wire retrain_condition 		= ((lp_state_req == Retrain 	|| (pl_error || reg_pl_error))	&& data_in[61:0] == 62'h0600000B_40004012);
	wire active_condition 		= (lp_state_req == Active 		&& data_in[61:0] == 62'h06000001_40004012);
	always @(*) begin
		if (conflict) begin
			if (error || data_in[61:0] == 62'h0600000A_40004012) begin
				// Priority 1
				req_en = (error && (~linkerror_condition));
				resp_en = ((data_in[61:0] == 62'h0600000A_40004012) || linkerror_condition);
			end else if (lp_state_req == Disable || data_in[61:0] == 62'h0600000C_40004012 || complete_disable) begin
				// Priority 2 
				req_en = ((lp_state_req == Disable) && (~disable_condition));
				resp_en = ((data_in[61:0] == 62'h0600000C_40004012) || disable_condition || complete_disable);
			end else if (lp_state_req == LinkReset || data_in[61:0] == 62'h06000009_40004012 || complete_linkreset) begin
				// Priority 3
				req_en = ((lp_state_req == LinkReset) && (~linkerror_condition));
				resp_en = ((data_in[61:0] == 62'h06000009_40004012) || linkreset_condition || complete_linkreset);
			end else if (lp_state_req == Retrain || (pl_error || reg_pl_error) || data_in[61:0] == 62'h0600000B_40004012 || complete_retrain) begin
				// Priority 4
				req_en = ((lp_state_req == Retrain || (pl_error || reg_pl_error)) && (~retrain_condition));
				resp_en = ((data_in[61:0] == 62'h0600000B_40004012) || retrain_condition || complete_retrain);
			end else if (lp_state_req == Active || data_in[61:0] == 62'h06000001_40004012) begin
				// Priority 5
				req_en = ((lp_state_req == Active) && (~active_condition));
				resp_en = ((data_in[61:0] == 62'h06000001_40004012) || active_condition);
			end else begin 
			req_en = 1'b0;
			resp_en = 1'b0;
			end
		end else begin
			req_en = 1'b0;
			resp_en = 1'b0;
		end 
    end
	
	always @(posedge lclk or negedge sys_rst) begin
		if (~sys_rst) begin
			pl_state_sts 			<= Nop;
			linkreset_complete 		<= 1'b0;
			disable_complete 		<= 1'b0;
			retrain_complete 		<= 1'b0;
			observed_reset 			<= 1'b0;
			linkerror_cycle_state 	<= 1'b0;
			active_cycle_state 		<= 1'b0;
			retrain_cycle_state 	<= 1'b0;
			disable_cycle_state 	<= 1'b0;
			linkreset_cycle_state 	<= 1'b0;
			active_hs 				<= 1'b0;
			encoder_en_rdi 				<= 1'b0;
			sb_exit_rdi 				<= 1'b0;
			phy_retrain 			<= 1'b0;
			stall_start 			<= 1'b0;
			active_req 				<= 1'b0;
			clear_en 				<= 1'b0;
			linkerror_complete 		<= 1'b0;
			rdi_packet_error 		<= 1'b0;
			clear_reg_signals 		<= 1'b0;
			waiting_for_active 		<= 1'b0;
			timer_update 			<= 1'b0;
			linkerror_resp_wait 	<= 1'b0;
			mem_addr 				<= 24'h000000;
			mem_wr_en 				<= 1'b0;
			mem_data 				<= 64'h00000000_00000000;
			linkerror_timer_start 	<= 1'b0;
			linkerror_timer_start2 	<= 1'b0;
			data_out_rdi 				<= 64'h00000000_00000000;
			timeout_state 			<= CYCLE1_TX;
			trainerror_hs_rdi       <= 1'b0; 
		end else begin
			data_out_rdi <= 64'h00000000_00000000;
			encoder_en_rdi <= 1'b0;
			trainerror_hs_rdi       <= 1'b0 ;

			if (((linkerror_counter2 == (LINKERROR_TIMEOUT_CYCLES2)) || ltsm_timeout || linkerror_resp_wait)  && (pl_state_sts != LinkError)) begin
			case (timeout_state) 
				CYCLE1_TX: begin
					if (((linkerror_counter2 == (LINKERROR_TIMEOUT_CYCLES2)) || ltsm_timeout)  && (pl_state_sts != LinkError)) begin
						linkerror_resp_wait 	<= 1'b1;
						linkerror_timer_start2 <= 1'b0;
						linkerror_complete <= 1'b0;
						encoder_en_rdi <= 1'b1;
						data_out_rdi <= 64'h0600000A_40004012;
						timeout_state <= CYCLE1_WAIT;
					end
				end
				CYCLE1_WAIT: begin
					linkerror_timer_start2 <= 1'b1;
					encoder_en_rdi <= 1'b0;
					data_out_rdi <= 64'h00000000_00000000;
					if(linkerror_counter2 == (LINKERROR_TIMEOUT_CYCLES2-1)) begin
						linkerror_resp_wait <= 1'b0;
						linkerror_timer_start2 <= 1'b0;
						pl_state_sts <= LinkError;
						trainerror_hs_rdi       <= 1'b1 ;
						clear_reg_signals <= 1'b1;
						timeout_state <= CYCLE1_TX;
					end
					if (rdi_en && packet_resp) begin
						if(data_in[61:0] == 62'h0600000A_40008012) begin
							linkerror_resp_wait <= 1'b0;
							linkerror_timer_start2 <= 1'b0;
							pl_state_sts <= LinkError;
							trainerror_hs_rdi       <= 1'b1 ;
							clear_reg_signals <= 1'b1;
							timeout_state <= CYCLE1_TX;
						end
					end
				end
			endcase
		end else if ((rdi_en && packet_req && pl_state_sts != LinkError && (~conflict || resp_en)) || ((complete_retrain || complete_disable || complete_linkreset)  && (~conflict || resp_en))) begin
				if(pl_state_sts == Nop && lp_state_req == Nop) observed_reset <= 1'b1;
				if(pl_state_sts == Retrain && lp_state_req == Nop) active_req <= 1'b1;
				case (data_in[61:0]) 
					62'h06000009_40004012: begin
						retrain_complete <= 1'b0;
						disable_complete <= 1'b0;
						if (!stall_start && pl_state_sts == Active) begin
							stall_start <= 1'b1;  // Initiate stall process
							linkreset_complete <= 1'b1;
						end else if (complete_stall || pl_state_sts != Active) begin
							encoder_en_rdi <= 1'b1;
							data_out_rdi <= 64'h06000009_40008012;
							clear_en <= 1'b1;
							pl_state_sts <= LinkReset;
							linkreset_complete <= 1'b0;
						end else begin
							linkreset_complete <= 1'b1;
						end
					end
					62'h0600000A_40004012: begin
						encoder_en_rdi <= 1'b1;
						data_out_rdi <= 64'h0600000A_40008012;
						clear_en <= 1'b1;
						retrain_complete <= 1'b0;
						linkreset_complete <= 1'b0;
						disable_complete <= 1'b0;
						pl_state_sts <= LinkError;
						trainerror_hs_rdi       <= 1'b1 ;
					end
					62'h0600000B_40004012 : begin
						linkreset_complete <= 1'b0;
						disable_complete <= 1'b0;
						retrain_complete <= 1'b1;
						if (!stall_start) begin
							stall_start <= 1'b1;  // Initiate stall process
						end
					end
					62'h0600000C_40004012: begin
						retrain_complete <= 1'b0;
						linkreset_complete <= 1'b0;
						if (!stall_start && pl_state_sts == Active) begin
							stall_start <= 1'b1;  // Initiate stall process
							disable_complete <= 1'b1;
						end else if (complete_stall || pl_state_sts != Active) begin
							encoder_en_rdi <= 1'b1;
							data_out_rdi <= 64'h0600000C_40008012;
							clear_en <= 1'b1;
							disable_complete <= 1'b0;
							pl_state_sts <= Disable;
						end else begin
							disable_complete <= 1'b1;
						end 
					end
					62'h06000001_40004012: begin
						encoder_en_rdi <= 1'b1;
						data_out_rdi <= 64'h06000001_40008012;
						clear_en <= 1'b1;
						retrain_complete <= 1'b0;
						linkreset_complete <= 1'b0;
						disable_complete <= 1'b0;
						if (active_hs) begin
							pl_state_sts <= Active;
							sb_exit_rdi <= 1'b1;
							active_hs <= 1'b0;
						end else begin
							active_hs <= 1'b1;
						end
					end 
					default: begin
						if (disable_complete) begin
							clear_reg_signals <= 1'b1;
							encoder_en_rdi <= 1'b1;
							data_out_rdi <= 64'h0600000C_40008012;
							clear_en <= 1'b1;
							stall_start <= 1'b0;
							disable_complete <= 1'b0;
							pl_state_sts <= Disable;
						end else if (linkreset_complete) begin
							clear_reg_signals <= 1'b1;
							encoder_en_rdi <= 1'b1;
							data_out_rdi <= 64'h06000009_40008012;
							clear_en <= 1'b1;
							pl_state_sts <= LinkReset;
							stall_start <= 1'b0;
							linkreset_complete <= 1'b0;
						end else if (retrain_complete) begin
							clear_reg_signals <= 1'b1;
							encoder_en_rdi <= 1'b1;
							data_out_rdi <= 64'h0600000B_40008012;
							clear_en <= 1'b1;
							pl_state_sts <= Retrain;
							phy_retrain <= 1'b1;
							stall_start <= 1'b0;  // Clear stall_start after completion
							retrain_complete <= 1'b0;
						end else begin
							encoder_en_rdi <= 1'b0;
							data_out_rdi <= 64'h00000000_00000000;
							clear_en <= 1'b0;
							rdi_packet_error <= 1'b1;
						end
					end
				endcase
			end else if (~conflict || (conflict && req_en))begin
				case (pl_state_sts)
				//___________________________________________________________________________________________________________
					Nop: begin
						if (state_change) begin
							active_hs <= 1'b0;
						end 
						if (lp_state_req == Nop) begin // Reset observed for at least 1 cycle
							observed_reset <= 1'b1;
						end
						if (observed_reset || lp_linkerror || internal_error || rdi_packet_error || linkerror_complete) begin
							if (lp_linkerror || internal_error || rdi_packet_error || linkerror_complete) begin
								case (linkerror_cycle_state)
									1'b0: begin
										linkerror_timer_start2 	<= 1'b1;
										timer_update			<= 1'b1;
										encoder_en_rdi 				<= 1'b1;
										data_out_rdi 				<= 64'h0600000A_40004012;
										linkerror_complete 		<= 1'b1;
										linkerror_cycle_state 	<= 1'b1;
									end
									1'b1: begin
										encoder_en_rdi 	<= 1'b0;
										data_out_rdi 	<= 64'h00000000_00000000;
										timer_update			<= 1'b0;
										if(linkerror_counter2 == (LINKERROR_TIMEOUT_CYCLES2-1)) begin
											linkerror_timer_start2 	<= 1'b0;
											pl_state_sts 			<= LinkError;
											trainerror_hs_rdi       <= 1'b1;
											linkerror_complete 		<= 1'b0;
											linkerror_cycle_state 	<= 1'b0;
										end
										if (rdi_en && packet_resp) begin
											if(data_in[61:0] == 62'h0600000A_40008012) begin
												pl_state_sts 			<= LinkError;
												trainerror_hs_rdi       <= 1'b1;
												linkerror_complete 		<= 1'b0;
												linkerror_timer_start2 	<= 1'b0;
											end else begin
												/////////report error
												rdi_packet_error 		<= 1'b1;
											end
											linkerror_cycle_state 		<= 1'b0;
										end
									end
								endcase
							end else if(lp_state_req == Disable) begin
								case (disable_cycle_state)
									1'b0: begin
										linkerror_timer_start2 	<= 1'b1;
										encoder_en_rdi 				<= 1'b1;
										data_out_rdi 				<= 64'h0600000C_40004012;
										disable_cycle_state 	<= 1'b1;
									end
									1'b1: begin
										encoder_en_rdi 	<= 1'b0;
										data_out_rdi 	<= 64'h00000000_00000000;
										if (rdi_en && packet_resp && ~timeout_flag) begin
											if(data_in[61:0] == 62'h0600000C_40008012) begin
												pl_state_sts 			<= Disable;
												linkerror_timer_start2 	<= 1'b0;
											end else begin
												/////////report error
												rdi_packet_error 		<= 1'b1;
											end
											disable_cycle_state 		<= 1'b0;
										end
									end
								endcase
							end else if (lp_state_req == LinkReset) begin
								case (linkreset_cycle_state)
									1'b0: begin
										linkerror_timer_start2 	<= 1'b1;
										encoder_en_rdi 				<= 1'b1;
										data_out_rdi 				<= 64'h06000009_40004012;
										linkreset_cycle_state 	<= 1'b1;
									end
									1'b1: begin
										encoder_en_rdi 	<= 1'b0;
										data_out_rdi 	<= 64'h00000000_00000000;
										if (rdi_en && packet_resp && ~timeout_flag) begin
											if(data_in[61:0] == 62'h06000009_40008012) begin
												pl_state_sts 			<= LinkReset;
												linkerror_timer_start2 	<= 1'b0;
											end else begin
												/////////report error
												rdi_packet_error 		<= 1'b1;
											end
											linkreset_cycle_state 		<= 1'b0;
										end
									end
								endcase
							end else if (lp_state_req == Active && cs == LINKINIT) begin // Active requested
								case (active_cycle_state)
									1'b0: begin
										encoder_en_rdi 			<= 1'b1;
										data_out_rdi 			<= 64'h06000001_40004012;
										active_cycle_state 	<= 1'b1;
									end
									1'b1: begin
										if (~waiting_for_active && active_cycle_state != prev_active_cycle_state) begin
											encoder_en_rdi 	<= 1'b0;
											data_out_rdi 	<= 64'h00000000_00000000;
										end
										if (rdi_en && packet_resp) begin
											if(data_in[61:0] == 62'h06000001_40008012) begin 
												// rsvd[61:59]_dstid[58:56]_msginfo[55:40]_msgsubcode[39:32]_srcid[31:29]_rsvd[28:22]_msgcode[21:14]_rsvd[13:5]_opcode[4:0]
												if(active_hs) begin
													pl_state_sts 		<= Active;
													active_cycle_state 	<= 1'b0;
													active_hs 			<= 1'b0;
													sb_exit_rdi 			<= 1'b1;
													mem_addr 			<= 24'h000010;
													mem_wr_en 			<= 1'b1;
													mem_data 			<= 64'h00000000_00000000;
												end else begin
													active_hs 			<= 1'b1;
													waiting_for_active	<= 1'b1;
												end
											end else begin
												rdi_packet_error 	<= 1'b1;
												active_cycle_state 	<= 1'b0;
											end
											
										end
									end
								endcase
							end	else begin
								if (clear_en) begin
								clear_en 	<= 1'b0;
								encoder_en_rdi 	<= 1'b0;
								data_out_rdi 	<= 64'h00000000_00000000;
							end
							end
						end
					end
					//________________________________________________________________________________________________________________________________________
					Active: begin
						active_cycle_state 	<= 1'b0;
						waiting_for_active <= 1'b0;
						active_req <= 1'b0;
						sb_exit_rdi <= 1'b0;
						mem_wr_en <= 1'b0;
						if (state_change) begin
							active_hs <= 1'b0;
						end
						if (lp_linkerror || internal_error || internal_error_reg || rdi_packet_error || linkerror_complete) begin
							if(!stall_done || !reg_stall_done) stall_start <= 1'b1;
							if (stall_done || reg_stall_done) begin
								stall_start <= 1'b0;
								case (linkerror_cycle_state)
									1'b0: begin
										linkerror_timer_start2 	<= 1'b1;
										encoder_en_rdi 				<= 1'b1;
										timer_update			<= 1'b1;
										data_out_rdi 				<= 64'h0600000A_40004012;
										linkerror_complete 		<= 1'b1;
										linkerror_cycle_state 	<= 1'b1;
									end
									1'b1: begin
										encoder_en_rdi 	<= 1'b0;
										data_out_rdi 	<= 64'h00000000_00000000;
										timer_update			<= 1'b0;
										if(linkerror_counter2 == (LINKERROR_TIMEOUT_CYCLES2-1)) begin
											linkerror_timer_start2 	<= 1'b0;
											pl_state_sts 			<= LinkError;
											trainerror_hs_rdi       <= 1'b1;
											linkerror_complete 		<= 1'b0;
											linkerror_cycle_state 	<= 1'b0;
										end
										if (rdi_en && packet_resp) begin
											if(data_in[61:0] == 62'h0600000A_40008012) begin
												pl_state_sts 			<= LinkError;
												clear_reg_signals 			<= 1'b1;
												trainerror_hs_rdi       <= 1'b1;
												linkerror_complete 		<= 1'b0;
												linkerror_timer_start2 	<= 1'b0;
											end else begin
												/////////report error
												rdi_packet_error 	<= 1'b1;
											end
											linkerror_cycle_state 	<= 1'b0;
										end
									end
								endcase
							end
						end else if (lp_state_req == Disable) begin
							if(!stall_done || !reg_stall_done) stall_start <= 1'b1;
							if (stall_done || reg_stall_done) begin
								stall_start <= 1'b0;
								case (disable_cycle_state)
									1'b0: begin
										linkerror_timer_start2 	<= 1'b1;
										encoder_en_rdi 				<= 1'b1;
										data_out_rdi 				<= 64'h0600000C_40004012;
										disable_cycle_state 	<= 1'b1;
									end
									1'b1: begin
										encoder_en_rdi 	<= 1'b0;
										data_out_rdi 	<= 64'h00000000_00000000;
										if (rdi_en && packet_resp && ~timeout_flag) begin
											if(data_in[61:0] == 62'h0600000C_40008012) begin
												pl_state_sts 			<= Disable;
												linkerror_timer_start2 	<= 1'b0;
												clear_reg_signals 			<= 1'b1;
											end else begin
												/////////report error
												rdi_packet_error 		<= 1'b1;
											end
											disable_cycle_state 		<= 1'b0;
										end
									end
								endcase
							end	
						end else if (lp_state_req == LinkReset) begin
							if(!stall_done || !reg_stall_done) stall_start <= 1'b1;
							if (stall_done || reg_stall_done) begin
								stall_start <= 1'b0;
								case (linkreset_cycle_state)
									1'b0: begin
										linkerror_timer_start2 	<= 1'b1;
										encoder_en_rdi 				<= 1'b1;
										data_out_rdi 				<= 64'h06000009_40004012;
										linkreset_cycle_state 	<= 1'b1;
									end
									1'b1: begin
										encoder_en_rdi 	<= 1'b0;
										data_out_rdi 	<= 64'h00000000_00000000;
										if (rdi_en && packet_resp && ~timeout_flag) begin
											if(data_in[61:0] == 62'h06000009_40008012) begin
												pl_state_sts 			<= LinkReset;
												clear_reg_signals 			<= 1'b1;
												linkerror_timer_start2 	<= 1'b0;
											end else begin
												/////////report error
												rdi_packet_error 		<= 1'b1;
											end
											linkreset_cycle_state 		<= 1'b0;
										end
									end
								endcase
							end
						end else if(lp_state_req == Retrain || pl_error || reg_pl_error) begin
							if(!stall_done && !reg_stall_done) stall_start <= 1'b1;
							else stall_start <= 1'b0;
							if ((stall_done || reg_stall_done) && (mb_tx_done || reg_mb_tx_done) && (mb_rx_done || reg_mb_rx_done)) begin
								stall_start <= 1'b0;
								case (retrain_cycle_state)
									1'b0: begin
										encoder_en_rdi 			<= 1'b1;
										data_out_rdi 			<= 64'h0600000B_40004012;
										retrain_cycle_state <= 1'b1;
									end
									1'b1: begin
										encoder_en_rdi 	<= 1'b0;
										data_out_rdi 	<= 64'h00000000_00000000;
										if (rdi_en && packet_resp) begin
											if(data_in[61:0] == 62'h0600000B_40008012) begin
												pl_state_sts 	<= Retrain;
												clear_reg_signals <= 1'b1;	
												phy_retrain 	<= 1'b1;
											end else begin
												/////////report error
												rdi_packet_error <= 1'b1;
											end
											retrain_cycle_state <= 1'b0;
										end
									end
								endcase
							end 
						end else if (clear_en) begin
							clear_en 	<= 1'b0;
							encoder_en_rdi 	<= 1'b0;
							data_out_rdi 	<= 64'h00000000_00000000;
						end
						
					end
					//________________________________________________________________________________________________________________________________________
					Retrain: begin
						clear_reg_signals <= 1'b0;
						phy_retrain <= 1'b0;
						if (state_change) begin
							active_hs <= 1'b0;
						end
						if (lp_linkerror || internal_error || rdi_packet_error || linkerror_complete) begin
							case (linkerror_cycle_state)
								1'b0: begin
									linkerror_timer_start2 	<= 1'b1;
									encoder_en_rdi 				<= 1'b1;
									timer_update			<= 1'b1;
									data_out_rdi 				<= 64'h0600000A_40004012;
									linkerror_complete 		<= 1'b1;
									linkerror_cycle_state 	<= 1'b1;
								end
								1'b1: begin
									encoder_en_rdi 	<= 1'b0;
									data_out_rdi 	<= 64'h00000000_00000000;
									timer_update			<= 1'b0;
									if(linkerror_counter2 == (LINKERROR_TIMEOUT_CYCLES2-1)) begin
										linkerror_timer_start2 	<= 1'b0;
										pl_state_sts 			<= LinkError;
										trainerror_hs_rdi       <= 1'b1;
										linkerror_complete 		<= 1'b0;
										linkerror_cycle_state 		<= 1'b0;
									end
									if (rdi_en && packet_resp) begin
										if(data_in[61:0] == 62'h0600000A_40008012) begin
											pl_state_sts 			<= LinkError;
											trainerror_hs_rdi       <= 1'b1;
											linkerror_complete 		<= 1'b0;
											linkerror_timer_start2 	<= 1'b0;
										end else begin
											/////////report error
											rdi_packet_error 		<= 1'b1;
										end
										linkerror_cycle_state 		<= 1'b0;
									end
								end
							endcase
						end else if (lp_state_req == Disable) begin
							case (disable_cycle_state)
								1'b0: begin
									linkerror_timer_start2 	<= 1'b1;
									encoder_en_rdi 				<= 1'b1;
									data_out_rdi 				<= 64'h0600000C_40004012;
									disable_cycle_state 	<= 1'b1;
								end
								1'b1: begin
									encoder_en_rdi 	<= 1'b0;
									data_out_rdi 	<= 64'h00000000_00000000;
									if (rdi_en && packet_resp && ~timeout_flag) begin
										if(data_in[61:0] == 62'h0600000C_40008012) begin
											pl_state_sts 			<= Disable;
											linkerror_timer_start2 	<= 1'b0;
										end else begin
											/////////report error
											rdi_packet_error 		<= 1'b1;
										end
										disable_cycle_state 		<= 1'b0;
									end
								end
							endcase
						end else if (lp_state_req == LinkReset) begin
							case (linkreset_cycle_state)
								1'b0: begin
									linkerror_timer_start2 	<= 1'b1;
									encoder_en_rdi 				<= 1'b1;
									data_out_rdi 				<= 64'h06000009_40004012;
									linkreset_cycle_state 	<= 1'b1;
								end
								1'b1: begin
									encoder_en_rdi 	<= 1'b0;
									data_out_rdi 	<= 64'h00000000_00000000;
									if (rdi_en && packet_resp && ~timeout_flag) begin
										if(data_in[61:0] == 62'h06000009_40008012) begin
											pl_state_sts 			<= LinkReset;
											linkerror_timer_start2 	<= 1'b0;
										end else begin
											/////////report error
											rdi_packet_error 		<= 1'b1;
										end
										linkreset_cycle_state 		<= 1'b0;
									end
								end
							endcase
						end else if (lp_state_req == Nop) begin
							encoder_en_rdi <= 1'b0;
							data_out_rdi <= 64'h00000000_00000000;
							active_req <= 1'b1;
						end else if (lp_state_req == Active && active_req && cs == LINKINIT) begin // Active requested
							// active_req <= 1'b0;
							case (active_cycle_state)
								1'b0: begin
									encoder_en_rdi 			<= 1'b1;
									data_out_rdi 			<= 64'h06000001_40004012;
									active_cycle_state 	<= 1'b1;
								end
								1'b1: begin
									if (~waiting_for_active && active_cycle_state != prev_active_cycle_state) begin
										encoder_en_rdi 	<= 1'b0;
										data_out_rdi 	<= 64'h00000000_00000000;
									end
									if (rdi_en && packet_resp) begin
										if(data_in[61:0] == 62'h06000001_40008012) begin
											if(active_hs) begin
												active_hs 		<= 1'b0;
												sb_exit_rdi 	<= 1'b1;
												mem_addr 			<= 24'h000010;
												mem_wr_en 			<= 1'b1;
												mem_data 			<= 64'h00000000_00000000;
												pl_state_sts 	<= Active;
												active_cycle_state 	<= 1'b0;
											end else begin
												active_hs 			<= 1'b1;
												waiting_for_active	<= 1'b1;
											end
										end else begin
											/////////report error
											rdi_packet_error 	<= 1'b1;
										active_cycle_state 		<= 1'b0;
										end
									end
								end
							endcase
						end else if (clear_en) begin
							clear_en <= 1'b0;
							encoder_en_rdi <= 1'b0;
							data_out_rdi <= 64'h00000000_00000000;
						end
					end
					//___________________________________________________________________________________________________________
					LinkReset: begin
						clear_reg_signals <= 1'b0;
						active_cycle_state 	<= 1'b0;
						if (state_change) begin
							active_hs <= 1'b0;
						end
						if (lp_linkerror || internal_error || rdi_packet_error || linkerror_complete) begin
							case (linkerror_cycle_state)
								1'b0: begin
									linkerror_timer_start2 	<= 1'b1;
									encoder_en_rdi 				<= 1'b1;
									timer_update			<= 1'b1;
									data_out_rdi 				<= 64'h0600000A_40004012;
									linkerror_complete 		<= 1'b1;
									linkerror_cycle_state 	<= 1'b1;
								end
								1'b1: begin
									encoder_en_rdi 	<= 1'b0;
									data_out_rdi 	<= 64'h00000000_00000000;
										timer_update			<= 1'b0;
									if(linkerror_counter2 == (LINKERROR_TIMEOUT_CYCLES2-1)) begin
										linkerror_timer_start2 	<= 1'b0;
										pl_state_sts 			<= LinkError;
										trainerror_hs_rdi       <= 1'b1;
										linkerror_complete 		<= 1'b0;
										linkerror_cycle_state 	<= 1'b0;
									end
									if (rdi_en && packet_resp) begin
										if(data_in[61:0] == 62'h0600000A_40008012) begin
											pl_state_sts 			<= LinkError;
											trainerror_hs_rdi       <= 1'b1;
											linkerror_complete 		<= 1'b0;
											linkerror_timer_start2 	<= 1'b0;
										end else begin
											/////////report error
											rdi_packet_error 		<= 1'b1;
										end
										linkerror_cycle_state 		<= 1'b0;
									end
								end
							endcase
						end else if (lp_state_req == Disable) begin
							case (disable_cycle_state)
								1'b0: begin
									linkerror_timer_start2 	<= 1'b1;
									encoder_en_rdi 				<= 1'b1;
									data_out_rdi 				<= 64'h0600000C_40004012;
									disable_cycle_state 	<= 1'b1;
								end
								1'b1: begin
									encoder_en_rdi 	<= 1'b0;
									data_out_rdi 	<= 64'h00000000_00000000;
									if (rdi_en && packet_resp && ~timeout_flag) begin
										if(data_in[61:0] == 62'h0600000C_40008012) begin
											pl_state_sts 			<= Disable;
											linkerror_timer_start2 	<= 1'b0;
										end else begin
											/////////report error
											rdi_packet_error 		<= 1'b1;
										end
										disable_cycle_state 		<= 1'b0;
									end
								end
							endcase
						end else if (lp_state_req == Active) begin
							encoder_en_rdi 		<= 1'b0;
							data_out_rdi 		<= 64'h00000000_00000000;
							pl_state_sts 	<= Nop;
						end else if (clear_en) begin
							clear_en 	<= 1'b0;
							encoder_en_rdi 	<= 1'b0;
							data_out_rdi 	<= 64'h00000000_00000000;
						end
					end
					//________________________________________________________________________________________________________________________________________
					Disable: begin
						clear_reg_signals <= 1'b0;
						active_cycle_state 	<= 1'b0;
						if (state_change) begin
							active_hs <= 1'b0;
						end
						if (lp_linkerror || internal_error || rdi_packet_error || linkerror_complete) begin
							case (linkerror_cycle_state)
								1'b0: begin
									linkerror_timer_start2 	<= 1'b1;
									encoder_en_rdi 				<= 1'b1;
									timer_update			<= 1'b1;
									data_out_rdi 				<= 64'h0600000A_40004012;
									linkerror_complete 		<= 1'b1;
									linkerror_cycle_state 	<= 1'b1;
								end
								1'b1: begin
									encoder_en_rdi 	<= 1'b0;
									data_out_rdi 	<= 64'h00000000_00000000;
										timer_update			<= 1'b0;
									if(linkerror_counter2 == (LINKERROR_TIMEOUT_CYCLES2-1)) begin
										linkerror_timer_start2 	<= 1'b0;
										pl_state_sts 			<= LinkError;
										trainerror_hs_rdi       <= 1'b1;
										linkerror_complete 		<= 1'b0;
										linkerror_cycle_state 	<= 1'b0;
									end
									if (rdi_en && packet_resp) begin
										if(data_in[61:0] == 62'h0600000A_40008012) begin
											pl_state_sts 			<= LinkError;
											trainerror_hs_rdi       <= 1'b1;
											linkerror_complete 		<= 1'b0;
											linkerror_timer_start2 	<= 1'b0;
										end else begin
											/////////report error
											rdi_packet_error 		<= 1'b1;
										end
										linkerror_cycle_state 			<= 1'b0;
									end
								end
							endcase
						end else if (lp_state_req == Active) begin
							encoder_en_rdi 	<= 1'b0;
							data_out_rdi 	<= 64'h00000000_00000000;
							pl_state_sts 	<= Nop;
						end else if (clear_en) begin
							clear_en 	<= 1'b0;
							encoder_en_rdi 	<= 1'b0;
							data_out_rdi 	<= 64'h00000000_00000000;
						end
					end
					//___________________________________________________________________________________________________________
					LinkError: begin
						active_cycle_state 	<= 1'b0;
						clear_reg_signals <= 1'b0;
						linkerror_cycle_state <= 1'b0;
						disable_cycle_state <= 1'b0;
						linkreset_cycle_state <=1'b0;
						retrain_cycle_state <= 1'b0;
						linkerror_timer_start2 <= 0;
						if (state_change) begin
							active_hs <= 1'b0;
						end
						// if (clear_en) begin
						// 	clear_en 	<= 1'b0;
							encoder_en_rdi 	<= 1'b0;
							data_out_rdi 	<= 64'h00000000_00000000;
						// end
						linkerror_timer_start 	<= 1'b1;
						rdi_packet_error 		<= 1'b0;
						if (lp_state_req == Active && ~lp_linkerror && ~internal_error && (linkerror_counter == LINKERROR_TIMEOUT_CYCLES-1)) begin
							linkerror_timer_start 	<= 1'b0;
							pl_state_sts 			<= Nop;
						end
					end
				endcase
			end else begin 
				data_out_rdi 		<= 64'h00000000_00000000;
				encoder_en_rdi 		<= 1'b0;
			end
		end 
	end

endmodule 