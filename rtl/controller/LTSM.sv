import Universal_pkg ::*; 

module LTSM (top_if.ltsm vif);

		logic 		lclk				;
		logic 		sys_rst				;
  
	// RDI Interface
		logic [3:0] lp_state_req		;
		logic 		lp_stallack			;		//signal from the RDI interface, when asserted, pl_trdy should be de-asserted 
  
	// Controller 
	 	logic 		sb_p_done			;
	 	logic 		sb_exit				;
	 	logic 		trainerror_hs		;
		logic 		repair_req			; 		//signal for the LINKSPEED state to indicate if it needs to transition to REPAIR or not
	 	logic 		speedidle_req		; 		//signal for the LINKSPEED state to indicate if it needs to transition to SPEEDIDLE or not
	 	logic [2:0] retrain_encoding	; 		//signal for retrain exit encoding 
	 	logic 		retrain_hs 			; 		//trigger signal after completing the Stallreq/Ack Mechanism and finishing the required handshake
	   	LTSM_state	cs 					;
	   	MBINIT_states	mbinit_cs			;
	   	MBTRAIN_states	mbtrain_cs			;
	   	logic 		ltsm_timeout		;
  
	// Memory Controller 
	   logic 		sw_exit				;
  
	// MB
	   logic 		full				; 		//FULL signal from the MB_TX fifo indicating that 
	   logic [4:0]	mb_op				;
	   logic 		pl_trdy				; 		//   signal to the RDI interface and to the MB_TX when the LTSM is in ACTIVE state and ready to send data
  
	   logic 		phy_in_retrain		; 		//   flag is set when entry to PHYRETRAIN
  
	// SB
	   logic 		active_flag         ;
       
    assign lclk             = vif.lclk;
    assign sys_rst          = vif.RST_n;
    assign lp_state_req     = vif.lp_state_req;
    assign sw_exit          = vif.sw_exit;
    assign sb_exit          = vif.SB_EXIT;
    assign sb_p_done        = vif.sb_p_done;
    assign trainerror_hs    = vif.TRAINERROR_HS;
    assign vif.ltsm_timeout = ltsm_timeout     ;
    
    assign vif.cs           = cs;
    assign vif.mbinit_cs    = mbinit_cs;
    assign vif.mbtrain_cs   = mbtrain_cs;
    assign vif.mb_op        = LTSM_states'(mb_op);

    assign repair_req         = vif.REPAIR_REQ;
    assign speedidle_req     = vif.SPEEDIDLE_REQ;
    assign full               = vif.FULL;
    assign retrain_encoding   = vif.Retrain_Encoding;
    assign retrain_hs         = vif.Retrain_hs;
    assign lp_stallack        = vif.lp_stallack;

    assign vif.pl_trdy        = pl_trdy;
    assign vif.PHY_IN_RETRAIN = phy_in_retrain;

    assign vif.active_flag     = active_flag;

	wire [3:0] rdi_state_req_tr;
	bit  [3:0] rdi_state_req_cs;
   
	reg  adapter_exit;
	wire sb_exit_reg;
	reg  sb_exit_reg_ff, stall_ack_reg;
	
	reg  [15:0] timer_state;

	LTSM_state ns;
	MBINIT_states mbinit_ns;
	MBTRAIN_states mbtrain_ns;

	assign ltsm_timeout = (timer_state == (8 * MS_TO_CLK - 1));

	// Register the value of sb_exit in case of RESET State
	always @(posedge lclk or negedge sys_rst) begin
		if (~sys_rst) begin
			sb_exit_reg_ff <= 1'b0;
		end else if (cs == RESET) begin
			sb_exit_reg_ff <= sb_exit_reg_ff | sb_exit;
        end else begin
			sb_exit_reg_ff <= 1'b0; 
		end

        if(~sys_rst) begin
            stall_ack_reg <= 1'b0;
        end
        else begin 
            if(cs == ACTIVE && lp_stallack) 
            stall_ack_reg <= 1'b1;
            else if(cs!= ACTIVE) begin 
                stall_ack_reg <= 1'b0;
            end
        end
	end
	
	assign sb_exit_reg = sb_exit_reg_ff;
 
    // Current State Logic
    always @(posedge lclk or negedge sys_rst) begin
        if (~sys_rst) begin
			cs 				<= RESET;
			mbinit_cs 		<= PARAM;
			mbtrain_cs 		<= VALVREF;
			pl_trdy 		<= 1'b0;
			phy_in_retrain 	<= 1'b0;
			active_flag 	<= 1'b0;
        end else begin    
			cs 				<= ns;
			mbinit_cs 		<= mbinit_ns;
			mbtrain_cs 		<= mbtrain_ns;
			
            if(ns == ACTIVE) begin
				active_flag <= 1'b1;
				if(lp_stallack || stall_ack_reg) begin
					pl_trdy <= 1'b0;
				end else if (~full) begin
					pl_trdy <= 1'b1;
				end else begin
					pl_trdy <= 1'b0;
				end
			end else begin
				pl_trdy 	<= 1'b0;
				active_flag <= 1'b0;
			end
			
			if (ns == PHYRETRAIN) begin
				phy_in_retrain <= 1'b1;
			end else if (ns == LINKINIT) begin
				phy_in_retrain <= 1'b0;  
			end else begin
				phy_in_retrain <= 1'b0;  
			end

        end
    end

    // Next State Logic
    always @(*) begin
        case (cs)
            RESET: begin
	        /*sb_exit_reg*/
                if ((timer_state == (4 * MS_TO_CLK_RST - 1)) && (sw_exit || adapter_exit || sb_exit || sb_exit_reg)) begin
                    ns = SBINIT;
                end else begin
                    ns = RESET;
                end
            end

            SBINIT: begin
                if ((timer_state == (8 * MS_TO_CLK - 1))) begin
                    ns = TRAINERROR;   
                end else if(sb_exit) begin
                    ns = MBINIT;
                end else begin
                    ns = SBINIT;
                end
            end

            MBINIT: begin
                if ((timer_state == (8 * MS_TO_CLK - 1)) || trainerror_hs)begin
                    ns = TRAINERROR;
                end else if ((mbinit_cs == REPAIRMB) && sb_exit) begin
                    ns = MBTRAIN;
                end else begin
                    ns = MBINIT;
                end
            end

            MBTRAIN: begin
                if ((timer_state == (8 * MS_TO_CLK - 1)) || trainerror_hs) begin
                    ns = TRAINERROR;
                end else if ((mbtrain_cs == LINKSPEED) && sb_exit) begin
                    ns = LINKINIT;
                end else begin
                    ns = MBTRAIN;
                end
            end

            LINKINIT: begin
                if ((timer_state == (8 * MS_TO_CLK - 1)) || trainerror_hs) begin
					ns = TRAINERROR;
                end else if (sb_exit) begin
                    ns = ACTIVE;
                end else begin
                    ns = LINKINIT;
                end
            end

            ACTIVE: begin
                if (trainerror_hs) begin
                    ns = TRAINERROR; 
                end else if(retrain_hs) begin
                    ns = PHYRETRAIN;
                end else begin
                    ns = ACTIVE;
                end
            end
			
			PHYRETRAIN: begin
                if ((timer_state == (8 * MS_TO_CLK - 1)) || trainerror_hs) begin
                    ns = TRAINERROR;
                end else if ( (retrain_encoding == 3'b010) && sb_exit) begin 
                    ns = MBTRAIN;
                end else if ( (retrain_encoding == 3'b100) && sb_exit) begin
                    ns = MBTRAIN;
                end else if ( (retrain_encoding == 3'b001) && sb_exit) begin
                    ns = MBTRAIN;
                end else begin
                    ns = PHYRETRAIN;
                end
            end

            TRAINERROR: begin
                if(sb_p_done) begin
                    ns = RESET;
                end else begin
                    ns = TRAINERROR;
                end
            end

            default: begin
                ns = RESET;
            end
        endcase
    end

    // MBINIT State Logic
    always @(*) begin
        if (cs == MBINIT) begin
            case (mbinit_cs)
                PARAM: begin
                    if (sb_exit) begin
                        mbinit_ns = CAL;
                    end else begin
                        mbinit_ns = PARAM;
                    end
                end

                CAL: begin
                    if (sb_exit) begin
                        mbinit_ns = REPAIRCLK;
                    end else begin
                        mbinit_ns = CAL;
                    end
                end

                REPAIRCLK: begin
                    if(sb_exit) begin
                        mbinit_ns = REPAIRVAL;
                    end else begin
                        mbinit_ns = REPAIRCLK;
                    end
                end

                REPAIRVAL: begin
                    if(sb_exit) begin
                        mbinit_ns = REVERSALMB;
                    end else begin
                        mbinit_ns = REPAIRVAL;
                    end
                end

                REVERSALMB: begin
                    if(sb_exit) begin
                        mbinit_ns = REPAIRMB;
                    end else begin
                        mbinit_ns = REVERSALMB;
                    end
                end

                REPAIRMB: begin
                    if(sb_exit) begin
                        mbinit_ns = PARAM;     
                    end else begin
                        mbinit_ns = REPAIRMB;
                    end
                end

                default: begin
                    mbinit_ns = PARAM;
                end
            endcase
        end else begin
            mbinit_ns = PARAM;
        end
    end
	
	// MBTRAIN State Logic
    always @(*) begin
        if (cs == MBTRAIN) begin
            case (mbtrain_cs)
				VALVREF: begin
					if (sb_exit) begin
						mbtrain_ns = DATAVREF;
                    end else begin
                        mbtrain_ns = VALVREF;
					end
                end

                DATAVREF: begin
                    if (sb_exit) begin
                        mbtrain_ns = SPEEDIDLE;
                    end else begin
                        mbtrain_ns = DATAVREF;
					end
                end

               SPEEDIDLE: begin
                    if (sb_exit) begin
                        mbtrain_ns = TXSELFCAL;
                    end else begin
                        mbtrain_ns = SPEEDIDLE;
					end
                end

                TXSELFCAL: begin
                    if (sb_exit) begin
                        mbtrain_ns = RXCLKCAL;
                    end else begin
                        mbtrain_ns = TXSELFCAL;
					end
                end

                RXCLKCAL: begin
                    if (sb_exit) begin
                        mbtrain_ns = VALTRAINCENTER;
                    end else begin
                        mbtrain_ns = RXCLKCAL;
					end
                end

                VALTRAINCENTER: begin
                    if (sb_exit) begin
                        mbtrain_ns = VALTRAINVREF;     
                    end else begin
                        mbtrain_ns = VALTRAINCENTER;
					end
                end

                VALTRAINVREF: begin
                    if (sb_exit) begin
                        mbtrain_ns = DATATRAINCENTER1;
                    end else begin
                        mbtrain_ns = VALTRAINVREF;
					end
                end

                DATATRAINCENTER1: begin
                    if (sb_exit) begin
                        mbtrain_ns = DATATRAINVREF;
                    end else begin
                        mbtrain_ns = DATATRAINCENTER1;
					end
                end

                DATATRAINVREF: begin
                    if (sb_exit) begin
                        mbtrain_ns = RXDESKEW;
                    end else begin
                        mbtrain_ns = DATATRAINVREF;
					end
                end

                RXDESKEW: begin
                    if (sb_exit) begin
                        mbtrain_ns = DATATRAINCENTER2;
                    end else begin
                        mbtrain_ns = RXDESKEW;
					end 
                end

                DATATRAINCENTER2: begin
                    if (sb_exit) begin
                        mbtrain_ns = LINKSPEED;
                    end else begin
                        mbtrain_ns = DATATRAINCENTER2;
					end
                end

				LINKSPEED: begin
                    if (speedidle_req) begin
                        mbtrain_ns = SPEEDIDLE;
                    end else if (repair_req) begin
                        mbtrain_ns = REPAIR;
                    end else if (sb_exit) begin
                        mbtrain_ns = VALVREF;
                    end else begin
                        mbtrain_ns = LINKSPEED;
					end 
                end

				REPAIR: begin
                    if (sb_exit) begin
                        mbtrain_ns = TXSELFCAL;
                    end else begin
                        mbtrain_ns = REPAIR;
					end 
                end
				
                default: begin
                    mbtrain_ns = VALVREF;
                end

            endcase

        end else if (cs == PHYRETRAIN) begin
            if ( (retrain_encoding == 3'b010) && sb_exit) begin 
				mbtrain_ns = SPEEDIDLE;
            end else if ((retrain_encoding == 3'b100) && sb_exit) begin
                mbtrain_ns = REPAIR;
            end else if ((retrain_encoding == 3'b001) && sb_exit) begin
                mbtrain_ns = TXSELFCAL;
            end else begin
                mbtrain_ns = VALVREF;
            end
        end else begin
			mbtrain_ns = VALVREF;
		end 
    end
	
	// Timer Logic  
	always @(posedge lclk or negedge sys_rst) begin
		if (~sys_rst) begin
			timer_state <= 0;
		end else if (cs != ns || mbinit_cs != mbinit_ns || mbtrain_cs != mbtrain_ns) begin 	// Reset timer on any FSM state change
			timer_state <= 0; 
		end else if (ns == TRAINERROR || ns == ACTIVE) begin 												// Hold timer in TRAINERROR state (FSM_0)
			timer_state <= 0; 
		end else if (ns == RESET) begin 													// Limit count to 3 milliseconds in RESET state
			if (timer_state < 3 * MS_TO_CLK_RST) begin
				timer_state <= timer_state + 1;
			end
		end else begin 																		// Increment normally in all other states
			timer_state <= timer_state + 1;
		end
	end
    
    // RDI State Request Logic
    genvar k;
    generate
        for (k = 0; k < 4; k = k + 1) begin
            always @(posedge lclk) begin
                 if ((rdi_state_req_cs[k] == 0) && lp_state_req[k]) begin
                    rdi_state_req_cs[k] <= 1;
                end else if ((rdi_state_req_cs[k] == 1) && (~lp_state_req[k])) begin
                    rdi_state_req_cs[k] <= 0;
                end 
            end
            assign rdi_state_req_tr[k] = (cs != RESET ) ? 1'b0 : (((rdi_state_req_cs[k] == 1'b0) && lp_state_req[k]) || ((rdi_state_req_cs[k] == 1'b1) && !lp_state_req[k]));
        end
    endgenerate
	
	always @(posedge lclk or negedge sys_rst) begin
		if (~sys_rst) begin
			adapter_exit <= 1'b0;
		end else if (cs == RESET) begin
			adapter_exit <= adapter_exit | ((rdi_state_req_tr == 4'b0001) && (lp_state_req == 4'b0001));
		end else begin
            adapter_exit <= 1'b0;
        end
	end

    // Mainband Opcode Logic
    always @(*) begin
		case (cs)
			RESET: 	mb_op = 0;
			SBINIT: mb_op = 1;
			MBINIT: begin
				case (mbinit_cs)
					PARAM: 		mb_op = 2;
					CAL: 		mb_op = 3;
					REPAIRCLK: 	mb_op = 4;
					REPAIRVAL: 	mb_op = 5;
					REVERSALMB: mb_op = 6;
					REPAIRMB: 	mb_op = 7;
					default: 	mb_op = 0;
				endcase
			end
			MBTRAIN: begin
				case (mbtrain_cs)
					VALVREF:          mb_op = 8;
					DATAVREF:         mb_op = 9;
					SPEEDIDLE:        mb_op = 10;
					TXSELFCAL:        mb_op = 11;
					RXCLKCAL:         mb_op = 12;
					VALTRAINCENTER:   mb_op = 13;
					VALTRAINVREF:     mb_op = 14;
					DATATRAINCENTER1: mb_op = 15;
					DATATRAINVREF:    mb_op = 16;
					RXDESKEW:         mb_op = 17;
					DATATRAINCENTER2: mb_op = 18;
					LINKSPEED:        mb_op = 19;
					REPAIR:           mb_op = 20;
					default:          mb_op = 0;
				endcase
			end
			LINKINIT: 	mb_op = 21;
			ACTIVE: 	mb_op = 22;
			PHYRETRAIN: mb_op = 23;
			TRAINERROR: mb_op = 24;
			default: 	mb_op = 0;
		endcase
    end

endmodule