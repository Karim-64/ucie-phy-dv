import Universal_pkg::*;
//implementing the Side Band Controller Top module
module Controller_TOP #(parameter DATA_WIDTH_TOP = 64,
						parameter ADDR_WIDTH_TOP = 24 
)
( top_if.ctrl CTRL );
 
wire							lclk 				;
wire							sys_rst 			;
wire	[DATA_WIDTH_TOP-1:0] 	data_in				; 		// from SB_RX Decoder
wire	[2:0] 					cs 					; 		// from LTSM
wire	[2:0] 					mbinit_cs 			; 		// from LTSM
wire	[3:0] 					mbtrain_cs 			; 		// from LTSM
wire 							ltsm_timeout 		; 		// from LTSM

// inputs of Module Partner
wire 							module_partner_en	; 		// from SB_RX Decoder
wire 							end_mb 				; 		// from MB_TX
wire 							valid_frame_error 	; 		// from MB_RX
wire 							detec_succ 			; 		// from MB_RX
wire	[15:0] 					faulty_lanes		; 		// from MB_RX
wire 							comparison_done 	; 		// from MB_RX

// inputs of RDI
wire 							rdi_en 				; 		// from SB_RX Decoder
wire 							lp_stallack			; 		// from RDI 
wire 							lp_wake_req 		; 		// from RDI
wire 							clk_hs_start 		; 		// from SB_RX    
wire 							lp_clk_ack 			; 		// from RDI
wire 	[3:0] 					lp_state_req 		; 		// from RDI    
wire 							pl_error			;
wire 							lp_linkerror 		; 		// from RDI
wire 							mb_tx_done 			; 		// from MB_TX (the ANDing result of both End && Empty)
wire 							mb_rx_done 			; 		// from MB_RX


// inputs of Module
wire 							ser_done 			; 		// from SB_TX
wire 							module_en 			; 		// from SB_RX
wire 							error 				; 		// from SB_RX
wire 							pattern_detected_sync; 		// from SB_RX
wire 							sb_o_detected_sync 	; 		// from SB_RX     


// inputs of Arbiter
wire 							phy_resend_req 		; 		// signal to wait for the D2D to write its data in the Async. FIFO


// outputs of Module Partner
wire 	       					sb_exit				; 		// to LTSM
wire 	       					trainerror_hs		; 		// to LTSM
wire 	[15:0] 					error_threshold		; 		// to MB_RX   
wire 	[2:0]  					width_degrade_mp 	; 		// to MB_RX
wire 	       					width_update 		; 		// to MB_RX
wire 	       					test_resp 			; 		// to MB_RX

// outputs of RDI
wire	      					pl_stallreq			; 		// to RDI Interface         
wire	      					pl_wake_ack			; 		// to RDI Interface    
wire	      					pl_clk_req			; 		// to RDI Interface  
wire	      					pl_inband_pres		; 		// to RDI Interface         
wire	[3:0] 					pl_state_sts		; 		// to RDI Interface
wire	      					pl_phyinrecenter	; 		// to RDI Interface 
wire 							pl_trainerror		;		// to RDI Interface
wire 							pl_cerror			;		// to RDI Interface
wire 							pl_nferror 			;		// to RDI Interface
wire 							phy_retrain 		; 		// to LTSM

// outputs of Module   
wire	[1:0]               	decoder_mode		; 		// TO SBTX
wire	                    	sb_pattern			; 		// TO SBTX
wire	                    	progress_stop		; 		// TO SBTX
wire	                    	mem_wr_en			;		// TO MEMORY_CONTROLLER
wire	[DATA_WIDTH_TOP-1:0]	mem_data			;		// TO MEMORY_CONTROLLER
wire	[ADDR_WIDTH_TOP-1:0]	mem_addr			;		// TO MEMORY_CONTROLLER
wire	                    	speed_idle_req		; 		// to LTSM 
wire	                    	repair_req			; 		// to LTSM 
wire	                    	sb_p_done			; 		// TO ltsm
wire	[2:0]               	retrain_encoding_ltsm; 		// to LTSM
wire	                    	path_sel			; 		// to SBRX
wire	                    	start_mb			; 		// to MB_TX
wire	                    	lane_reverse		; 		// to MB_TX
wire	[2:0]               	width_degrade		;       // to MB_TX
wire	[2:0]               	pl_speedmode		; 		// to RDI Interface
wire	[2:0] 					pl_lnk_cfg			;

// outputs of Arbiter
wire	[DATA_WIDTH_TOP-1:0]  data_out_encoder;   // to SB_TX Encoder
wire	                      encoder_en;          // to SB_TX Encoder
wire	                      data_marker ;        // Data marker for the SB_TX Credits System

 // internal signals connections
 // OUTPUTS from Module & INPUTS to Module Partner
	wire                        sb_exit_m;    // from SB Controller "Module" block
	wire  [2:0]                 retrain_encoding;  // from SB Controller "Module" block  
	wire  [2:0]                 max_speed;         // from SB Controller "Module" block
	
	
	// OUTPUTS from Module Partner & INPUTS to Module
	wire                        trainerror_flag;   // to SB Controller "Module" block
	
	
	// OUTPUTS from Module Partner & INPUTS to Arbiter
	wire  [DATA_WIDTH_TOP-1:0]  data_out_mp;       // to SB Controller Arbiter
	wire                        encoder_en_mp;     // to SB Controller Arbiter
	
	
	// OUTPUTS from RDI & INPUTS to Arbiter
	wire  [DATA_WIDTH_TOP-1:0]  data_out_rdi;       // to SB Controller Arbiter
	wire                        encoder_en_rdi;     // to SB Controller Arbiter
	
	
	// OUTPUTS from Module & INPUTS to Arbiter
	wire  [DATA_WIDTH_TOP-1:0]  data_out_m;       // to SB Controller Arbiter
	wire                        encoder_en_m;     // to SB Controller Arbiter
	
	
	// OUTPUTS from RDI & INPUTS to Module
	wire                        rdi_packet_error;   // from RDI & to SB Controller "Module" block
	wire  error_triggers;
	
	wire  module_internal_error;
	wire  rdi_internal_error ;
	
	wire [ADDR_WIDTH_TOP-1:0] 	module_mem_addr;
	wire [DATA_WIDTH_TOP-1:0] 	module_mem_data;
	wire 						module_mem_wr_en; 
	
	wire [ADDR_WIDTH_TOP-1:0] 	rdi_mem_addr;
	wire [DATA_WIDTH_TOP-1:0]	rdi_mem_data;
	wire 						rdi_mem_wr_en;
	
	wire sb_exit_mp;
	wire sb_exit_rdi;
	wire trainerror_hs_m;
	wire trainerror_hs_mp;
	wire trainerror_hs_rdi ; 
	wire speed_idle_req_m;
	wire speed_idle_req_mp;
	wire repair_req_m;
	wire repair_req_mp;
	wire start_mb_m;
	wire start_mb_mp;
	wire test_resp_m;
	wire test_resp_mp;
	
	assign rdi_internal_error = module_internal_error | trainerror_flag | error;
	assign error_triggers = trainerror_flag || rdi_packet_error || error;
	
	assign sb_exit 			= sb_exit_mp 		| sb_exit_rdi;
	assign trainerror_hs 	= trainerror_hs_m 	| trainerror_hs_mp;
	assign speed_idle_req 	= speed_idle_req_m 	| speed_idle_req_mp;
	assign repair_req 		= repair_req_m 		| repair_req_mp;
	assign start_mb 		= start_mb_m 		| start_mb_mp;
	assign test_resp 		= test_resp_m 		| test_resp_mp;

///********************************************************//////
/////////////////// Connecting Interface  //////////////////////
///********************************************************/////
assign lclk = CTRL.lclk ; 
assign sys_rst = CTRL.RST_n ; 
assign data_in = CTRL.DATA_IN; 
assign cs = CTRL.cs ;
assign mbinit_cs = CTRL.mbinit_cs ; 
assign mbtrain_cs = CTRL.mbtrain_cs ;
assign ltsm_timeout = CTRL.ltsm_timeout ; 
assign module_partner_en = CTRL.Module_Partner_EN ; 
assign end_mb = CTRL.End_LTSM_Synch ; 
assign valid_frame_error = CTRL.valid_frame_error ; 
assign detec_succ = CTRL.detec_succ ; 
assign faulty_lanes = CTRL.faulty_lanes ; 
assign comparison_done = CTRL.Comparison_Done ; 
assign rdi_en = CTRL.RDI_EN ; 
assign lp_stallack = CTRL.lp_stallack ; 
assign lp_wake_req = CTRL.lp_wake_req ; 
assign clk_hs_start = CTRL.clk_hs_start ; 
assign lp_clk_ack = CTRL.lp_clk_ack ; 
assign lp_state_req = CTRL.lp_state_req ; 
assign pl_error = CTRL.pl_error ; 
assign lp_linkerror = CTRL.lp_linkerror ; 
assign mb_tx_done = CTRL.mb_tx_done ; 
assign mb_rx_done = CTRL.mb_rx_done ;  
assign ser_done = CTRL.ser_done ; 
assign module_en = CTRL.Module_EN ; 
assign error = CTRL.SB_Error ; 
assign pattern_detected_sync = CTRL.pattern_detected_sync ; 
assign sb_o_detected_sync = CTRL.sb_o_detected_sync ; 
assign phy_resend_req = CTRL.PHY_Resend_Req ;



assign CTRL.Error_Threshold      = error_threshold;
assign CTRL.width_degrade2     = width_degrade_mp;
assign CTRL.Width_Update         = width_update;
assign CTRL.test_resp_m            = test_resp_m;
assign CTRL.test_resp_mp            = test_resp_mp ;
assign CTRL.pl_stallreq          = pl_stallreq;
assign CTRL.pl_wake_ack          = pl_wake_ack;
assign CTRL.pl_clk_req           = pl_clk_req;
assign CTRL.pl_inband_pres       = pl_inband_pres;
assign CTRL.pl_state_sts         = RDI_states'(pl_state_sts);
assign CTRL.pl_phyinrecenter     = pl_phyinrecenter;
assign CTRL.pl_trainerror        = pl_trainerror;
assign CTRL.pl_cerror            = pl_cerror;
assign CTRL.pl_nferror           = pl_nferror;
assign CTRL.phy_retrain          = phy_retrain;
assign CTRL.decoder_mode         = decoder_mode;
assign CTRL.sb_pattern           = sb_pattern;
assign CTRL.progress_stop        = progress_stop;
assign CTRL.sb_p_done            = sb_p_done;
assign CTRL.retrain_encoding_ltsm= retrain_encoding_ltsm;
assign CTRL.path_sel             = path_sel;
assign CTRL.lane_reverse         = lane_reverse;
assign CTRL.width_degrade        = width_degrade;
assign CTRL.operating_speed      = pl_speedmode;
assign CTRL.pl_lnk_cfg           = pl_lnk_cfg;
assign CTRL.DATA_OUT_Encoder     = data_out_encoder;
assign CTRL.Encoder_En           = encoder_en;
assign CTRL.Data_Marker          = data_marker;
assign CTRL.module_internal_error= module_internal_error;
assign CTRL.rdi_internal_error   = rdi_internal_error;
assign CTRL.rdi_packet_error     = rdi_packet_error;
assign CTRL.trainerror_flag		 = trainerror_flag;
assign CTRL.DATA_OUT_M           = data_out_m;
assign CTRL.DATA_OUT_MP          = data_out_mp;
assign CTRL.DATA_OUT_RDI         = data_out_rdi;
assign CTRL.ENCODER_EN_M         = encoder_en_m;
assign CTRL.ENCODER_EN_MP        = encoder_en_mp;
assign CTRL.ENCODER_EN_RDI       = encoder_en_rdi;
assign CTRL.sb_exit_m           = sb_exit_m;
assign CTRL.sb_exit_mp           = sb_exit_mp;
assign CTRL.sb_exit_RDI         = sb_exit_rdi;
assign CTRL.trainerror_hs_m     = trainerror_hs_m;
assign CTRL.trainerror_hs_mp     = trainerror_hs_mp;
assign CTRL.trainerror_hs_rdi 	= trainerror_hs_rdi ; 
assign CTRL.speed_idle_req_m   = speed_idle_req_m;
assign CTRL.speed_idle_req_mp   = speed_idle_req_mp;
assign CTRL.repair_req_m       = repair_req_m;
assign CTRL.repair_req_mp     = repair_req_mp;
assign CTRL.max_speed          = max_speed;
assign CTRL.error              =error_triggers;
assign CTRL.module_mem_wr_en     =module_mem_wr_en;
assign CTRL.module_mem_addr      =module_mem_addr;
assign CTRL.module_mem_data      = module_mem_data;
assign CTRL.rdi_mem_addr         =rdi_mem_addr;
assign CTRL.rdi_mem_data         =rdi_mem_data;
assign CTRL.rdi_mem_wr_en       = rdi_mem_wr_en;
assign CTRL.start_mb           = start_mb_m ;
assign CTRL.Start_MB           = start_mb_mp;

 
// assign CTRL.mem_wr_en            = mem_wr_en;
// assign CTRL.mem_data             = mem_data;
// assign CTRL.mem_addr             = mem_addr;
// assign CTRL.speed_idle_req       = speed_idle_req;
// assign CTRL.repair_req           = repair_req;
// assign CTRL.sb_exit              = sb_exit;
// assign CTRL.trainerror_hs              = trainerror_hs;
// assign CTRL.repair_req              = repair_req;

///********************************************************//////
/////////////////////// RDI  ///////////////////////////////////
///********************************************************/////

rdi_interface #( .DATA_WIDTH(DATA_WIDTH_TOP), .ADDR_WIDTH(ADDR_WIDTH_TOP)) U0_rdi_interface (
	.lclk 				(lclk) 					,
	.sys_rst 			(sys_rst)				,
	.rdi_en 			(rdi_en)				,
	.data_in 			(data_in[61:0])			,
	.lp_stallack 		(lp_stallack)			,
	.lp_wake_req 		(lp_wake_req)			,
	.clk_hs_start 		(clk_hs_start)			,
	.lp_clk_ack 		(lp_clk_ack)			,
	.lp_state_req 		(lp_state_req)			,
	.pl_error 			(pl_error)				,
	.lp_linkerror 		(lp_linkerror)			,
	.cs 				(cs)					,
	.internal_error 	(rdi_internal_error)	,
	.mb_tx_done 		(mb_tx_done)			,
	.mb_rx_done 		(mb_rx_done)			,
						
						
	.trainerror_hs_rdi  (trainerror_hs_rdi)		,
	.pl_stallreq 		(pl_stallreq)			,
	.pl_wake_ack 		(pl_wake_ack)			,
	.pl_clk_req 		(pl_clk_req)			,
	.pl_inband_pres 	(pl_inband_pres)		,
	.pl_state_sts 		(pl_state_sts)			,
	.pl_phyinrecenter 	(pl_phyinrecenter)		,
	.pl_trainerror 		(pl_trainerror)			,
	.pl_cerror 			(pl_cerror)				,
	.pl_nferror 		(pl_nferror)			,
	.sb_exit_rdi 		(sb_exit_rdi)			,
	.data_out_rdi 		(data_out_rdi)			,
	.encoder_en_rdi 	(encoder_en_rdi)		,
	.phy_retrain 		(phy_retrain)			,
	.rdi_packet_error 	(rdi_packet_error)		,
	.mem_addr			(rdi_mem_addr)			,
	.mem_wr_en			(rdi_mem_wr_en)			,
	.mem_data			(rdi_mem_data)			,
	.ltsm_timeout		(ltsm_timeout)
);


///********************************************************//////
/////////////////////// Module  /////////////////////////////////
///********************************************************/////

PHY_module #( .DATA_WIDTH(DATA_WIDTH_TOP), .ADDR_WIDTH(ADDR_WIDTH_TOP)) U0_PHY_module (
	.lclk 					(lclk) 					,
	.sys_rst 				(sys_rst)				,
	.ser_done 				(ser_done)				,
	.data_in 				(data_in)				,
	.module_en 				(module_en)				,
	.error 					(error_triggers)		,
	.cs 					(cs)					,
	.mbinit_cs 				(mbinit_cs)				,
	.mbtrain_cs 			(mbtrain_cs)			,
	.pattern_detected 		(pattern_detected_sync)	,
	.sb_o_detected 			(sb_o_detected_sync)	,
	.end_mb 				(end_mb)				,
		
		
	.decoder_mode 			(decoder_mode)			,
	.data_out_m 			(data_out_m)			,
	.encoder_en_m 			(encoder_en_m)			,
	.sb_pattern 			(sb_pattern)			,
	.progress_stop 			(progress_stop)			,
	.mem_wr_en 				(module_mem_wr_en)		,
	.mem_data 				(module_mem_data)		,
	.mem_addr 				(module_mem_addr)		,
	.sb_exit_m 				(sb_exit_m)				,
	.trainerror_hs_m 		(trainerror_hs_m)		,
	.speed_idle_req_m 		(speed_idle_req_m)		,
	.repair_req_m 			(repair_req_m)			,
	.sb_p_done 				(sb_p_done)				,
	.retrain_encoding_ltsm 	(retrain_encoding_ltsm)	,
	.path_sel 				(path_sel)				,
	.start_mb_m 			(start_mb_m)			,
	.lane_reverse 			(lane_reverse)			,
	.width_degrade 			(width_degrade)			,
	.pl_speedmode 			(pl_speedmode)			,
	.pl_lnk_cfg 			(pl_lnk_cfg)			,
	.max_speed 				(max_speed)				,
	.retrain_encoding 		(retrain_encoding)		,
	.module_error 			(module_internal_error)	,
	.start_rx 				(test_resp_m)
);


///********************************************************//////
/////////////////////// Module_Partner  /////////////////////////
///********************************************************/////

Module_Partner #( .DATA_WIDTH(DATA_WIDTH_TOP)) U0_Module_Partner (
	.lclk 					(lclk)				,
	.sys_rst 				(sys_rst)			,
	.module_partner_en 		(module_partner_en)	,
	.data_in 				(data_in)			,
	.cs 					(cs)				,
	.mbinit_cs 				(mbinit_cs)			,
	.mbtrain_cs 			(mbtrain_cs)		,
	.end_mb 				(end_mb)			,
	.valid_frame_error 		(valid_frame_error)	,
	.detec_succ 			(detec_succ)		,
	.faulty_lanes 			(faulty_lanes)		,
	.comparison_done 		(comparison_done)	,
	.sb_exit_m 				(sb_exit_m)			,
	.retrain_encoding 		(retrain_encoding)	,
	.max_speed 				(max_speed)			,
	
	
	.sb_exit_mp 			(sb_exit_mp)		,
	.trainerror_hs_mp 		(trainerror_hs_mp)	,
	.trainerror_flag 		(trainerror_flag)	,
	.error_threshold 		(error_threshold)	,
	.start_mb_mp 			(start_mb_mp)		,
	.width_degrade_mp 		(width_degrade_mp)	,
	.width_update 			(width_update)		,
	.data_out_mp 			(data_out_mp)		,
	.encoder_en_mp 			(encoder_en_mp)		,
	.speed_idle_req_mp 		(speed_idle_req_mp)	,
	.repair_req_mp 			(repair_req_mp)		,
	.test_resp_mp 			(test_resp_mp)
);


///********************************************************//////
/////////////////////// Arbiter  ///////////////////////////////
///********************************************************/////

Controller_Arbiter #( .DATA_WIDTH(DATA_WIDTH_TOP)) U0_Controller_Arbiter (
	.sys_rst 				(sys_rst)			,
	.lclk 					(lclk)				,
	.phy_resend_req 		(phy_resend_req)	,
	.rdi_en 				(encoder_en_rdi)	,
	.module_en 				(encoder_en_m)		,
	.module_partner_en 		(encoder_en_mp)		,
	.rdi_data 				(data_out_rdi)		,
	.module_data 			(data_out_m)		,
	.module_partner_data 	(data_out_mp)		,
	
	.encoder_data 			(data_out_encoder)	,
	.encoder_en 			(encoder_en)		,
	.data_marker 			(data_marker)
);


endmodule