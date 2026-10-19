module SB_RX_TOP #(
	parameter DATA_WIDTH 		= 64,
	parameter FIFO_DEPTH 		= 32,
	parameter CHUNK_WIDTH 		= 32,
	parameter DESTINATION_SEL 	= 2
)(top_if.sbrx SR_IF);
	logic 							lclk 					;
	logic  							sb_clk 					;
	logic  							sys_rst 				;
	logic  							sb_sys_rst 				;
	
	// UCIE Interface
	logic  							RXCKSB 					;
	logic 							RXDATASB 				;
	
	// SB_TX
	logic 							completion_sel 			;
	logic 		[DATA_WIDTH:0] 		tx_completion_data_in 	;
	
	// LTSM
	logic  							active_flag ;			
	
	// Controller 
	logic  							path_sel 	;			
	
	// Pattern Detector to Controller 
	 logic 						pattern_detected 		;
	 logic 						pattern_detected_sync 	;
	 logic  					sb_o_detected_sync ;
	
	// Decoder to controller
	 logic 						module_en 				;
	 logic 						module_partner_en 		;
	 logic  				    rdi_en 					;
     logic  				    decoder_error 			;
	 logic [DATA_WIDTH:0] 		controller_data_in 		;
	
	
	// RDI Interface
	logic 					    lp_clk_ack 				;
	logic 					    lp_cfg_crd 				;
	logic [CHUNK_WIDTH-1:0] 	pl_cfg 					;
	logic  						pl_cfg_vld 				;
	// RDI Module
	logic  						clk_hs_start;

	// signals related to Deserializer
	wire [DATA_WIDTH-1:0] 		deser_data_out;
	wire 						data_valid;
	
	// signals related to Demux1x2
	wire 						path_sel_sync;
	wire [DATA_WIDTH-1:0] 		async_fifo_data_in;
	wire [DATA_WIDTH-1:0] 		pattern_data_in;
	
	// signal related to Pattern detector
	wire 						sb_o_detected;
	
	// signals related to Async fifo
	wire [DATA_WIDTH-1:0] 		async_fifo_data_out;
	wire 						async_fifo_full;
	wire 						async_fifo_empty;
	
	// signals related to Decoder 
	wire 						decoder_rd_en;
	wire [DATA_WIDTH:0] 		decoder_data_out;
	wire [DESTINATION_SEL-1:0]  dest_sel;
	
	// signals related to demux1x4
	wire [DATA_WIDTH:0] 		request_data_in; 
	wire [DATA_WIDTH:0] 		sync_fifo_data_in; 
	wire [DATA_WIDTH:0] 		completion_data_in;
	
	// signals related to mux2x1
	wire [DATA_WIDTH:0] 		completion;
	
	// signals related to completion packet buffer
	wire [DATA_WIDTH:0] 		completion_data_out;
	wire 						completion_buffer_full;
	wire 						completion_buffer_empty;
	
	// signals related to request packet buffer
	wire [DATA_WIDTH:0] 		request_data_out;
	wire 						request_buffer_full; 
	wire 						request_buffer_empty;
	
	// signals related to sync fifo
	wire [DATA_WIDTH:0] 		sync_fifo_data_out;
	wire 						sync_fifo_full; 
	wire 						sync_fifo_empty;
	
	// signals related to up_down_counter
	wire 						credit_decr;
	wire [4:0] 					credits;
	wire                        Pattern_Done;
	
	wire request_rd_en , completion_rd_en , sync_rd_en ; 
	
	assign avail_credit = (|credits);

    assign lclk =SR_IF.lclk;
    assign sys_rst= SR_IF.RST_n;
    assign sb_sys_rst=SR_IF.RST_n;
	assign sb_clk= SR_IF.sb_clk;

	assign RXCKSB= SR_IF.RXCKSB;
	assign RXDATASB=SR_IF.RXDATASB;
	assign path_sel=SR_IF.path_sel ; 
    assign tx_completion_data_in=SR_IF.tx_completion_data_in;
    assign completion_sel=SR_IF.completion_sel;
    assign active_flag =SR_IF.active_flag;
    assign lp_clk_ack=SR_IF.lp_clk_ack;
	assign lp_cfg_crd= SR_IF.lp_cfg_crd;
    assign Pattern_Done = SR_IF.pattern_done ;

    assign SR_IF.clk_hs_start=clk_hs_start;
	assign SR_IF.sb_error=decoder_error; //
	assign SR_IF.Module_EN=module_en; //
    assign SR_IF.Module_Partner_EN=module_partner_en; //
	assign SR_IF.RDI_EN = rdi_en; // 
	assign SR_IF.DATA_IN = controller_data_in; //
	assign SR_IF.pl_cfg=pl_cfg;
	assign SR_IF.pl_cfg_vld=pl_cfg_vld;
	assign SR_IF.sb_o_detected_sync=sb_o_detected_sync;
    assign SR_IF.pattern_detected=pattern_detected;
    assign SR_IF.pattern_detected_sync=pattern_detected_sync;
    assign SR_IF.credit_decr = credit_decr ; 
    assign SR_IF.avail_credit = avail_credit ; 

	assign SR_IF.decision_done = request_rd_en || completion_rd_en || sync_rd_en ;
	  
	reg sb_o_detected_delay;

	always@(posedge sb_clk or negedge sb_sys_rst) begin 

	    if(~sb_sys_rst)
	      sb_o_detected_delay <= 'b0;

	    else begin 

	    if(Pattern_Done)
	    	sb_o_detected_delay <= 1'b1;
	    end

    end 
	
	Deserializer_SBRX #(.DATA_WIDTH(DATA_WIDTH)) Deserializer_U0(
		.sb_clk				(sb_clk)						, 		
		.sb_sys_rst			(sb_sys_rst)					, 	
		.RXCKSB				(RXCKSB)						,	 		
		.RXDATASB			(RXDATASB)						, 		
		.deser_data_out		(deser_data_out)				, 
		.data_valid			(data_valid)
	);
	
	Demux1x2 #(.DATA_WIDTH(DATA_WIDTH)) Demux1x2(
		.data_in			(deser_data_out)				,
		.sel				(path_sel_sync)					,
		.out0				(async_fifo_data_in)			,
		.out1				(pattern_data_in)
	);
	
	Pattern_detector_SBRX #(.DATA_WIDTH(DATA_WIDTH)) Pattern_detector_U0(
		.sb_clk				(sb_clk)						,
		.sb_sys_rst			(sb_sys_rst)					,
		.pattern_data_in	(pattern_data_in)				,
		.data_valid			(data_valid && path_sel_sync)	,
		.pattern_detected	(pattern_detected)				,
		.sb_o_detected 		(sb_o_detected) 	
	);
	
	Asynch_fifo_SBRX #(.DATA_WIDTH(DATA_WIDTH)) Async_fifo_U0(
		.sb_clk				(sb_clk)						,   
		.lclk				(lclk)							, 	
		.sb_sys_rst			(sb_sys_rst)					, 	
		.sys_rst			(sys_rst)						, 	
		.async_fifo_wr_en	(data_valid && ~path_sel_sync)	, 	
		.async_fifo_data_in	(async_fifo_data_in)			, 	
		.async_fifo_rd_en	(decoder_rd_en)					, 	
		.async_fifo_data_out(async_fifo_data_out)			, 	
		.async_fifo_full	(async_fifo_full)				, 	
		.async_fifo_empty 	(async_fifo_empty) 				
	);
	
	Decoder_SBRX #(.DATA_WIDTH(DATA_WIDTH), .DESTINATION_SEL(DESTINATION_SEL)) Decoder_U0(
		.lclk				(lclk)							,
	    .sys_rst			(sys_rst)						,
	    .async_fifo_empty	(async_fifo_empty)				,
	    .completion_sel		(completion_sel)				,
	    .decoder_data_in	(async_fifo_data_out)			,
	    .decoder_data_out	(decoder_data_out)				,
	    .decoder_rd_en		(decoder_rd_en)					,
	    .dest_sel			(dest_sel)						,
	    .module_en			(module_en)						,
	    .module_partner_en	(module_partner_en)				,
	    .rdi_en				(rdi_en)						,
	    .decoder_error 		(decoder_error)
	);
	
	Demux_1x4 #(.DATA_WIDTH(DATA_WIDTH), .DESTINATION_SEL(DESTINATION_SEL)) Demux1x4_U0(
		.din 				(decoder_data_out)				,
		.sel 				(dest_sel)						,
		.d0 				(controller_data_in)			,
		.d1 				(request_data_in)				,
		.d2 				(sync_fifo_data_in)				,
		.d3					(completion_data_in)
	);
	
	Mux2x1 #(.DATA_WIDTH(DATA_WIDTH)) Mux2x1(
		.in0 				(completion_data_in) 			,
		.in1 				(tx_completion_data_in) 		,
		.sel 				(completion_sel) 				,
		.out 				(completion)
	);

	Packet_buffer_SBRX #(.DATA_WIDTH(DATA_WIDTH), .DEPTH(8)) Completion_packet_buffer_U0(
		.lclk 				(lclk) 							,
		.sys_rst 			(sys_rst) 						,
		.wr_en 				((completion_sel) || (dest_sel[0] && dest_sel[1])),
		.rd_en 				(completion_rd_en)				,
		.wr_data 			(completion) 					,
		.rd_data 			(completion_data_out) 			,
		.full 				(completion_buffer_full) 		,
		.empty 				(completion_buffer_empty)
	);
	
	Packet_buffer_SBRX #(.DATA_WIDTH(DATA_WIDTH), .DEPTH(2)) Request_packet_buffer_U1(
		.lclk 				(lclk) 							,
		.sys_rst 			(sys_rst) 						,
		.wr_en 				(dest_sel[0] && ~dest_sel[1]) 	,
		.rd_en 				(request_rd_en) 				,
		.wr_data 			(request_data_in) 				,
		.rd_data 			(request_data_out) 				,
		.full 				(request_buffer_full) 			,
		.empty 				(request_buffer_empty)
	);
	
	Sync_fifo_SBRX #(.DATA_WIDTH(DATA_WIDTH), .FIFO_DEPTH(32)) Sync_fifo_U0(
    	.lclk				(lclk)							,
		.sys_rst			(sys_rst)						,
		.wr_en				(~dest_sel[0] && dest_sel[1])	,
		.rd_en				(sync_rd_en)					,
		.wr_data			(sync_fifo_data_in)				,
		.rd_data			(sync_fifo_data_out)			,
		.full				(sync_fifo_full)				,
		.empty				(sync_fifo_empty)
	);
	
	PriorityRegisterBlock_SBRX #(.DATA_WIDTH(DATA_WIDTH), .CHUNK_WIDTH(CHUNK_WIDTH)) PriorityRegisterBlock_U0(
		.lclk					(lclk)						,
		.sys_rst				(sys_rst)					,
		.sync_fifo_data			(sync_fifo_data_out)		, 
		.completion_pkt_data	(completion_data_out)		,
		.request_pkt_data		(request_data_out)			,
		.sync_fifo_empty		(sync_fifo_empty)			, 	
		.completion_pkt_empty	(completion_buffer_empty)	, 
		.request_pkt_empty		(request_buffer_empty)		,
		.avail_credit			(avail_credit)				, 	
		.reg_out				(pl_cfg)					, 
		.sync_rd_en				(sync_rd_en)				,
		.completion_rd_en		(completion_rd_en)			, 
		.request_rd_en			(request_rd_en)				, 	
		.data_valid				(pl_cfg_vld)				,
		.lp_clk_ack				(lp_clk_ack)				,
		.active_flag			(active_flag)				,
		.clk_hs_start			(clk_hs_start)				,
		.credit_decr 			(credit_decr)
	);
	
	Synchronizer_SBRX Synchronizer_U0(
		.clk_dst 	(sb_clk) 				,       		
		.rst_n 		(sb_sys_rst) 			,         	
		.signal_src (path_sel) 				,    		
		.signal_dst (path_sel_sync) 		
	);
	
	Synchronizer_SBRX Synchronizer_U1(
		.clk_dst 	(lclk) 					, 				
		.rst_n 		(sys_rst) 				,        	 	
		.signal_src (sb_o_detected & sb_o_detected_delay) 		,    	
		.signal_dst (sb_o_detected_sync) 
	);
	
	Synchronizer_SBRX Synchronizer_U2(
		.clk_dst 	(lclk) 					,       			
		.rst_n 		(sys_rst) 				,         		
		.signal_src (pattern_detected) 		, 	
		.signal_dst	(pattern_detected_sync)
	);
	
	up_down_counter #(.WIDTH(5)) Counter_U0(
		.lclk 		(lclk)					, 	
		.sys_rst 	(sys_rst)				,
		.up 		(lp_cfg_crd)			, 	
		.down 		(credit_decr)			, 	
		.count 		(credits)
	);
	
endmodule