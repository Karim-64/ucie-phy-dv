//implementing the Module Partner block of the SB Controller
module Module_Partner #( parameter DATA_WIDTH = 64 )
(
  input                          lclk, 
  input                          sys_rst, 
  input                          module_partner_en,              // from SB_RX Decoder
  input        [DATA_WIDTH-1:0]  data_in,                       // from SB_RX Decoder
  input        [2:0]             cs,                           // from LTSM
  input        [2:0]             mbinit_cs,                   // from LTSM
  input        [3:0]             mbtrain_cs,                 // from LTSM
  input 	                 	 end_mb,                    // from MB_TX
  input                          valid_frame_error,        // from MB_RX    indicates if valid test passed or not "1 means failed"
  input                          detec_succ,              // from MB_RX    indicates if valid test passed or not "1 means passed"
  input        [15:0]            faulty_lanes,           // from MB_RX    indicates if lanes test passed or not "1 means good" & "0 means fault"
  input                          comparison_done,       // from MB_RX    indicates that the faulty_lanes has a valid value
  input                          sb_exit_m,       // from SB Controller "Module" block indicating that it is ready for state transition
  input        [2:0]             retrain_encoding,    // from SB Controller "Module" block indicating the local die retrain encoding 
  input        [2:0]             max_speed,          // from from SB Controller "Module" block indicating the local die data rate


  output  reg 			 		sb_exit_mp,                   // to LTSM
  output  reg 			 		trainerror_hs_mp,            // to LTSM
  output  reg 			 		trainerror_flag,         // to SB Controller "Module" block
  output  reg  [15:0] 	         error_threshold,        // to MB_RX    
  output  reg          	         start_mb_mp,              // to MB_TX    when sending the {Start Rx Init D to C point test resp} msg from module partner block
  output  reg  [2:0]		 width_degrade_mp,     // to MB_RX
  output  reg                    width_update,        // to MB_RX along with the width_degrade
  output  reg  [DATA_WIDTH-1:0]  data_out_mp,           // to SB_TX Encoder (i.e. to SB Controller Arbiter)
  output  reg                    encoder_en_mp,        // to SB_TX Encoder  (i.e. to SB Controller Arbiter)
  output  reg                    speed_idle_req_mp,    // to LTSM to transition from LINKSPEED to SPEEDIDLE  
  output  reg                    repair_req_mp,      // to LTSM to transition from LINKSPEED to REPAIR  
  output  reg                    test_resp_mp       // to MB_RX to be ready to receive pattern 
  );


//internal signals
logic                   flag = 0;    //to wait for the data part of msg req
logic                   flag_2 = 0;  //to send the data part of msg response in the next cycle
logic                   flag_sb = 0; //to be checked for sb_exit_mp condition
logic                   flag_mb = 0; //to wait for the end_mb signal 
logic [DATA_WIDTH-1:0]  DATA_IN_reg;
logic [2:0]             Resolved_Encoding;
logic [15:0]            faulty_lanes_reg = 16'b0;
logic                   failed = 1'b0;
logic [2:0]             common_speed;


logic status;
logic retrain_enable;  // PHYRETRAIN state retrain encoding comparison enable


localparam 	RESET 		= 3'b000,    SBINIT 		= 3'b001,
				MBINIT 		= 3'b010,    MBTRAIN 		= 3'b011,
				LINKINIT 	= 3'b100,    ACTIVE 		= 3'b101,
				PHYRETRAIN 	= 3'b110,    TRAINERROR 	= 3'b111;

    localparam  PARAM 		= 3'b000,    CAL 			= 3'b001,
				REPAIRCLK 	= 3'b010,    REPAIRVAL 		= 3'b011,
				REVERSALMB 	= 3'b100,    REPAIRMB 		= 3'b101;

    localparam  VALVREF 			= 4'b0000,   DATAVREF 			= 4'b0001,
                SPEEDIDLE 			= 4'b0010,   TXSELFCAL 			= 4'b0011,
                RXCLKCAL 			= 4'b0100,   VALTRAINCENTER 	= 4'b0101,
                VALTRAINVREF 		= 4'b0110,   DATATRAINCENTER1 	= 4'b0111,
                DATATRAINVREF 		= 4'b1000,   RXDESKEW 			= 4'b1001,
                DATATRAINCENTER2 	= 4'b1010,   LINKSPEED 			= 4'b1011,
                REPAIR 				= 4'b1100;


always @(*) begin

    if(valid_frame_error || detec_succ) begin
       if(valid_frame_error)
          failed = 1'b1;
       else
          failed = 1'b0;
    end 

    if(comparison_done) begin
      faulty_lanes_reg = faulty_lanes;
    end

end


assign status = (faulty_lanes_reg == 16'hFFFF||faulty_lanes_reg == 16'hFF||faulty_lanes_reg == 16'hFF00) ? 1'b1 : 1'b0;


always @(*) begin
  if(retrain_enable) begin
    case ({retrain_encoding , data_in[42:40]})
      6'b001_001: Resolved_Encoding = 3'b001;
      6'b001_100: Resolved_Encoding = 3'b100;
      6'b001_010: Resolved_Encoding = 3'b010;
      6'b100_001: Resolved_Encoding = 3'b100;
      6'b100_100: Resolved_Encoding = 3'b100;
      6'b100_010: Resolved_Encoding = 3'b010;
      6'b010_001: Resolved_Encoding = 3'b010;
      6'b010_100: Resolved_Encoding = 3'b010;
      6'b010_010: Resolved_Encoding = 3'b010;
      default:    Resolved_Encoding = 3'b0;  // avoids latch
    endcase

  end else begin
      Resolved_Encoding = 3'b0;
  end

end


assign retrain_enable = ((cs == PHYRETRAIN) && module_partner_en) ? 1'b1 : 1'b0;


// All "data_in" are checked if their: MsgCode[7:0], MsgSubcode[7:0], srcid, dstid & MsgInfo[15:0](only in case MsgInfo contains a known value) match or not
// Msg format = {dp[63], cp[62], rsvd[61:59], dstid[58:56], MsgInfo[55:40], MsgSubcode[39:32], srcid[31:29], rsvd[28:22], MsgCode[21:14], rsvd[13:5], opcode[4:0]}


always @(posedge lclk or negedge sys_rst) begin

  if(!sys_rst) begin

     sb_exit_mp <= 1'b0;             
     trainerror_hs_mp <= 1'b0;      
     trainerror_flag <= 1'b0;     
     error_threshold <= 16'b0;   
     start_mb_mp <= 1'b0; 
     width_degrade_mp <= 3'b011; 
     data_out_mp <= 64'b0;  
     encoder_en_mp <= 1'b0;   
     flag <= 0;
     flag_2 <= 0;
     flag_sb <= 0;
     flag_mb <= 0;
     speed_idle_req_mp <= 1'b0;
     repair_req_mp <= 1'b0;
     width_update <= 1'b0;
     test_resp_mp <= 1'b0;
     common_speed <= 4'b0;
     DATA_IN_reg <= 64'b0;

  end else if(cs == RESET) begin

     trainerror_hs_mp <= 1'b0;      
     trainerror_flag <= 1'b0;     
     error_threshold <= 16'b0;   
     start_mb_mp <= 1'b0; 
     width_degrade_mp <= 3'b011 ; 
     data_out_mp <= 64'b0;  
     encoder_en_mp <= 1'b0;   
     flag <= 0;
     flag_2 <= 0;
     flag_sb <= 0;
     flag_mb <= 0;
     speed_idle_req_mp <= 1'b0;
     repair_req_mp <= 1'b0;
     width_update <= 1'b0;
     test_resp_mp <= 1'b0;
     common_speed <= 4'b0;
     DATA_IN_reg <= 64'b0;

    if(sb_exit_m) begin
      sb_exit_mp <= 1'b1;
    end else begin
      sb_exit_mp <= 1'b0;
    end

  end else if(module_partner_en) begin

    case(cs)
     SBINIT : begin 
               // data_in = {SBINIT done req}
               if( (data_in[21:14] == 8'h95) && (data_in[39:32] == 8'h01) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0] & MsgSubcode[7:0] match or not
                  // data_out_mp = {SBINIT done resp}
                  data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h01 , data_in[31:22] , 8'h9A , data_in[13:0] }; 
                  encoder_en_mp <= 1'b1;
                  trainerror_flag <= 1'b0;    
                  if(sb_exit_m) begin
                    sb_exit_mp <= 1'b1;
                    flag_sb <= 0;
                  end else begin
                    sb_exit_mp <= 1'b0;
                    flag_sb <= 1;
                  end
 
               end else begin
                  data_out_mp <= 64'b0;
                  trainerror_flag <= 1'b1;
                  encoder_en_mp <= 1'b0;
                  sb_exit_mp <= 1'b0;
                  flag_sb <= 0;
               end
     end

     MBINIT: begin
              case(mbinit_cs)
		PARAM: begin
                       // data_in = {TRAINERROR Entry req}
                       if( (data_in[21:14] == 8'hE5) && (data_in[39:32] == 8'h00) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0] & MsgSubcode[7:0] match or not
                          // data_out_mp = {TRAINERROR Entry resp}
                          data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h00 , data_in[31:22] , 8'hEA , data_in[13:0] }; 
                          encoder_en_mp <= 1'b1;
                          sb_exit_mp <= 1'b0;
                          trainerror_hs_mp <= 1'b1;
                          flag_sb <= 0;
                          flag <= 0; 
                          flag_2 <= 0;
                          trainerror_flag <= 1'b0;    

                       // data_in = {MBINIT.PARAM configuration req}
                       end else if( (data_in[21:14] == 8'hA5) && (data_in[39:32] == 8'h00) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0] & MsgSubcode[7:0] match or not
                          flag <= 1;  // to wait for the 64 bit of data 
                          DATA_IN_reg <= data_in;       //storing the msg 
                          data_out_mp <= 64'b0; 
                          encoder_en_mp <= 1'b0;
                          sb_exit_mp <= 1'b0;
                          flag_sb <= 0;
                          flag_2 <= 0;
                          trainerror_flag <= 1'b0;    

                       end else if( flag ) begin
                          flag <= 0;

                          if( data_in[2:0] < max_speed )
                             common_speed <= data_in[2:0];
                          else
                             common_speed <= max_speed;

                          // data_out_mp = {MBINIT.PARAM configuration resp}
                          data_out_mp <= { 1'b0 ,1'b0 , DATA_IN_reg[61:40] , 8'h00 , DATA_IN_reg[31:22] , 8'hAA , DATA_IN_reg[13:0] };  
                          encoder_en_mp <= 1'b1;
                          sb_exit_mp <= 1'b0;
                          trainerror_hs_mp <= 1'b0;
                          flag_sb <= 0;
                          flag_2 <= 1;    // to send the remainig data part of the resp in the next cycle
                          trainerror_flag <= 1'b0;    

                       end else begin
                           data_out_mp <= 64'b0;
                           trainerror_flag <= 1'b1;
                           encoder_en_mp <= 1'b0;
                           sb_exit_mp <= 1'b0;
                           trainerror_hs_mp <= 1'b0;
                           flag_sb <= 0;
                           flag <= 0; 
                           flag_2 <= 0;
                        end

                end

		CAL: begin
                        // data_in = {TRAINERROR Entry req}
                        if( (data_in[21:14] == 8'hE5) && (data_in[39:32] == 8'h00) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0] & MsgSubcode[7:0] match or not
                          // data_out_mp = {TRAINERROR Entry resp}
                          data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h00 , data_in[31:22] , 8'hEA , data_in[13:0] }; 
                          encoder_en_mp <= 1'b1;
                          sb_exit_mp <= 1'b0;
                          trainerror_hs_mp <= 1'b1;
                          flag_sb <= 0;
                          trainerror_flag <= 1'b0;    

                       // data_in = {MBINIT.CAL Done req} 
                       end else if( (data_in[21:14] == 8'hA5) && (data_in[39:32] == 8'h02) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0] & MsgSubcode[7:0] match or not
                          // data_out_mp = {MBINIT.CAL Done resp}
                          data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h02 , data_in[31:22] , 8'hAA , data_in[13:0] }; 
                          encoder_en_mp <= 1'b1;
                          trainerror_hs_mp <= 1'b0;
                          trainerror_flag <= 1'b0;    
                          if(sb_exit_m) begin
                            sb_exit_mp <= 1'b1;
                            flag_sb <= 0;
                          end else begin
                            sb_exit_mp <= 1'b0;
                            flag_sb <= 1;
                          end
                         
                        end else begin
                           data_out_mp <= 64'b0;
                           trainerror_flag <= 1'b1;
                           encoder_en_mp <= 1'b0;
                           sb_exit_mp <= 1'b0;
                           trainerror_hs_mp <= 1'b0;
                           flag_sb <= 0;
                        end
                end

		REPAIRCLK: begin
                            // data_in = {TRAINERROR Entry req}
                            if( (data_in[21:14] == 8'hE5) && (data_in[39:32] == 8'h00) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0] & MsgSubcode[7:0] match or not
                              // data_out_mp = {TRAINERROR Entry resp}
                              data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h00 , data_in[31:22] , 8'hEA , data_in[13:0] }; 
                              encoder_en_mp <= 1'b1;
                              sb_exit_mp <= 1'b0;
                              trainerror_hs_mp <= 1'b1;
                              flag_sb <= 0;
                              trainerror_flag <= 1'b0;    

                            // data_in = {MBINIT.REPAIRCLK init req}
                            end else if( (data_in[21:14] == 8'hA5) && (data_in[39:32] == 8'h03) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0] & MsgSubcode[7:0] match or not
                               // data_out_mp = {MBINIT.REPAIRCLK init resp}
                               data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h03 , data_in[31:22] , 8'hAA , data_in[13:0] }; 
                               encoder_en_mp <= 1'b1;
                               sb_exit_mp <= 1'b0;
                               trainerror_hs_mp <= 1'b0;
                               flag_sb <= 0;
                               trainerror_flag <= 1'b0;    

                             // data_in = {MBINIT.REPAIRCLK result req}
                             end else if( (data_in[21:14] == 8'hA5) && (data_in[39:32] == 8'h04) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0] & MsgSubcode[7:0] match or not
                               // data_out_mp = {MBINIT.REPAIRCLK result resp}
                               data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h04 , data_in[31:22] , 8'hAA , data_in[13:0] }; 
                               encoder_en_mp <= 1'b1;
                               sb_exit_mp <= 1'b0;
                               trainerror_hs_mp <= 1'b0;
                               flag_sb <= 0;
                               trainerror_flag <= 1'b0;    

                             // data_in = {MBINIT.REPAIRCLK done req}
                             end else if( (data_in[21:14] == 8'hA5) && (data_in[39:32] == 8'h08) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0] & MsgSubcode[7:0] match or not
                               // data_out_mp = {MBINIT.REPAIRCLK done resp}
                               data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h08 , data_in[31:22] , 8'hAA , data_in[13:0] }; 
                               encoder_en_mp <= 1'b1;
                               trainerror_hs_mp <= 1'b0;
                               trainerror_flag <= 1'b0;    
                               if(sb_exit_m) begin
                                 sb_exit_mp <= 1'b1;
                                 flag_sb <= 0;
                               end else begin
                                 sb_exit_mp <= 1'b0;
                                 flag_sb <= 1;
                               end

                             end else begin
                               data_out_mp <= 64'b0;
                               trainerror_flag <= 1'b1;
                               encoder_en_mp <= 1'b0;
                               sb_exit_mp <= 1'b0;
                               trainerror_hs_mp <= 1'b0;
                               flag_sb <= 0;
                             end
                end

		REPAIRVAL: begin
                            test_resp_mp <= 1'b0 ; 
                            // data_in = {TRAINERROR Entry req}
                            if( (data_in[21:14] == 8'hE5) && (data_in[39:32] == 8'h00) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0] & MsgSubcode[7:0] match or not
                              // data_out_mp = {TRAINERROR Entry resp}
                              data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h00 , data_in[31:22] , 8'hEA , data_in[13:0] }; 
                              encoder_en_mp <= 1'b1;
                              sb_exit_mp <= 1'b0;
                              trainerror_hs_mp <= 1'b1;
                              flag_sb <= 0;
                              trainerror_flag <= 1'b0;    

                            // data_in = {MBINIT.REPAIRVAL init req}
                            end else if( (data_in[21:14] == 8'hA5) && (data_in[39:32] == 8'h09) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0] & MsgSubcode[7:0] match or not
                               // data_out_mp = {MBINIT.REPAIRVAL init resp}
                               data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h09 , data_in[31:22] , 8'hAA , data_in[13:0] }; 
                               encoder_en_mp <= 1'b1;
                               sb_exit_mp <= 1'b0;
                               trainerror_hs_mp <= 1'b0;
                               flag_sb <= 0;
                               trainerror_flag <= 1'b0; 
                               test_resp_mp <= 1'b1 ;    

                             // data_in = {MBINIT.REPAIRVAL result req}
                             end else if( (data_in[21:14] == 8'hA5) && (data_in[39:32] == 8'h0A) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0] & MsgSubcode[7:0] match or not
                               // data_out_mp = {MBINIT.REPAIRVAL result resp}
                               if(failed) begin                     // valid test failed "valid bit is 0"
                                  data_out_mp <= { 1'b0 ,1'b0 , data_in[61:42] , 1'b0 , 1'b0 , 8'h0A , data_in[31:22] , 8'hAA , data_in[13:0] }; 
                                  encoder_en_mp <= 1'b1;
                                  sb_exit_mp <= 1'b0;
                                  trainerror_hs_mp <= 1'b0;
                                  flag_sb <= 0;
                                  trainerror_flag <= 1'b0;    
                               end else begin                                 // valid test passed "valid bit is 1"
                                  data_out_mp <= { 1'b0 ,1'b0 , data_in[61:42] , 1'b0 , 1'b1 , 8'h0A , data_in[31:22] , 8'hAA , data_in[13:0] }; 
                                  encoder_en_mp <= 1'b1;
                                  sb_exit_mp <= 1'b0;
                                  trainerror_hs_mp <= 1'b0;
                                  flag_sb <= 0;
                                  trainerror_flag <= 1'b0;    
                               end

                             // data_in = {MBINIT.REPAIRVAL done req}
                             end else if( (data_in[21:14] == 8'hA5) && (data_in[39:32] == 8'h0C) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0] & MsgSubcode[7:0] match or not
                               // data_out_mp = {MBINIT.REPAIRVAL done resp}
                               data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h0C , data_in[31:22] , 8'hAA , data_in[13:0] }; 
                               encoder_en_mp <= 1'b1;
                               trainerror_hs_mp <= 1'b0;
                               trainerror_flag <= 1'b0;    
                               if(sb_exit_m) begin
                                 sb_exit_mp <= 1'b1;
                                 flag_sb <= 0;
                               end else begin
                                 sb_exit_mp <= 1'b0;
                                 flag_sb <= 1;
                               end

                             end else begin
                               data_out_mp <= 64'b0;
                               trainerror_flag <= 1'b1;
                               encoder_en_mp <= 1'b0;
                               sb_exit_mp <= 1'b0;
                               trainerror_hs_mp <= 1'b0;
                               flag_sb <= 0;
                             end
                end

		REVERSALMB: begin
                             // data_in = {TRAINERROR Entry req}
                             test_resp_mp <= 1'b0 ; 
                             if( (data_in[21:14] == 8'hE5) && (data_in[39:32] == 8'h00) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0] & MsgSubcode[7:0] match or not
                               // data_out_mp = {TRAINERROR Entry resp}
                               data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h00 , data_in[31:22] , 8'hEA , data_in[13:0] }; 
                               encoder_en_mp <= 1'b1;
                               sb_exit_mp <= 1'b0;
                               trainerror_hs_mp <= 1'b1;
                               flag_sb <= 0;
                               flag_2 <= 0;
                               trainerror_flag <= 1'b0;    

                             // data_in = {MBINIT.REVERSALMB init req}
                             end else if( (data_in[21:14] == 8'hA5) && (data_in[39:32] == 8'h0D) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0] & MsgSubcode[7:0] match or not
                               // data_out_mp = {MBINIT.REVERSALMB init resp}
                               data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h0D , data_in[31:22] , 8'hAA , data_in[13:0] }; 
                               encoder_en_mp <= 1'b1;
                               sb_exit_mp <= 1'b0;
                               flag_sb <= 0;
                               flag_2 <= 0;
                               trainerror_flag <= 1'b0;    

                             // data_in = {MBINIT.REVERSALMB clear error req}
                             end else if( (data_in[21:14] == 8'hA5) && (data_in[39:32] == 8'h0E) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0] & MsgSubcode[7:0] match or not
                               // data_out_mp = {MBINIT.REVERSALMB clear error resp}
                               data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h0E , data_in[31:22] , 8'hAA , data_in[13:0] }; 
                               encoder_en_mp <= 1'b1;
                               sb_exit_mp <= 1'b0;
                               flag_sb <= 0;
                               flag_2 <= 0;
                               trainerror_flag <= 1'b0;
                               test_resp_mp <= 1'b1 ;     

                             // data_in = {MBINIT.REVERSALMB result req}
                             end else if( (data_in[21:14] == 8'hA5) && (data_in[39:32] == 8'h0F) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0] & MsgSubcode[7:0] match or not
                               // data_out_mp = {MBINIT.REVERSALMB result resp}
                               data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h0F , data_in[31:22] , 8'hAA , data_in[13:5] , 5'b11011 }; 
                               encoder_en_mp <= 1'b1;
                               sb_exit_mp <= 1'b0;
                               flag_sb <= 0;
                               flag_2 <= 1;    // to send the remainig data part of the resp in the next cycle
                               trainerror_flag <= 1'b0;    
                             
                             // data_in = {MBINIT.REVERSALMB done req} 
                             end else if( (data_in[21:14] == 8'hA5) && (data_in[39:32] == 8'h10) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0] & MsgSubcode[7:0] match or not
                               // data_out_mp = {MBINIT.REVERSALMB done resp}
                               data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h10 , data_in[31:22] , 8'hAA , data_in[13:0] }; 
                               encoder_en_mp <= 1'b1;
                               flag_2 <= 0;
                               trainerror_flag <= 1'b0;    
                               if(sb_exit_m) begin
                                 sb_exit_mp <= 1'b1;
                                 flag_sb <= 0;
                               end else begin
                                 sb_exit_mp <= 1'b0;
                                 flag_sb <= 1;
                               end

                             end else begin
                               data_out_mp <= 64'b0;
                               trainerror_flag <= 1'b1;
                               encoder_en_mp <= 1'b0;
                               sb_exit_mp <= 1'b0;
                               flag_sb <= 0;
                               flag_2 <= 0;
                             end
                end

		REPAIRMB: begin
                           // data_in = {TRAINERROR Entry req}
                           if( (data_in[21:14] == 8'hE5) && (data_in[39:32] == 8'h00) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0] & MsgSubcode[7:0] match or not
                               // data_out_mp = {TRAINERROR Entry resp}
                               data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h00 , data_in[31:22] , 8'hEA , data_in[13:0] }; 
                               encoder_en_mp <= 1'b1;
                               sb_exit_mp <= 1'b0;
                               trainerror_hs_mp <= 1'b1;
                               flag_sb <= 0;
                               flag_2 <= 0;
                               flag <= 0; 
                               width_update <= 1'b0;
                               test_resp_mp <= 1'b0;
                               trainerror_flag <= 1'b0;    

                            // data_in = {MBINIT.REPAIRMB start req}
                            end else if( (data_in[21:14] == 8'hA5) && (data_in[39:32] == 8'h11) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                               // data_out_mp = {MBINIT.REPAIRMB start resp}
                               data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h11 , data_in[31:22] , 8'hAA , data_in[13:0] }; 
                               encoder_en_mp <= 1'b1;
                               sb_exit_mp <= 1'b0;
                               flag_sb <= 0;
                               flag_2 <= 0;
                               flag <= 0; 
                               width_update <= 1'b0;
                               test_resp_mp <= 1'b0;
                               trainerror_flag <= 1'b0;    

                            // data_in = {Start Tx Init D to C point test req}
                            end else if( (data_in[21:14] == 8'h85) && (data_in[39:32] == 8'h01) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                flag <= 1;  // to wait for the 64 bit of data 
                                error_threshold <= data_in[55:40];
                                DATA_IN_reg <= data_in;       //storing the msg 
                                data_out_mp <= 64'b0; 
                                encoder_en_mp <= 1'b0;
                                sb_exit_mp <= 1'b0;
                                flag_sb <= 0;
                                flag_2 <= 0;
                                width_update <= 1'b0;
                                test_resp_mp <= 1'b0;
                                trainerror_flag <= 1'b0;    

                             end else if( flag ) begin
                                 flag <= 0;
                                 // data_out_mp = {Start Tx Init D to C point test resp}
                                 data_out_mp <= { 1'b0 ,1'b0 , DATA_IN_reg[61:56] , 16'h0000 , 8'h01 , DATA_IN_reg[31:22] , 8'h8A , DATA_IN_reg[13:5] , 5'b10010 }; 
                                 encoder_en_mp <= 1'b1;
                                 sb_exit_mp <= 1'b0;
                                 trainerror_hs_mp <= 1'b0;
                                 flag_sb <= 0;
                                 flag_2 <= 0;
                                 width_update <= 1'b0;
                                 test_resp_mp <= 1'b0;
                                 trainerror_flag <= 1'b0;    

                              // data_in = {LFSR_clear_error req}
                              end else if( (data_in[21:14] == 8'h85) && (data_in[39:32] == 8'h02) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                 // data_out_mp = {LFSR_clear_error resp}
                                 data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h02 , data_in[31:22] , 8'h8A , data_in[13:0] }; 
                                 encoder_en_mp <= 1'b1;
                                 sb_exit_mp <= 1'b0;
                                 trainerror_hs_mp <= 1'b0;
                                 flag_sb <= 0;
                                 flag_2 <= 0;
                                 flag <= 0; 
                                 width_update <= 1'b0;
                                 test_resp_mp <= 1'b1;
                                 trainerror_flag <= 1'b0;    

                              // data_in = {Tx Init D to C results req}
                              end else if( (data_in[21:14] == 8'h85) && (data_in[39:32] == 8'h03) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                             
                                  // data_out_mp = {Tx Init D to C results resp}
                                  // PerLaneID test passed "status bit is 1"    // PerLaneID test failed "status bit is 0"
                                  data_out_mp <= { 1'b0 ,1'b0 , data_in[61:45] , status , data_in[43:40] , 8'h03 , data_in[31:22] , 8'h8A , data_in[13:5] , 5'b11011 }; 
                                  encoder_en_mp <= 1'b1;
                                  sb_exit_mp <= 1'b0;
                                  trainerror_hs_mp <= 1'b0;
                                  flag <= 0;
                                  flag_2 <= 1;    // to send the remainig data part of the resp in the next cycle 
                                  flag_sb <= 0;
                                  width_update <= 1'b0;
                                  test_resp_mp <= 1'b0;
                                  trainerror_flag <= 1'b0;    

                               // data_in =  {End Tx Init D to C point test req}
                               end else if( (data_in[21:14] == 8'h85) && (data_in[39:32] == 8'h04) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                  // data_out_mp = {End Tx Init D to C point test resp}
                                  data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h04 , data_in[31:22] , 8'h8A , data_in[13:0] }; 
                                  encoder_en_mp <= 1'b1;
                                  sb_exit_mp <= 1'b0;
                                  trainerror_hs_mp <= 1'b0;
                                  flag <= 0;
                                  flag_sb <= 0;
                                  flag_2 <= 0;
                                  width_update <= 1'b0;
                                  test_resp_mp <= 1'b0;
                                  trainerror_flag <= 1'b0;    

                            // data_in = {MBINIT.REPAIRMB apply degrade req}
                            end else if( (data_in[21:14] == 8'hA5) && (data_in[39:32] == 8'h14) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                               // data_out_mp = {MBINIT.REPAIRMB apply degrade resp}
                               data_out_mp <= { 1'b0 ,1'b0 , data_in[61:56] , 16'h0000 , 8'h14 , data_in[31:22] , 8'hAA , data_in[13:0] }; 
                               encoder_en_mp <= 1'b1;
                               sb_exit_mp <= 1'b0;
                               width_degrade_mp <= data_in[42:40];
                               width_update <= 1'b1;
                               flag_sb <= 0;
                               flag_2 <= 0;
                               flag <= 0;
                               test_resp_mp <= 1'b0;
                               trainerror_flag <= 1'b0;    

                             // data_in = {MBINIT.REPAIRMB end req} 
                             end else if( (data_in[21:14] == 8'hA5) && (data_in[39:32] == 8'h13) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                               // data_out_mp = {MBINIT.REPAIRMB end resp}
                               data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h13 , data_in[31:22] , 8'hAA , data_in[13:0] }; 
                               encoder_en_mp <= 1'b1;
                               flag_2 <= 0;
                               flag <= 0;
                               width_update <= 1'b0;
                               test_resp_mp <= 1'b0;
                               trainerror_flag <= 1'b0;    
                               if(sb_exit_m) begin
                                 sb_exit_mp <= 1'b1;
                                 flag_sb <= 0;
                               end else begin
                                 sb_exit_mp <= 1'b0;
                                 flag_sb <= 1;
                               end

                             end else begin
                               data_out_mp <= 64'b0;
                               trainerror_flag <= 1'b1;
                               encoder_en_mp <= 1'b0;
                               sb_exit_mp <= 1'b0;
                               flag_sb <= 0;
                               flag_2 <= 0;
                               flag <= 0;
                               width_update <= 1'b0;
                               test_resp_mp <= 1'b0;
                             end
                end

		default: begin
                          sb_exit_mp <= 1'b0;             
                          trainerror_hs_mp <= 1'b0;      
                          trainerror_flag <= 1'b0;     
                          //error_threshold <= 16'b0;   
                          start_mb_mp <= 1'b0; 
                          //width_degrade_mp <= 3'b0; 
                          data_out_mp <= 64'b0;  
                          encoder_en_mp <= 1'b0;  
                          flag <= 0;
                          flag_2 <= 0;
                          flag_sb <= 0;
                          speed_idle_req_mp <= 1'b0;
                          repair_req_mp <= 1'b0;
                          width_update <= 1'b0;
                          test_resp_mp <= 1'b0;
                end

	      endcase
     end

     MBTRAIN : begin
                case(mbtrain_cs)
                  VALVREF: begin
                             // data_in = {TRAINERROR Entry req}
                             if( (data_in[21:14] == 8'hE5) && (data_in[39:32] == 8'h00) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                               // data_out_mp = {TRAINERROR Entry resp}
                               data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h00 , data_in[31:22] , 8'hEA , data_in[13:0] }; 
                               encoder_en_mp <= 1'b1;
                               sb_exit_mp <= 1'b0;
                               start_mb_mp <= 1'b0;
                               trainerror_hs_mp <= 1'b1;
                               flag <= 0;
                               flag_sb <= 0;
                               flag_mb <= 0;
                               trainerror_flag <= 1'b0;    

                             // data_in = {MBTRAIN.VALVREF start req}
                             end else if( (data_in[21:14] == 8'hB5) && (data_in[39:32] == 8'h00) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                               // data_out_mp = {MBTRAIN.VALVREF start resp}
                               data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h00 , data_in[31:22] , 8'hBA , data_in[13:0] }; 
                               encoder_en_mp <= 1'b1;
                               sb_exit_mp <= 1'b0;
                               start_mb_mp <= 1'b0;
                               trainerror_hs_mp <= 1'b0;
                               flag <= 0;
                               flag_sb <= 0;
                               flag_mb <= 0;
                               trainerror_flag <= 1'b0;    

                             // data_in = {Start Rx Init D to C point test req}
                             end else if( (data_in[21:14] == 8'h85) && (data_in[39:32] == 8'h07) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                               flag <= 1;  // to wait for the 64 bit of data 
                               DATA_IN_reg <= data_in;       //storing the msg 
                               flag_sb <= 0;
                               data_out_mp <= 64'b0; 
                               encoder_en_mp <= 1'b0;
                               sb_exit_mp <= 1'b0;
                               start_mb_mp <= 1'b0;
                               trainerror_hs_mp <= 1'b0;
                               flag_sb <= 0;
                               flag_mb <= 0;
                               trainerror_flag <= 1'b0;    

                             end else if( flag ) begin
                               flag <= 0;
                               // data_out_mp = {Start Rx Init D to C point test resp}
                               data_out_mp <= { 1'b0 ,1'b0 , DATA_IN_reg[61:56] , 16'h0000 , 8'h07 , DATA_IN_reg[31:22] , 8'h8A , DATA_IN_reg[13:5] , 5'b10010}; 
                               encoder_en_mp <= 1'b1;
                               sb_exit_mp <= 1'b0;
                               start_mb_mp <= 1'b0;
                               trainerror_hs_mp <= 1'b0;
                               flag_sb <= 0;
                               flag_mb <= 0;
                               trainerror_flag <= 1'b0;    

                             // data_in = {LFSR_clear_error req}
                             end else if( (data_in[21:14] == 8'h85) && (data_in[39:32] == 8'h02) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                               // data_out_mp = {LFSR_clear_error resp}
                               data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h02 , data_in[31:22] , 8'h8A , data_in[13:0] }; 
                               encoder_en_mp <= 1'b1;
                               sb_exit_mp <= 1'b0;
                               start_mb_mp <= 1'b1;
                               flag_mb <= 1;
                               flag_sb <= 0;
                               flag <= 0; 
                               trainerror_flag <= 1'b0;    

                             // data_in = {Rx Init D to C Tx Count Done resp}
                             end else if( (data_in[21:14] == 8'h8A) && (data_in[39:32] == 8'h08) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                               // data_out_mp
                               data_out_mp <= 64'b0;
                               encoder_en_mp <= 1'b0;
                               sb_exit_mp <= 1'b0;
                               start_mb_mp <= 1'b0;
                               trainerror_hs_mp <= 1'b0; 
                               flag <= 0;
                               flag_sb <= 0;
                               flag_mb <= 0;
                               trainerror_flag <= 1'b0;    
                               
                             // data_in =  {End Rx Init D to C point test req}
                             end else if( (data_in[21:14] == 8'h85) && (data_in[39:32] == 8'h09) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                               // data_out_mp =  {End Rx Init D to C point test resp}
                               data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h09 , data_in[31:22] , 8'h8A , data_in[13:0] }; 
                               encoder_en_mp <= 1'b1;
                               sb_exit_mp <= 1'b0;
                               start_mb_mp <= 1'b0;
                               trainerror_hs_mp <= 1'b0;
                               flag <= 0;
                               flag_sb <= 0;
                               flag_mb <= 0;
                               trainerror_flag <= 1'b0;    

                             // data_in = {MBTRAIN.VALVREF end req}
                             end else if( (data_in[21:14] == 8'hB5) && (data_in[39:32] == 8'h01) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                               // data_out_mp =  {MBTRAIN.VALVREF end resp}
                               data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h01 , data_in[31:22] , 8'hBA , data_in[13:0] }; 
                               encoder_en_mp <= 1'b1;
                               start_mb_mp <= 1'b0;
                               trainerror_hs_mp <= 1'b0;
                               flag <= 0;
                               flag_mb <= 0;
                               trainerror_flag <= 1'b0;    
                               if(sb_exit_m) begin
                                 sb_exit_mp <= 1'b1;
                                 flag_sb <= 0;
                               end else begin
                                 sb_exit_mp <= 1'b0;
                                 flag_sb <= 1;
                               end

                             end else begin
                               data_out_mp <= 64'b0;
                               trainerror_flag <= 1'b1;
                               encoder_en_mp <= 1'b0;
                               sb_exit_mp <= 1'b0;
                               start_mb_mp <= 1'b0;
                               trainerror_hs_mp <= 1'b0;
                               flag <= 0;
                               flag_sb <= 0;
                               flag_mb <= 0;
                             end
                               
                  end

		  DATAVREF: begin
                             // data_in = {TRAINERROR Entry req}
                             if( (data_in[21:14] == 8'hE5) && (data_in[39:32] == 8'h00) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                               // data_out_mp = {TRAINERROR Entry resp}
                               data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h00 , data_in[31:22] , 8'hEA , data_in[13:0] }; 
                               encoder_en_mp <= 1'b1;
                               sb_exit_mp <= 1'b0;
                               start_mb_mp <= 1'b0;
                               trainerror_hs_mp <= 1'b1;
                               flag <= 0;
                               flag_sb <= 0;
                               flag_mb <= 0;
                               trainerror_flag <= 1'b0;    

                             // data_in = {MBTRAIN.DATAVREF start req}
                             end else if( (data_in[21:14] == 8'hB5) && (data_in[39:32] == 8'h02) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                               // data_out_mp =  {MBTRAIN.DATAVREF start resp}
                               data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h02 , data_in[31:22] , 8'hBA , data_in[13:0] }; 
                               encoder_en_mp <= 1'b1;
                               sb_exit_mp <= 1'b0;
                               start_mb_mp <= 1'b0;
                               trainerror_hs_mp <= 1'b0;
                               flag <= 0;
                               flag_sb <= 0;
                               flag_mb <= 0;
                               trainerror_flag <= 1'b0;    

                             // data_in = {Start Rx Init D to C point test req}
                             end else if( (data_in[21:14] == 8'h85) && (data_in[39:32] == 8'h07) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                               flag <= 1;  // to wait for the 64 bit of data 
                               DATA_IN_reg <= data_in;       //storing the msg 
                               flag_sb <= 0;
                               flag_mb <= 0;
                               data_out_mp <= 64'b0; 
                               encoder_en_mp <= 1'b0;
                               sb_exit_mp <= 1'b0;
                               start_mb_mp <= 1'b0;
                               trainerror_hs_mp <= 1'b0;
                               trainerror_flag <= 1'b0;    

                             end else if( flag ) begin
                               flag <= 0;
                               // data_out_mp = {Start Rx Init D to C point test resp}
                               data_out_mp <= { 1'b0 ,1'b0 , DATA_IN_reg[61:56] , 16'h0000 , 8'h07 , DATA_IN_reg[31:22] , 8'h8A , DATA_IN_reg[13:5] , 5'b10010 }; 
                               encoder_en_mp <= 1'b1;
                               sb_exit_mp <= 1'b0;
                               start_mb_mp <= 1'b0;
                               trainerror_hs_mp <= 1'b0;
                               flag_sb <= 0;
                               flag_mb <= 0;
                               trainerror_flag <= 1'b0;    

                             // data_in = {LFSR_clear_error req}
                             end else if( (data_in[21:14] == 8'h85) && (data_in[39:32] == 8'h02) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                               // data_out_mp = {LFSR_clear_error resp}
                               data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h02 , data_in[31:22] , 8'h8A , data_in[13:0] }; 
                               encoder_en_mp <= 1'b1;
                               sb_exit_mp <= 1'b0;
                               start_mb_mp <= 1'b1;
                               flag_mb <= 1;
                               flag_sb <= 0;
                               flag <= 0; 
                               trainerror_flag <= 1'b0;    

                             // data_in = {Rx Init D to C Tx Count Done resp}
                             end else if( (data_in[21:14] == 8'h8A) && (data_in[39:32] == 8'h08) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                               // data_out_mp
                               data_out_mp <= 64'b0;
                               encoder_en_mp <= 1'b0;
                               sb_exit_mp <= 1'b0;
                               start_mb_mp <= 1'b0;
                               trainerror_hs_mp <= 1'b0; 
                               flag <= 0;
                               flag_sb <= 0;
                               flag_mb <= 0;
                               trainerror_flag <= 1'b0;    

                             // data_in =  {End Rx Init D to C point test req}
                             end else if( (data_in[21:14] == 8'h85) && (data_in[39:32] == 8'h09) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                               // data_out_mp =  {End Rx Init D to C point test resp}
                               data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h09 , data_in[31:22] , 8'h8A , data_in[13:0] }; 
                               encoder_en_mp <= 1'b1;
                               sb_exit_mp <= 1'b0;
                               start_mb_mp <= 1'b0;
                               trainerror_hs_mp <= 1'b0;
                               flag <= 0;
                               flag_sb <= 0;
                               flag_mb <= 0;
                               trainerror_flag <= 1'b0;    

                             // data_in = {MBTRAIN.DATAVREF end req}
                             end else if( (data_in[21:14] == 8'hB5) && (data_in[39:32] == 8'h03) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                               // data_out_mp = {MBTRAIN.DATAVREF end resp}
                               data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h03 , data_in[31:22] , 8'hBA , data_in[13:0] }; 
                               encoder_en_mp <= 1'b1;          
                               start_mb_mp <= 1'b0;
                               trainerror_hs_mp <= 1'b0;
                               flag <= 0;
                               flag_mb <= 0;
                               trainerror_flag <= 1'b0;    
                               if(sb_exit_m) begin     // to wait for module sb_exit_mp signal
                                 sb_exit_mp <= 1'b1;
                                 flag_sb <= 0;
                               end else begin
                                 sb_exit_mp <= 1'b0;
                                 flag_sb <= 1;
                               end

                             end else begin
                               data_out_mp <= 64'b0;
                               trainerror_flag <= 1'b1;
                               encoder_en_mp <= 1'b0;
                               sb_exit_mp <= 1'b0;
                               start_mb_mp <= 1'b0;
                               trainerror_hs_mp <= 1'b0;
                               flag <= 0;
                               flag_sb <= 0;
                               flag_mb <= 0;
                             end

                  end

		  SPEEDIDLE: begin
                               // data_in = {TRAINERROR Entry req}
                               if( (data_in[21:14] == 8'hE5) && (data_in[39:32] == 8'h00) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                 // data_out_mp = {TRAINERROR Entry resp}
                                 data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h00 , data_in[31:22] , 8'hEA , data_in[13:0] }; 
                                 encoder_en_mp <= 1'b1;
                                 sb_exit_mp <= 1'b0;
                                 trainerror_hs_mp <= 1'b1;
                                 flag_sb <= 0;
                                 speed_idle_req_mp <= 1'b0;
                                 repair_req_mp <= 1'b0;
                                 trainerror_flag <= 1'b0;    

                               // data_in = {MBTRAIN.SPEEDIDLE done req}
                               end else if( (data_in[21:14] == 8'hB5) && (data_in[39:32] == 8'h04) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                 // data_out_mp = {MBTRAIN.SPEEDIDLE done resp}
                                 data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h04 , data_in[31:22] , 8'hBA , data_in[13:0] }; 
                                 encoder_en_mp <= 1'b1;
                                 trainerror_hs_mp <= 1'b0;
                                 speed_idle_req_mp <= 1'b0;
                                 repair_req_mp <= 1'b0;  
                                 trainerror_flag <= 1'b0;    
                                 if(sb_exit_m) begin     // to wait for module sb_exit_mp signal
                                   sb_exit_mp <= 1'b1;
                                   flag_sb <= 0;
                                 end else begin
                                   sb_exit_mp <= 1'b0;
                                   flag_sb <= 1;
                                 end

                               end else begin
                                  data_out_mp <= 64'b0;
                                  trainerror_flag <= 1'b1;
                                  encoder_en_mp <= 1'b0;
                                  sb_exit_mp <= 1'b0;
                                  trainerror_hs_mp <= 1'b0;
                                  flag_sb <= 0;
                                  speed_idle_req_mp <= 1'b0;
                                  repair_req_mp <= 1'b0;
                               end
                              
                  end   
 
		  TXSELFCAL: begin
                               // data_in = {TRAINERROR Entry req}
                               if( (data_in[21:14] == 8'hE5) && (data_in[39:32] == 8'h00) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                 // data_out_mp = {TRAINERROR Entry resp}
                                 data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h00 , data_in[31:22] , 8'hEA , data_in[13:0] }; 
                                 encoder_en_mp <= 1'b1;
                                 sb_exit_mp <= 1'b0;
                                 trainerror_hs_mp <= 1'b1;
                                 flag_sb <= 0;
                                 trainerror_flag <= 1'b0;    

                               // data_in =  {MBTRAIN.TXSELFCAL Done req}
                               end else if( (data_in[21:14] == 8'hB5) && (data_in[39:32] == 8'h05) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                 // data_out_mp =  {MBTRAIN.TXSELFCAL Done resp}
                                 data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h05 , data_in[31:22] , 8'hBA , data_in[13:0] }; 
                                 encoder_en_mp <= 1'b1;
                                 trainerror_hs_mp <= 1'b0;
                                 trainerror_flag <= 1'b0;    
                                 if(sb_exit_m) begin     // to wait for module sb_exit_mp signal
                                   sb_exit_mp <= 1'b1;
                                   flag_sb <= 0;
                                 end else begin
                                   sb_exit_mp <= 1'b0;
                                   flag_sb <= 1;
                                 end

                               end else begin
                                 data_out_mp <= 64'b0;
                                 trainerror_flag <= 1'b1;
                                 encoder_en_mp <= 1'b0;
                                 sb_exit_mp <= 1'b0;
                                 trainerror_hs_mp <= 1'b0;
                                 flag_sb <= 0;
                               end

                  end   

		  RXCLKCAL: begin
                              // data_in = {TRAINERROR Entry req}
                               if( (data_in[21:14] == 8'hE5) && (data_in[39:32] == 8'h00) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                 // data_out_mp = {TRAINERROR Entry resp}
                                 data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h00 , data_in[31:22] , 8'hEA , data_in[13:0] }; 
                                 encoder_en_mp <= 1'b1;
                                 sb_exit_mp <= 1'b0;
                                 trainerror_hs_mp <= 1'b1;
                                 flag_sb <= 0;
                                 trainerror_flag <= 1'b0;    

                              // data_in = {MBTRAIN.RXCLKCAL start req}
                              end else if( (data_in[21:14] == 8'hB5) && (data_in[39:32] == 8'h06) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                               // data_out_mp = {MBTRAIN.RXCLKCAL start resp}
                               data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h06 , data_in[31:22] , 8'hBA , data_in[13:0] }; 
                               encoder_en_mp <= 1'b1;
                               sb_exit_mp <= 1'b0;
                               trainerror_hs_mp <= 1'b0;
                               flag_sb <= 0;
                               trainerror_flag <= 1'b0;    

                             // data_in = {MBTRAIN.RXCLKCAL done req}
                             end else if( (data_in[21:14] == 8'hB5) && (data_in[39:32] == 8'h07) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                               // data_out_mp = {MBTRAIN.RXCLKCAL done resp}
                               data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h07 , data_in[31:22] , 8'hBA , data_in[13:0] }; 
                               encoder_en_mp <= 1'b1;
                               trainerror_hs_mp <= 1'b0;
                               trainerror_flag <= 1'b0;    
                               if(sb_exit_m) begin     // to wait for module sb_exit_mp signal
                                  sb_exit_mp <= 1'b1;
                                  flag_sb <= 0;
                               end else begin
                                  sb_exit_mp <= 1'b0;
                                  flag_sb <= 1;
                               end

                             end else begin
                               data_out_mp <= 64'b0;
                               trainerror_flag <= 1'b1;
                               encoder_en_mp <= 1'b0;
                               sb_exit_mp <= 1'b0;
                               trainerror_hs_mp <= 1'b0;
                               flag_sb <= 0;
                             end

                  end    
  
		  VALTRAINCENTER: begin
                                    // data_in = {TRAINERROR Entry req}
                                    if( (data_in[21:14] == 8'hE5) && (data_in[39:32] == 8'h00) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                      // data_out_mp = {TRAINERROR Entry resp}
                                      data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h00 , data_in[31:22] , 8'hEA , data_in[13:0] }; 
                                      encoder_en_mp <= 1'b1;
                                      sb_exit_mp <= 1'b0;
                                      trainerror_hs_mp <= 1'b1;
                                      flag <= 0;
                                      flag_sb <= 0;
                                      test_resp_mp <= 1'b0;
                                      trainerror_flag <= 1'b0;    

                                    // data_in = {MBTRAIN.VALTRAINCENTER start req}
                                    end else if( (data_in[21:14] == 8'hB5) && (data_in[39:32] == 8'h08) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                      // data_in = {MBTRAIN.VALTRAINCENTER start resp}
                                      data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h08 , data_in[31:22] , 8'hBA , data_in[13:0] }; 
                                      encoder_en_mp <= 1'b1;
                                      sb_exit_mp <= 1'b0;
                                      trainerror_hs_mp <= 1'b0;
                                      flag <= 0;
                                      flag_sb <= 0;
                                      test_resp_mp <= 1'b0;
                                      trainerror_flag <= 1'b0;    

                                    // data_in = {Start Tx Init D to C point test req}
                                    end else if( (data_in[21:14] == 8'h85) && (data_in[39:32] == 8'h01) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                       flag <= 1;  // to wait for the 64 bit of data 
                                       error_threshold <= data_in[55:40];
                                       DATA_IN_reg <= data_in;       //storing the msg 
                                       flag_sb <= 0;
                                       test_resp_mp <= 1'b0;
                                       data_out_mp <= 64'b0;
                                       encoder_en_mp <= 1'b0;
                                       sb_exit_mp <= 1'b0;
                                       trainerror_hs_mp <= 1'b0;
                                       trainerror_flag <= 1'b0;    

                                    end else if( flag ) begin
                                      flag <= 0;
                                      // data_out_mp = {Start Tx Init D to C point test resp}
                                      data_out_mp <= { 1'b0 ,1'b0 , DATA_IN_reg[61:56] , 16'h0000 , 8'h01 , DATA_IN_reg[31:22] , 8'h8A , DATA_IN_reg[13:5] , 5'b10010 }; 
                                      encoder_en_mp <= 1'b1;
                                      sb_exit_mp <= 1'b0;
                                      trainerror_hs_mp <= 1'b0;
                                      flag_sb <= 0;
                                      test_resp_mp <= 1'b0;
                                      trainerror_flag <= 1'b0;    

                                   // data_in = {LFSR_clear_error req}
                                   end else if( (data_in[21:14] == 8'h85) && (data_in[39:32] == 8'h02) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                      // data_out_mp = {LFSR_clear_error resp}
                                      data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h02 , data_in[31:22] , 8'h8A , data_in[13:0] }; 
                                      encoder_en_mp <= 1'b1;
                                      sb_exit_mp <= 1'b0;
                                      trainerror_hs_mp <= 1'b0;
                                      flag_sb <= 0;
                                      flag_2 <= 0;
                                      flag <= 0; 
                                      test_resp_mp <= 1'b1;
                                      trainerror_flag <= 1'b0;    

                                    // data_in = {Tx Init D to C results req}
                                    end else if( (data_in[21:14] == 8'h85) && (data_in[39:32] == 8'h03) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                             
                                        // data_out_mp = {Tx Init D to C results resp}
                                        if (failed) begin    // valid test failed "valid bit is 0"
                                          data_out_mp <= { 1'b0 ,1'b0 , data_in[61:46] , 1'b0 , data_in[44:40] , 8'h03 , data_in[31:22] , 8'h8A , data_in[13:5] , 5'b11011 }; 
                                          encoder_en_mp <= 1'b1;
                                          sb_exit_mp <= 1'b0;
                                          trainerror_hs_mp <= 1'b0;
                                          flag <= 0;
                                          flag_2 <= 1;    // to send the remainig data part of the resp in the next cycle 
                                          flag_sb <= 0;
                                          test_resp_mp <= 1'b0;
                                          trainerror_flag <= 1'b0;    
                                        end else begin    // valid test passed "valid bit is 1"
                                          data_out_mp <= { 1'b0 ,1'b0 , data_in[61:46] , 1'b1 , data_in[44:40] , 8'h03 , data_in[31:22] , 8'h8A , data_in[13:5] , 5'b11011 }; 
                                          encoder_en_mp <= 1'b1;
                                          sb_exit_mp <= 1'b0;
                                          trainerror_hs_mp <= 1'b0;
                                          flag <= 0;
                                          flag_2 <= 1;
                                          flag_sb <= 0;
                                          test_resp_mp <= 1'b0;
                                          trainerror_flag <= 1'b0;    
                                        end 

                                   // data_in =  {End Tx Init D to C point test req}
                                   end else if( (data_in[21:14] == 8'h85) && (data_in[39:32] == 8'h04) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                     // data_out_mp = {End Tx Init D to C point test resp}
                                     data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h04 , data_in[31:22] , 8'h8A , data_in[13:0] }; 
                                     encoder_en_mp <= 1'b1;
                                     sb_exit_mp <= 1'b0;
                                     trainerror_hs_mp <= 1'b0;
                                     flag <= 0;
                                     flag_sb <= 0;
                                     test_resp_mp <= 1'b0;
                                     trainerror_flag <= 1'b0;    

                                   // data_in = {MBTRAIN.VALTRAINCENTER done req}
                                   end else if( (data_in[21:14] == 8'hB5) && (data_in[39:32] == 8'h09) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                      // data_in = {MBTRAIN.VALTRAINCENTER done resp}
                                      data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h09 , data_in[31:22] , 8'hBA , data_in[13:0] }; 
                                      encoder_en_mp <= 1'b1;
                                      trainerror_hs_mp <= 1'b0;
                                      flag <= 0;
                                      test_resp_mp <= 1'b0;
                                      trainerror_flag <= 1'b0;    
                                      if(sb_exit_m) begin     // to wait for module sb_exit_mp signal
                                        sb_exit_mp <= 1'b1;
                                        flag_sb <= 0;
                                      end else begin
                                        sb_exit_mp <= 1'b0;
                                        flag_sb <= 1;
                                      end

                                   end else begin
                                       data_out_mp <= 64'b0;
                                       trainerror_flag <= 1'b1;
                                       encoder_en_mp <= 1'b0;
                                       sb_exit_mp <= 1'b0;
                                       trainerror_hs_mp <= 1'b0;
                                       flag <= 0;
                                       flag_sb <= 0;
                                       test_resp_mp <= 1'b0;
                                    end

                  end 
  
		  VALTRAINVREF: begin
                                   // data_in = {TRAINERROR Entry req}
                                   if( (data_in[21:14] == 8'hE5) && (data_in[39:32] == 8'h00) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                      // data_out_mp = {TRAINERROR Entry resp}
                                      data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h00 , data_in[31:22] , 8'hEA , data_in[13:0] }; 
                                      encoder_en_mp <= 1'b1;
                                      sb_exit_mp <= 1'b0;
                                      start_mb_mp <= 1'b0;
                                      trainerror_hs_mp <= 1'b1;
                                      flag <= 0;
                                      flag_sb <= 0;
                                      flag_mb <= 0;
                                      trainerror_flag <= 1'b0;    

                                   // data_in = {MBTRAIN.VALTRAINVREF start req}
                                   end else if( (data_in[21:14] == 8'hB5) && (data_in[39:32] == 8'h0A) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                      // data_out_mp = {MBTRAIN.VALTRAINVREF start resp}
                                      data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h0A , data_in[31:22] , 8'hBA , data_in[13:0] }; 
                                      encoder_en_mp <= 1'b1;
                                      sb_exit_mp <= 1'b0;
                                      start_mb_mp <= 1'b0;
                                      trainerror_hs_mp <= 1'b0;
                                      flag <= 0;
                                      flag_sb <= 0;
                                      flag_mb <= 0;
                                      trainerror_flag <= 1'b0;    

                                   // data_in = {Start Rx Init D to C point test req}
                                   end else if( (data_in[21:14] == 8'h85) && (data_in[39:32] == 8'h07) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                     flag <= 1;  // to wait for the 64 bit of data 
                                     DATA_IN_reg <= data_in;       //storing the msg 
                                     flag_sb <= 0;
                                     flag_mb <= 0;
                                     data_out_mp <= 64'b0;
                                     encoder_en_mp <= 1'b0;
                                     sb_exit_mp <= 1'b0;
                                     start_mb_mp <= 1'b0;
                                     trainerror_hs_mp <= 1'b0;
                                     trainerror_flag <= 1'b0;    

                                   end else if( flag ) begin
                                     flag <= 0;
                                     // data_out_mp = {Start Rx Init D to C point test resp}
                                     data_out_mp <= { 1'b0 ,1'b0 , DATA_IN_reg[61:56] , 16'h0000 , 8'h07 , DATA_IN_reg[31:22] , 8'h8A , DATA_IN_reg[13:5] , 5'b10010 }; 
                                     encoder_en_mp <= 1'b1;
                                     sb_exit_mp <= 1'b0;
                                     start_mb_mp <= 1'b0;
                                     trainerror_hs_mp <= 1'b0;
                                     flag_sb <= 0;
                                     flag_mb <= 0;
                                     trainerror_flag <= 1'b0;    

                                // data_in = {LFSR_clear_error req}
                                end else if( (data_in[21:14] == 8'h85) && (data_in[39:32] == 8'h02) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                    // data_out_mp = {LFSR_clear_error resp}
                                    data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h02 , data_in[31:22] , 8'h8A , data_in[13:0] }; 
                                    encoder_en_mp <= 1'b1;
                                    sb_exit_mp <= 1'b0;
                                    start_mb_mp <= 1'b1;
                                    flag_mb <= 1;
                                    flag_sb <= 0;
                                    flag <= 0; 
                                    trainerror_flag <= 1'b0;    

                                  // data_in = {Rx Init D to C Tx Count Done resp}
                                  end else if( (data_in[21:14] == 8'h8A) && (data_in[39:32] == 8'h08) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                    // data_out_mp
                                    data_out_mp <= 64'b0;
                                    encoder_en_mp <= 1'b0;
                                    sb_exit_mp <= 1'b0;
                                    start_mb_mp <= 1'b0;
                                    trainerror_hs_mp <= 1'b0; 
                                    flag <= 0;
                                    flag_sb <= 0;
                                    flag_mb <= 0;
                                    trainerror_flag <= 1'b0;    

                                  // data_in =  {End Rx Init D to C point test req}
                                  end else if( (data_in[21:14] == 8'h85) && (data_in[39:32] == 8'h09) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                   // data_out_mp =  {End Rx Init D to C point test resp}
                                   data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h09 , data_in[31:22] , 8'h8A , data_in[13:0] }; 
                                   encoder_en_mp <= 1'b1;
                                   sb_exit_mp <= 1'b0;
                                   start_mb_mp <= 1'b0;
                                   trainerror_hs_mp <= 1'b0;
                                   flag <= 0;
                                   flag_sb <= 0;
                                   flag_mb <= 0;
                                   trainerror_flag <= 1'b0;    

                                 // data_in =  {MBTRAIN.VALTRAINVREF done req}
                                 end else if( (data_in[21:14] == 8'hB5) && (data_in[39:32] == 8'h0B) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                   // data_out_mp = {MBTRAIN.VALTRAINVREF done resp}
                                   data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h0B , data_in[31:22] , 8'hBA , data_in[13:0] }; 
                                   encoder_en_mp <= 1'b1;
                                   start_mb_mp <= 1'b0;
                                   trainerror_hs_mp <= 1'b0;
                                   flag <= 0;
                                   flag_mb <= 0;
                                   trainerror_flag <= 1'b0;    
                                   if(sb_exit_m) begin     // to wait for module sb_exit_mp signal
                                     sb_exit_mp <= 1'b1;
                                     flag_sb <= 0;
                                   end else begin
                                     sb_exit_mp <= 1'b0;
                                     flag_sb <= 1;
                                   end

                                 end else begin
                                    data_out_mp <= 64'b0;
                                    trainerror_flag <= 1'b1;
                                    encoder_en_mp <= 1'b0;
                                    sb_exit_mp <= 1'b0;
                                    start_mb_mp <= 1'b0;
                                    trainerror_hs_mp <= 1'b0;
                                    flag <= 0;
                                    flag_sb <= 0;
                                    flag_mb <= 0;
                                 end

                  end  

		  DATATRAINCENTER1: begin
                                      // data_in = {TRAINERROR Entry req}
                                      if( (data_in[21:14] == 8'hE5) && (data_in[39:32] == 8'h00) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                        // data_out_mp = {TRAINERROR Entry resp}
                                        data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h00 , data_in[31:22] , 8'hEA , data_in[13:0] }; 
                                        encoder_en_mp <= 1'b1;
                                        sb_exit_mp <= 1'b0;
                                        trainerror_hs_mp <= 1'b1;
                                        flag_sb <= 0;
                                        test_resp_mp <= 1'b0;
                                        trainerror_flag <= 1'b0;    

                                      // data_in = {MBTRAIN.DATATRAINCENTER1 start req}
                                      end else if( (data_in[21:14] == 8'hB5) && (data_in[39:32] == 8'h0C) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                        // data_out_mp = {MBTRAIN.DATATRAINCENTER1 start resp}
                                        data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h0C , data_in[31:22] , 8'hBA , data_in[13:0] }; 
                                        encoder_en_mp <= 1'b1;
                                        sb_exit_mp <= 1'b0;
                                        trainerror_hs_mp <= 1'b0;
                                        flag_sb <= 0;
                                        test_resp_mp <= 1'b0;
                                        trainerror_flag <= 1'b0;    

                                      // data_in = {Start Tx Init D to C point test req}
                                      end else if( (data_in[21:14] == 8'h85) && (data_in[39:32] == 8'h01) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                        flag <= 1;  // to wait for the 64 bit of data 
                                        error_threshold <= data_in[55:40];
                                        DATA_IN_reg <= data_in;       //storing the msg 
                                        flag_sb <= 0;
                                        test_resp_mp <= 1'b0;
                                        data_out_mp <= 64'b0;
                                        encoder_en_mp <= 1'b0;
                                        sb_exit_mp <= 1'b0;
                                        trainerror_hs_mp <= 1'b0;
                                        trainerror_flag <= 1'b0;    

                                      end else if( flag ) begin
                                        flag <= 0;
                                        // data_out_mp = {Start Tx Init D to C point test resp}
                                        data_out_mp <= { 1'b0 ,1'b0 , DATA_IN_reg[61:56] , 16'h0000 , 8'h01 , DATA_IN_reg[31:22] , 8'h8A , DATA_IN_reg[13:5] , 5'b10010 }; 
                                        encoder_en_mp <= 1'b1;
                                        sb_exit_mp <= 1'b0;
                                        trainerror_hs_mp <= 1'b0;
                                        flag_sb <= 0;
                                        test_resp_mp <= 1'b0;
                                        trainerror_flag <= 1'b0;    

                                     // data_in = {LFSR_clear_error req}
                                     end else if( (data_in[21:14] == 8'h85) && (data_in[39:32] == 8'h02) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                        // data_out_mp = {LFSR_clear_error resp}
                                        data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h02 , data_in[31:22] , 8'h8A , data_in[13:0] }; 
                                        encoder_en_mp <= 1'b1;
                                        sb_exit_mp <= 1'b0;
                                        trainerror_hs_mp <= 1'b0;
                                        flag_sb <= 0;
                                        flag_2 <= 0;
                                        flag <= 0; 
                                        test_resp_mp <= 1'b1;
                                        trainerror_flag <= 1'b0;    

                                      // data_in = {Tx Init D to C results req}
                                      end else if( (data_in[21:14] == 8'h85) && (data_in[39:32] == 8'h03) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                          // data_out_mp = {Tx Init D to C results resp}
                                          // LFSR test passed "status bit is 1"    // LFSR test failed "status bit is 0"
                                          data_out_mp <= { 1'b0 ,1'b0 , data_in[61:45] , status , data_in[43:40] , 8'h03 , data_in[31:22] , 8'h8A , data_in[13:5] , 5'b11011 }; 
                                          encoder_en_mp <= 1'b1;
                                          sb_exit_mp <= 1'b0;
                                          trainerror_hs_mp <= 1'b0;
                                          flag <= 0;
                                          flag_2 <= 1;    // to send the remainig data part of the resp in the next cycle 
                                          flag_sb <= 0;
                                          test_resp_mp <= 1'b0;
                                          trainerror_flag <= 1'b0;    

                                      // data_in =  {End Tx Init D to C point test req}
                                      end else if( (data_in[21:14] == 8'h85) && (data_in[39:32] == 8'h04) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                        // data_out_mp = {End Tx Init D to C point test resp}
                                        data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h04 , data_in[31:22] , 8'h8A , data_in[13:0] }; 
                                        encoder_en_mp <= 1'b1;
                                        sb_exit_mp <= 1'b0;
                                        trainerror_hs_mp <= 1'b0;
                                        flag <= 0;
                                        flag_sb <= 0;
                                        test_resp_mp <= 1'b0;
                                        trainerror_flag <= 1'b0;    

                                       // data_in = {MBTRAIN.DATATRAINCENTER1 end req}
                                       end else if( (data_in[21:14] == 8'hB5) && (data_in[39:32] == 8'h0D) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                         // data_out_mp = {MBTRAIN.DATATRAINCENTER1 end resp}
                                         data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h0D , data_in[31:22] , 8'hBA , data_in[13:0] }; 
                                         encoder_en_mp <= 1'b1;
                                         trainerror_hs_mp <= 1'b0;
                                         flag <= 0;
                                         test_resp_mp <= 1'b0;
                                         trainerror_flag <= 1'b0;    
                                         if(sb_exit_m) begin     // to wait for module sb_exit_mp signal
                                           sb_exit_mp <= 1'b1;
                                           flag_sb <= 0;
                                         end else begin
                                           sb_exit_mp <= 1'b0;
                                           flag_sb <= 1;
                                         end

                                       end else begin
                                          data_out_mp <= 64'b0;
                                          trainerror_flag <= 1'b1;
                                          encoder_en_mp <= 1'b0;
                                          sb_exit_mp <= 1'b0;
                                          trainerror_hs_mp <= 1'b0;
                                          flag <= 0;
                                          flag_sb <= 0;
                                          test_resp_mp <= 1'b0;
                                       end

                  end

		  DATATRAINVREF: begin
                                    // data_in = {TRAINERROR Entry req}
                                    if( (data_in[21:14] == 8'hE5) && (data_in[39:32] == 8'h00) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                      // data_out_mp = {TRAINERROR Entry resp}
                                      data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h00 , data_in[31:22] , 8'hEA , data_in[13:0] }; 
                                      encoder_en_mp <= 1'b1;
                                      sb_exit_mp <= 1'b0;
                                      start_mb_mp <= 1'b0;
                                      trainerror_hs_mp <= 1'b1;
                                      flag <= 0;
                                      flag_sb <= 0;
                                      flag_mb <= 0;
                                      trainerror_flag <= 1'b0;    

                                     // data_in = {MBTRAIN.DATATRAINVREF start req}
                                     end else if( (data_in[21:14] == 8'hB5) && (data_in[39:32] == 8'h0E) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                        // data_out_mp = {MBTRAIN.DATATRAINVREF start resp}
                                        data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h0E , data_in[31:22] , 8'hBA , data_in[13:0] }; 
                                        encoder_en_mp <= 1'b1;
                                        sb_exit_mp <= 1'b0;
                                        start_mb_mp <= 1'b0;
                                        trainerror_hs_mp <= 1'b0;
                                        flag <= 0;
                                        flag_sb <= 0;
                                        flag_mb <= 0;
                                        trainerror_flag <= 1'b0;    

                                     // data_in = {Start Rx Init D to C point test req}
                                     end else if( (data_in[21:14] == 8'h85) && (data_in[39:32] == 8'h07) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                       flag <= 1;  // to wait for the 64 bit of data 
                                       DATA_IN_reg <= data_in;       //storing the msg 
                                       flag_sb <= 0;
                                       flag_mb <= 0;
                                       data_out_mp <= 64'b0;
                                       encoder_en_mp <= 1'b0;
                                       sb_exit_mp <= 1'b0;
                                       start_mb_mp <= 1'b0;
                                       trainerror_hs_mp <= 1'b0;
                                       trainerror_flag <= 1'b0;    

                                     end else if( flag ) begin
                                       flag <= 0;
                                       // data_out_mp = {Start Rx Init D to C point test resp}
                                       data_out_mp <= { 1'b0 ,1'b0 , DATA_IN_reg[61:56] , 16'h0000 , 8'h07 , DATA_IN_reg[31:22] , 8'h8A , DATA_IN_reg[13:5] , 5'b10010 }; 
                                       encoder_en_mp <= 1'b1;
                                       sb_exit_mp <= 1'b0;
                                       start_mb_mp <= 1'b0;
                                       trainerror_hs_mp <= 1'b0;
                                       flag_sb <= 0;
                                       flag_mb <= 0;
                                       trainerror_flag <= 1'b0;    

                                   // data_in = {LFSR_clear_error req}
                                   end else if( (data_in[21:14] == 8'h85) && (data_in[39:32] == 8'h02) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                      // data_out_mp = {LFSR_clear_error resp}
                                      data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h02 , data_in[31:22] , 8'h8A , data_in[13:0] }; 
                                      encoder_en_mp <= 1'b1;
                                      sb_exit_mp <= 1'b0;
                                      start_mb_mp <= 1'b1;
                                      flag_mb <= 1;
                                      flag_sb <= 0;
                                      flag <= 0; 
                                      trainerror_flag <= 1'b0;    

                                   // data_in = {Rx Init D to C Tx Count Done resp}
                                   end else if( (data_in[21:14] == 8'h8A) && (data_in[39:32] == 8'h08) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                      // data_out_mp
                                      data_out_mp <= 64'b0;
                                      encoder_en_mp <= 1'b0;
                                      sb_exit_mp <= 1'b0;
                                      start_mb_mp <= 1'b0;
                                      trainerror_hs_mp <= 1'b0; 
                                      flag <= 0;
                                      flag_sb <= 0;
                                      flag_mb <= 0;
                                      trainerror_flag <= 1'b0;    

                                   // data_in =  {End Rx Init D to C point test req}
                                   end else if( (data_in[21:14] == 8'h85) && (data_in[39:32] == 8'h09) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                      // data_out_mp =  {End Rx Init D to C point test resp}
                                      data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h09 , data_in[31:22] , 8'h8A , data_in[13:0] }; 
                                      encoder_en_mp <= 1'b1;
                                      sb_exit_mp <= 1'b0;
                                      start_mb_mp <= 1'b0;
                                      trainerror_hs_mp <= 1'b0;
                                      flag <= 0;
                                      flag_sb <= 0;
                                      flag_mb <= 0;
                                      trainerror_flag <= 1'b0;    

                                    // data_in = {MBTRAIN.DATATRAINVREF end req}
                                    end else if( (data_in[21:14] == 8'hB5) && (data_in[39:32] == 8'h10) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                       // data_out_mp = {MBTRAIN.DATATRAINVREF end resp}
                                       data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h10 , data_in[31:22] , 8'hBA , data_in[13:0] }; 
                                       encoder_en_mp <= 1'b1;
                                       start_mb_mp <= 1'b0;
                                       trainerror_hs_mp <= 1'b0;
                                       flag <= 0;
                                       flag_mb <= 0;
                                       trainerror_flag <= 1'b0;    
                                       if(sb_exit_m) begin     // to wait for module sb_exit_mp signal
                                           sb_exit_mp <= 1'b1;
                                           flag_sb <= 0;
                                       end else begin
                                           sb_exit_mp <= 1'b0;
                                           flag_sb <= 1;
                                       end

                                     end else begin
                                        data_out_mp <= 64'b0;
                                        trainerror_flag <= 1'b1;
                                        encoder_en_mp <= 1'b0;
                                        sb_exit_mp <= 1'b0;
                                        start_mb_mp <= 1'b0;
                                        trainerror_hs_mp <= 1'b0;
                                        flag <= 0;
                                        flag_sb <= 0;
                                        flag_mb <= 0;
                                     end

                  end

		  RXDESKEW: begin
                            // data_in = {TRAINERROR Entry req}
                            if( (data_in[21:14] == 8'hE5) && (data_in[39:32] == 8'h00) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                // data_out_mp = {TRAINERROR Entry resp}
                                data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h00 , data_in[31:22] , 8'hEA , data_in[13:0] }; 
                                encoder_en_mp <= 1'b1;
                                sb_exit_mp <= 1'b0;
                                start_mb_mp <= 1'b0;
                                trainerror_hs_mp <= 1'b1;
                                flag <= 0;
                                flag_sb <= 0;
                                flag_mb <= 0;
                                trainerror_flag <= 1'b0;    

                             // data_in = {MBTRAIN.RXDESKEW start req}
                             end else if( (data_in[21:14] == 8'hB5) && (data_in[39:32] == 8'h11) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                // data_out_mp = {MBTRAIN.RXDESKEW start resp}
                                data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h11 , data_in[31:22] , 8'hBA , data_in[13:0] }; 
                                encoder_en_mp <= 1'b1;
                                sb_exit_mp <= 1'b0;
                                start_mb_mp <= 1'b0;
                                trainerror_hs_mp <= 1'b0;
                                flag <= 0;
                                flag_sb <= 0;
                                flag_mb <= 0;
                                trainerror_flag <= 1'b0;    

                             // data_in = {Start Rx Init D to C point test req}
                             end else if( (data_in[21:14] == 8'h85) && (data_in[39:32] == 8'h07) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                 flag <= 1;  // to wait for the 64 bit of data of the msg req
                                 DATA_IN_reg <= data_in;       //storing the msg 
                                 flag_sb <= 0;
                                 flag_mb <= 0;
                                 data_out_mp <= 64'b0;
                                 encoder_en_mp <= 1'b0;
                                 sb_exit_mp <= 1'b0;
                                 start_mb_mp <= 1'b0;
                                 trainerror_hs_mp <= 1'b0;
                                 trainerror_flag <= 1'b0;    

                             end else if( flag ) begin
                                 flag <= 0;
                                 // data_out_mp = {Start Rx Init D to C point test resp}
                                 data_out_mp <= { 1'b0 ,1'b0 , DATA_IN_reg[61:56] , 16'h0000 , 8'h07 , DATA_IN_reg[31:22] , 8'h8A , DATA_IN_reg[13:5] , 5'b10010 }; 
                                 encoder_en_mp <= 1'b1;
                                 sb_exit_mp <= 1'b0;
                                 start_mb_mp <= 1'b0;
                                 trainerror_hs_mp <= 1'b0;
                                 flag_sb <= 0;
                                 flag_mb <= 0;
                                 trainerror_flag <= 1'b0;    

                              // data_in = {LFSR_clear_error req}
                              end else if( (data_in[21:14] == 8'h85) && (data_in[39:32] == 8'h02) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                 // data_out_mp = {LFSR_clear_error resp}
                                 data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h02 , data_in[31:22] , 8'h8A , data_in[13:0] }; 
                                 encoder_en_mp <= 1'b1;
                                 sb_exit_mp <= 1'b0;
                                 start_mb_mp <= 1'b1;
                                 flag_mb <= 1;
                                 flag_sb <= 0;
                                 flag <= 0; 
                                 trainerror_flag <= 1'b0;    

                              // data_in = {Rx Init D to C Tx Count Done resp}
                              end else if( (data_in[21:14] == 8'h8A) && (data_in[39:32] == 8'h08) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                  // data_out_mp
                                  data_out_mp <= 64'b0;
                                  encoder_en_mp <= 1'b0;
                                  sb_exit_mp <= 1'b0;
                                  start_mb_mp <= 1'b0;
                                  trainerror_hs_mp <= 1'b0; 
                                  flag <= 0;
                                  flag_sb <= 0;
                                  flag_mb <= 0;
                                  trainerror_flag <= 1'b0;    

                              // data_in =  {End Rx Init D to C point test req}
                              end else if( (data_in[21:14] == 8'h85) && (data_in[39:32] == 8'h09) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                  // data_out_mp =  {End Rx Init D to C point test resp}
                                  data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h09 , data_in[31:22] , 8'h8A , data_in[13:0] }; 
                                  encoder_en_mp <= 1'b1;
                                  sb_exit_mp <= 1'b0;
                                  start_mb_mp <= 1'b0;
                                  trainerror_hs_mp <= 1'b0;
                                  flag <= 0;
                                  flag_sb <= 0;
                                  flag_mb <= 0;
                                  trainerror_flag <= 1'b0;    

                             // data_in = {MBTRAIN.RXDESKEW end req}
                             end else if( (data_in[21:14] == 8'hB5) && (data_in[39:32] == 8'h12) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                // data_out_mp = {MBTRAIN.RXDESKEW end resp}
                                data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h12 , data_in[31:22] , 8'hBA , data_in[13:0] }; 
                                encoder_en_mp <= 1'b1;
                                start_mb_mp <= 1'b0;
                                trainerror_hs_mp <= 1'b0;
                                flag <= 0;
                                flag_mb <= 0;
                                trainerror_flag <= 1'b0;    
                                if(sb_exit_m) begin     // to wait for module sb_exit_mp signal
                                  sb_exit_mp <= 1'b1;
                                  flag_sb <= 0;
                                end else begin
                                  sb_exit_mp <= 1'b0;
                                  flag_sb <= 1;
                                end

                              end else begin
                                 data_out_mp <= 64'b0;
                                 trainerror_flag <= 1'b1;
                                 encoder_en_mp <= 1'b0;
                                 sb_exit_mp <= 1'b0;
                                 start_mb_mp <= 1'b0;
                                 trainerror_hs_mp <= 1'b0;
                                 flag <= 0;
                                 flag_sb <= 0;
                                 flag_mb <= 0;
                              end

                  end

		  DATATRAINCENTER2: begin
                                     // data_in = {TRAINERROR Entry req}
                                     if( (data_in[21:14] == 8'hE5) && (data_in[39:32] == 8'h00) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                       // data_out_mp = {TRAINERROR Entry resp}
                                       data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h00 , data_in[31:22] , 8'hEA , data_in[13:0] }; 
                                       encoder_en_mp <= 1'b1;
                                       sb_exit_mp <= 1'b0;
                                       trainerror_hs_mp <= 1'b1;
                                       flag <= 0;
                                       flag_sb <= 0;
                                       test_resp_mp <= 1'b0;
                                       trainerror_flag <= 1'b0;    

                                     // data_in = {MBTRAIN.DATATRAINCENTER2 start req}
                                     end else if( (data_in[21:14] == 8'hB5) && (data_in[39:32] == 8'h13) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                       // data_out_mp = {MBTRAIN.DATATRAINCENTER2 start resp}
                                       data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h13 , data_in[31:22] , 8'hBA , data_in[13:0] }; 
                                       encoder_en_mp <= 1'b1;
                                       sb_exit_mp <= 1'b0;
                                       trainerror_hs_mp <= 1'b0;
                                       flag <= 0;
                                       flag_sb <= 0;
                                       test_resp_mp <= 1'b0;
                                       trainerror_flag <= 1'b0;    

                                     // data_in = {Start Tx Init D to C point test req}
                                      end else if( (data_in[21:14] == 8'h85) && (data_in[39:32] == 8'h01) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                        flag <= 1;  // to wait for the 64 bit of data 
                                        error_threshold <= data_in[55:40];
                                        DATA_IN_reg <= data_in;       //storing the msg 
                                        flag_sb <= 0;
                                        test_resp_mp <= 1'b0;
                                        data_out_mp <= 64'b0;
                                        encoder_en_mp <= 1'b0;
                                        sb_exit_mp <= 1'b0;
                                        trainerror_hs_mp <= 1'b0;
                                        trainerror_flag <= 1'b0;    

                                      end else if( flag ) begin
                                        flag <= 0;
                                        // data_out_mp = {Start Tx Init D to C point test resp}
                                        data_out_mp <= { 1'b0 ,1'b0 , DATA_IN_reg[61:56] , 16'h0000 , 8'h01 , DATA_IN_reg[31:22] , 8'h8A , DATA_IN_reg[13:5] , 5'b10010 }; 
                                        encoder_en_mp <= 1'b1;
                                        sb_exit_mp <= 1'b0;
                                        trainerror_hs_mp <= 1'b0;
                                        flag_sb <= 0;
                                        test_resp_mp <= 1'b0;
                                        trainerror_flag <= 1'b0;    

                                     // data_in = {LFSR_clear_error req}
                                     end else if( (data_in[21:14] == 8'h85) && (data_in[39:32] == 8'h02) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                        // data_out_mp = {LFSR_clear_error resp}
                                        data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h02 , data_in[31:22] , 8'h8A , data_in[13:0] }; 
                                        encoder_en_mp <= 1'b1;
                                        sb_exit_mp <= 1'b0;
                                        trainerror_hs_mp <= 1'b0;
                                        flag_sb <= 0;
                                        flag_2 <= 0;
                                        flag <= 0;
                                        test_resp_mp <= 1'b1;
                                        trainerror_flag <= 1'b0;    

                                      // data_in = {Tx Init D to C results req}
                                      end else if( (data_in[21:14] == 8'h85) && (data_in[39:32] == 8'h03) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                          // data_out_mp = {Tx Init D to C results resp}
                                          // LFSR test passed "status bit is 1"    // LFSR test failed "status bit is 0"
                                          data_out_mp <= { 1'b0 ,1'b0 , data_in[61:45] , status , data_in[43:40] , 8'h03 , data_in[31:22] , 8'h8A , data_in[13:5] , 5'b11011 }; 
                                          encoder_en_mp <= 1'b1;
                                          sb_exit_mp <= 1'b0;
                                          trainerror_hs_mp <= 1'b0;
                                          flag <= 0;
                                          flag_2 <= 1;    // to send the remainig data part of the resp in the next cycle
                                          flag_sb <= 0;
                                          test_resp_mp <= 1'b0;
                                          trainerror_flag <= 1'b0;    

                                      // data_in =  {End Tx Init D to C point test req}
                                      end else if( (data_in[21:14] == 8'h85) && (data_in[39:32] == 8'h04) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                        // data_out_mp = {End Tx Init D to C point test resp}
                                        data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h04 , data_in[31:22] , 8'h8A , data_in[13:0] }; 
                                        encoder_en_mp <= 1'b1;
                                        sb_exit_mp <= 1'b0;
                                        trainerror_hs_mp <= 1'b0;
                                        flag <= 0;
                                        flag_sb <= 0;
                                        test_resp_mp <= 1'b0;
                                        trainerror_flag <= 1'b0;    

                                     // data_in = {MBTRAIN.DATATRAINCENTER2 end req}
                                     end else if( (data_in[21:14] == 8'hB5) && (data_in[39:32] == 8'h14) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                        // data_out_mp = {MBTRAIN.DATATRAINCENTER2 end resp}
                                        data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h14 , data_in[31:22] , 8'hBA , data_in[13:0] }; 
                                        encoder_en_mp <= 1'b1;
                                        trainerror_hs_mp <= 1'b0;
                                        flag <= 0;
                                        test_resp_mp <= 1'b0;
                                        trainerror_flag <= 1'b0;    
                                        if(sb_exit_m) begin     // to wait for module sb_exit_mp signal
                                           sb_exit_mp <= 1'b1;
                                           flag_sb <= 0;
                                        end else begin
                                           sb_exit_mp <= 1'b0;
                                           flag_sb <= 1;
                                        end

                                     end else begin
                                        data_out_mp <= 64'b0;
                                        trainerror_flag <= 1'b1;
                                        encoder_en_mp <= 1'b0;
                                        sb_exit_mp <= 1'b0;
                                        trainerror_hs_mp <= 1'b0;
                                        flag <= 0;
                                        flag_sb <= 0;
                                        test_resp_mp <= 1'b0;
                                     end

                  end

		  LINKSPEED: begin
                              // data_in = {TRAINERROR Entry req}
                              if( (data_in[21:14] == 8'hE5) && (data_in[39:32] == 8'h00) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                // data_out_mp = {TRAINERROR Entry resp}
                                data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h00 , data_in[31:22] , 8'hEA , data_in[13:0] }; 
                                encoder_en_mp <= 1'b1;
                                sb_exit_mp <= 1'b0;
                                trainerror_hs_mp <= 1'b1;
                                flag <= 0;
                                speed_idle_req_mp <= 1'b0;
                                repair_req_mp <= 1'b0;
                                flag_sb <= 0;
                                test_resp_mp <= 1'b0;
                                trainerror_flag <= 1'b0;    

                              // data_in = {MBTRAIN.LINKSPEED start req}
                              end else if( (data_in[21:14] == 8'hB5) && (data_in[39:32] == 8'h15) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                  // data_out_mp = {MBTRAIN.LINKSPEED start resp}
                                   data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h15 , data_in[31:22] , 8'hBA , data_in[13:0] }; 
                                   encoder_en_mp <= 1'b1;
                                   sb_exit_mp <= 1'b0;
                                   trainerror_hs_mp <= 1'b0;
                                   flag <= 0;
                                   speed_idle_req_mp <= 1'b0;
                                   repair_req_mp <= 1'b0;
                                   flag_sb <= 0;
                                   test_resp_mp <= 1'b0;
                                   trainerror_flag <= 1'b0;    

                              // data_in = {Start Tx Init D to C point test req}
                              end else if( (data_in[21:14] == 8'h85) && (data_in[39:32] == 8'h01) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                  flag <= 1;  // to wait for the 64 bit of data 
                                  error_threshold <= data_in[55:40];
                                  DATA_IN_reg <= data_in;       //storing the msg 
                                  speed_idle_req_mp <= 1'b0;
                                  repair_req_mp <= 1'b0;
                                  flag_sb <= 0;
                                  test_resp_mp <= 1'b0;
                                  data_out_mp <= 64'b0;
                                  encoder_en_mp <= 1'b0;
                                  sb_exit_mp <= 1'b0;
                                  trainerror_hs_mp <= 1'b0;
                                  trainerror_flag <= 1'b0;    

                               end else if( flag ) begin
                                   flag <= 0;
                                   // data_out_mp = {Start Tx Init D to C point test resp}
                                   data_out_mp <= { 1'b0 ,1'b0 , DATA_IN_reg[61:56] , 16'h0000 , 8'h01 , DATA_IN_reg[31:22] , 8'h8A , DATA_IN_reg[13:5] , 5'b10010 }; 
                                   encoder_en_mp <= 1'b1;
                                   sb_exit_mp <= 1'b0;
                                   trainerror_hs_mp <= 1'b0;
                                   speed_idle_req_mp <= 1'b0;
                                   repair_req_mp <= 1'b0;
                                   flag_sb <= 0;
                                   test_resp_mp <= 1'b0;
                                   trainerror_flag <= 1'b0;    

                               // data_in = {LFSR_clear_error req}
                               end else if( (data_in[21:14] == 8'h85) && (data_in[39:32] == 8'h02) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                   // data_out_mp = {LFSR_clear_error resp}
                                   data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h02 , data_in[31:22] , 8'h8A , data_in[13:0] }; 
                                   encoder_en_mp <= 1'b1;
                                   sb_exit_mp <= 1'b0;
                                   trainerror_hs_mp <= 1'b0;
                                   speed_idle_req_mp <= 1'b0;
                                   repair_req_mp <= 1'b0;
                                   flag_sb <= 0;
                                   flag_2 <= 0;
                                   flag <= 0;
                                   test_resp_mp <= 1'b1;
                                   trainerror_flag <= 1'b0;    

                                // data_in = {Tx Init D to C results req}
                                end else if( (data_in[21:14] == 8'h85) && (data_in[39:32] == 8'h03) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                    // data_out_mp = {Tx Init D to C results resp}
                                    // LFSR test passed "status bit is 1"    // LFSR test failed "status bit is 0"
                                    data_out_mp <= { 1'b0 ,1'b0 , data_in[61:45] , status , data_in[43:40] , 8'h03 , data_in[31:22] , 8'h8A , data_in[13:5] , 5'b11011 }; 
                                    encoder_en_mp <= 1'b1;
                                    sb_exit_mp <= 1'b0;
                                    trainerror_hs_mp <= 1'b0;
                                    flag <= 0;
                                    flag_2 <= 1;    // to send the remainig data part of the resp in the next cycle
                                    speed_idle_req_mp <= 1'b0;
                                    repair_req_mp <= 1'b0;
                                    flag_sb <= 0;
                                    test_resp_mp <= 1'b0;
                                    trainerror_flag <= 1'b0;    

                                 // data_in =  {End Tx Init D to C point test req}
                                 end else if( (data_in[21:14] == 8'h85) && (data_in[39:32] == 8'h04) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                     // data_out_mp = {End Tx Init D to C point test resp}
                                     data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h04 , data_in[31:22] , 8'h8A , data_in[13:0] }; 
                                     encoder_en_mp <= 1'b1;
                                     sb_exit_mp <= 1'b0;
                                     trainerror_hs_mp <= 1'b0;
                                     flag <= 0;
                                     speed_idle_req_mp <= 1'b0;
                                     repair_req_mp <= 1'b0;  
                                     flag_sb <= 0;
                                     test_resp_mp <= 1'b0;
                                     trainerror_flag <= 1'b0;    

                                 // data_in = {MBTRAIN.LINKSPEED error req}
                                 end else if( (data_in[21:14] == 8'hB5) && (data_in[39:32] == 8'h16) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                     // data_out_mp = {MBTRAIN.LINKSPEED error resp}
                                     data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h16 , data_in[31:22] , 8'hBA , data_in[13:0] }; 
                                     encoder_en_mp <= 1'b1;
                                     sb_exit_mp <= 1'b0;
                                     trainerror_hs_mp <= 1'b0;
                                     flag <= 0;
                                     speed_idle_req_mp <= 1'b0;
                                     repair_req_mp <= 1'b0;
                                     flag_sb <= 0;
                                     test_resp_mp <= 1'b0;
                                     trainerror_flag <= 1'b0;    

                                 // data_in = {MBTRAIN.LINKSPEED exit to speed degrade req}
                                 end else if( (data_in[21:14] == 8'hB5) && (data_in[39:32] == 8'h18) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                     // data_out_mp = {MBTRAIN.LINKSPEED exit to speed degrade resp}
                                     data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h18 , data_in[31:22] , 8'hBA , data_in[13:0] }; 
                                     encoder_en_mp <= 1'b1;
                                     sb_exit_mp <= 1'b0;
                                     trainerror_hs_mp <= 1'b0;
                                     flag <= 0;
                                     speed_idle_req_mp <= 1'b1;
                                     repair_req_mp <= 1'b0;
                                     flag_sb <= 0;
                                     test_resp_mp <= 1'b0;
                                     trainerror_flag <= 1'b0;    

                                 // data_in = {MBTRAIN.LINKSPEED exit to repair req}
                                 end else if( (data_in[21:14] == 8'hB5) && (data_in[39:32] == 8'h17) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                     // data_out_mp = {MBTRAIN.LINKSPEED exit to repair resp}
                                     data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h17 , data_in[31:22] , 8'hBA , data_in[13:0] }; 
                                     encoder_en_mp <= 1'b1;
                                     sb_exit_mp <= 1'b0;
                                     trainerror_hs_mp <= 1'b0;
                                     flag <= 0;
                                     speed_idle_req_mp <= 1'b0;
                                     repair_req_mp <= 1'b1;
                                     flag_sb <= 0;
                                     test_resp_mp <= 1'b0;
                                     trainerror_flag <= 1'b0;    

                                 // data_in = {MBTRAIN.LINKSPEED done req}
                                 end else if( (data_in[21:14] == 8'hB5) && (data_in[39:32] == 8'h19) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                     // data_out_mp = {MBTRAIN.LINKSPEED done resp}
                                     data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h19 , data_in[31:22] , 8'hBA , data_in[13:0] }; 
                                     encoder_en_mp <= 1'b1;
                                     trainerror_hs_mp <= 1'b0;
                                     flag <= 0;
                                     speed_idle_req_mp <= 1'b0;
                                     repair_req_mp <= 1'b0;
                                     test_resp_mp <= 1'b0;
                                     trainerror_flag <= 1'b0;    
                                     if(sb_exit_m) begin     // to wait for module sb_exit_mp signal
                                      sb_exit_mp <= 1'b1;
                                      flag_sb <= 0;
                                     end else begin
                                       sb_exit_mp <= 1'b0;
                                       flag_sb <= 1;
                                     end

                                end else begin
                                    data_out_mp <= 64'b0;
                                    trainerror_flag <= 1'b1;
                                    trainerror_hs_mp <= 1'b0; 
                                    encoder_en_mp <= 1'b0;
                                    sb_exit_mp <= 1'b0;
                                    flag <= 0;
                                    speed_idle_req_mp <= 1'b0;
                                    repair_req_mp <= 1'b0;
                                    flag_sb <= 0;
                                    test_resp_mp <= 1'b0;
                                end

                                 

                  end

		  REPAIR: begin
                           // data_in = {TRAINERROR Entry req}
                           if( (data_in[21:14] == 8'hE5) && (data_in[39:32] == 8'h00) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not "TRAINERROR HandShake msgs"
                             // data_out_mp = {TRAINERROR Entry resp}
                               data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h00 , data_in[31:22] , 8'hEA , data_in[13:0] }; 
                               encoder_en_mp <= 1'b1;
                               sb_exit_mp <= 1'b0;
                               trainerror_hs_mp <= 1'b1;
                               flag_sb <= 0;
                               width_update <= 1'b0;
                               speed_idle_req_mp <= 1'b0;
                               repair_req_mp <= 1'b0;
                               trainerror_flag <= 1'b0;    

                           // data_in = {MBTRAIN.REPAIR init req}
                           end else if( (data_in[21:14] == 8'hB5) && (data_in[39:32] == 8'h1B) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                               // data_out_mp = {MBTRAIN.REPAIR init resp}
                               data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h1B , data_in[31:22] , 8'hBA , data_in[13:0] }; 
                               encoder_en_mp <= 1'b1;
                               sb_exit_mp <= 1'b0;
                               trainerror_hs_mp <= 1'b0;
                               flag_sb <= 0;
                               width_update <= 1'b0;
                               speed_idle_req_mp <= 1'b0;
                               repair_req_mp <= 1'b0;
                               trainerror_flag <= 1'b0;    

                           // data_in = {MBTRAIN.REPAIR Apply degrade req}
                           end else if( (data_in[21:14] == 8'hB5) && (data_in[39:32] == 8'h1E) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                               // data_out_mp = {MBTRAIN.REPAIR Apply degrade resp}
                               data_out_mp <= { 1'b0 ,1'b0 , data_in[61:56] , 16'b0 , 8'h1E , data_in[31:22] , 8'hBA , data_in[13:0] }; 
                               encoder_en_mp <= 1'b1;
                               sb_exit_mp <= 1'b0;
                               trainerror_hs_mp <= 1'b0;
                               width_degrade_mp <= data_in[42:40];
                               width_update <= 1'b1;
                               flag_sb <= 0;
                               speed_idle_req_mp <= 1'b0;
                               repair_req_mp <= 1'b0;
                               trainerror_flag <= 1'b0;    

                            // data_in = {MBTRAIN.REPAIR end req} 
                            end else if( (data_in[21:14] == 8'hB5) && (data_in[39:32] == 8'h1D) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or nott
                               // data_out_mp = {MBTRAIN.REPAIR end resp}
                               data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h1D , data_in[31:22] , 8'hBA , data_in[13:0] }; 
                               encoder_en_mp <= 1'b1;
                               trainerror_hs_mp <= 1'b0;
                               width_update <= 1'b0;
                               speed_idle_req_mp <= 1'b0;
                               repair_req_mp <= 1'b0;
                               trainerror_flag <= 1'b0;    
                               if(sb_exit_m) begin     // to wait for module sb_exit_mp signal
                                  sb_exit_mp <= 1'b1;
                                  flag_sb <= 0;
                               end else begin
                                  sb_exit_mp <= 1'b0;
                                  flag_sb <= 1;
                               end

                             end else begin
                               data_out_mp <= 64'b0;
                               trainerror_flag <= 1'b1;
                               trainerror_hs_mp <= 1'b0; 
                               encoder_en_mp <= 1'b0;
                               sb_exit_mp <= 1'b0;
                               flag_sb <= 0;
                               width_update <= 1'b0;
                               speed_idle_req_mp <= 1'b0;
                               repair_req_mp <= 1'b0;
                             end

                  end

		  default: begin
                            sb_exit_mp <= 1'b0;             
                            trainerror_hs_mp <= 1'b0;      
                            trainerror_flag <= 1'b0;     
                            //error_threshold <= 16'b0;   
                            start_mb_mp <= 1'b0; 
                            //width_degrade_mp <= 3'b0; 
                            data_out_mp <= 64'b0;  
                            encoder_en_mp <= 1'b0;   
                            flag <= 0;
                            flag_2 <= 0;
                            flag_sb <= 0;
                            flag_mb <= 0;
                            speed_idle_req_mp <= 1'b0;
                            repair_req_mp <= 1'b0;
                            width_update <= 1'b0;
                            test_resp_mp <= 1'b0;
                  end

                endcase
     end


      LINKINIT : begin     
                   // data_in = {TRAINERROR Entry req}
                   if( (data_in[21:14] == 8'hE5) && (data_in[39:32] == 8'h00) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not "TRAINERROR HandShake msgs"
                       // data_out_mp = {TRAINERROR Entry resp}
                       data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h00 , data_in[31:22] , 8'hEA , data_in[13:0] }; 
                       encoder_en_mp <= 1'b1;
                       sb_exit_mp <= 1'b0;
                       trainerror_hs_mp <= 1'b1;
                       trainerror_flag <= 1'b0;
                       start_mb_mp <= 1'b0;
                       width_update <= 1'b0;
                       speed_idle_req_mp <= 1'b0;
                       repair_req_mp <= 1'b0;
                       test_resp_mp <= 1'b0;
                       flag <= 0;
                       flag_2 <= 0;
                       flag_sb <= 0;
                       flag_mb <= 0;
  
                   end else begin
                       data_out_mp <= 64'b0;
                       trainerror_flag <= 1'b1;
                       trainerror_hs_mp <= 1'b0; 
                       encoder_en_mp <= 1'b0;
                       sb_exit_mp <= 1'b0;
                       start_mb_mp <= 1'b0;
                       width_update <= 1'b0;
                       speed_idle_req_mp <= 1'b0;
                       repair_req_mp <= 1'b0;
                       test_resp_mp <= 1'b0;
                       flag <= 0;
                       flag_2 <= 0;
                       flag_sb <= 0;
                       flag_mb <= 0;
                   end 

     end


     ACTIVE : begin     
                   // data_in = {TRAINERROR Entry req}
                   if( (data_in[21:14] == 8'hE5) && (data_in[39:32] == 8'h00) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not "TRAINERROR HandShake msgs"
                       // data_out_mp = {TRAINERROR Entry resp}
                       data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h00 , data_in[31:22] , 8'hEA , data_in[13:0] }; 
                       encoder_en_mp <= 1'b1;
                       sb_exit_mp <= 1'b0;
                       trainerror_hs_mp <= 1'b1;
                       trainerror_flag <= 1'b0;
                       start_mb_mp <= 1'b0;
                       width_update <= 1'b0;
                       speed_idle_req_mp <= 1'b0;
                       repair_req_mp <= 1'b0;
                       test_resp_mp <= 1'b0;
                       flag <= 0;
                       flag_2 <= 0;
                       flag_sb <= 0;
                       flag_mb <= 0;

                   end else begin
                       data_out_mp <= 64'b0;
                       trainerror_flag <= 1'b1;
                       trainerror_hs_mp <= 1'b0; 
                       encoder_en_mp <= 1'b0;
                       sb_exit_mp <= 1'b0;
                       start_mb_mp <= 1'b0;
                       width_update <= 1'b0;
                       speed_idle_req_mp <= 1'b0;
                       repair_req_mp <= 1'b0;
                       test_resp_mp <= 1'b0;
                       flag <= 0;
                       flag_2 <= 0;
                       flag_sb <= 0;
                       flag_mb <= 0;
                   end 

     end


     PHYRETRAIN : begin     
                   // data_in = {TRAINERROR Entry req}
                   if( (data_in[21:14] == 8'hE5) && (data_in[39:32] == 8'h00) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) && (data_in[55:40] == 16'h0000) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not "TRAINERROR HandShake msgs"
                       // data_out_mp = {TRAINERROR Entry resp}
                       data_out_mp <= { 1'b0 ,1'b0 , data_in[61:40] , 8'h00 , data_in[31:22] , 8'hEA , data_in[13:0] }; 
                       encoder_en_mp <= 1'b1;
                       sb_exit_mp <= 1'b0;
                       trainerror_hs_mp <= 1'b1;
                       flag_sb <= 0; 
                       trainerror_flag <= 1'b0;    
  
                   // data_in = {PHYRETRAIN.retrain start req}
                   end else if( (data_in[21:14] == 8'hC5) && (data_in[39:32] == 8'h01) && (data_in[31:29] == 3'b010) && (data_in[58:56] == 3'b110) ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                       // data_out_mp = {PHYRETRAIN.retrain start resp}
                       data_out_mp <= { 1'b0 ,1'b0 , data_in[61:43] , Resolved_Encoding , 8'h01 , data_in[31:22] , 8'hCA , data_in[13:0] }; 
                       encoder_en_mp <= 1'b1;
                       trainerror_hs_mp <= 1'b0;
                       trainerror_flag <= 1'b0;    
                       if(sb_exit_m) begin     // to wait for module sb_exit_mp signal
                         sb_exit_mp <= 1'b1;
                         flag_sb <= 0;
                       end else begin
                         sb_exit_mp <= 1'b0;
                         flag_sb <= 1;
                       end
 
                   end else begin
                       data_out_mp <= 64'b0;
                       trainerror_flag <= 1'b1;
                       trainerror_hs_mp <= 1'b0; 
                       encoder_en_mp <= 1'b0;
                       sb_exit_mp <= 1'b0;
                       flag_sb <= 0;
                   end 

     end


     default : begin     
                sb_exit_mp <= 1'b0;             
                trainerror_hs_mp <= 1'b0;      
                trainerror_flag <= 1'b0;     
                //error_threshold <= 16'b0;   
                start_mb_mp <= 1'b0; 
                //width_degrade_mp <= 3'b0; 
                data_out_mp <= 64'b0;  
                encoder_en_mp <= 1'b0;   
                flag <= 0;
                flag_2 <= 0;
                flag_sb <= 0;
                flag_mb <= 0;
                speed_idle_req_mp <= 1'b0;
                repair_req_mp <= 1'b0;
                width_update <= 1'b0;
                test_resp_mp <= 1'b0;
     end	 
    endcase


  end else if((cs == MBINIT) && (mbinit_cs == PARAM) && flag_2) begin
      
      data_out_mp <= { 53'b0 , 1'b0 , 1'b1 , 6'b0 , common_speed };
      encoder_en_mp <= 1'b1;
      flag_2 <= 0;
      trainerror_flag <= 1'b0;    
      if(sb_exit_m) begin
        sb_exit_mp <= 1'b1;
        flag_sb <= 0;
      end else begin
        sb_exit_mp <= 1'b0;
        flag_sb <= 1;
      end

  end else if((cs == MBTRAIN) && ( (mbtrain_cs == VALVREF) || (mbtrain_cs == DATAVREF) || (mbtrain_cs == VALTRAINVREF) || (mbtrain_cs == DATATRAINVREF) || (mbtrain_cs == RXDESKEW) ) && flag_mb)  begin
    if( end_mb ) begin
      // data_out_mp = {Rx Init D to C Tx Count Done req}
      data_out_mp <= { 5'b0 , 3'b110 , 16'h0000 , 8'h08 , 3'b010 ,7'b0 , 8'h85 , 9'b0 , 5'b10010 }; 
      encoder_en_mp <= 1'b1;
      sb_exit_mp <= 1'b0;
      start_mb_mp <= 1'b0;
      trainerror_hs_mp <= 1'b0; 
      trainerror_flag <= 1'b0;    
      flag <= 0;
      flag_sb <= 0;
      flag_mb <= 0;
    end else begin
      data_out_mp <= 64'b0;
      encoder_en_mp <= 1'b0;
      sb_exit_mp <= 1'b0;
      start_mb_mp <= 1'b0;
      trainerror_hs_mp <= 1'b0; 
      trainerror_flag <= 1'b0;    
      flag <= 0;
      flag_sb <= 0;
      flag_mb <= 1;
    end

  end else if(flag_sb) begin
    data_out_mp <= 64'b0;
    encoder_en_mp <= 1'b0;
    trainerror_flag <= 1'b0;    
    if(sb_exit_m) begin
       sb_exit_mp <= 1'b1;
       flag_sb <= 0;
     end else begin
       sb_exit_mp <= 1'b0;
       flag_sb <= 1;
     end
 
  end else if(flag_2) begin
    if( (cs == MBTRAIN) && (mbtrain_cs == VALTRAINCENTER) ) begin
      data_out_mp <= 64'b0;
      encoder_en_mp <= 1'b1;
      sb_exit_mp <= 1'b0;
      flag_2 <= 0;
      trainerror_flag <= 1'b0;    
    end else if( ((cs == MBTRAIN) || (cs == MBINIT)) && ( ((mbtrain_cs == DATATRAINCENTER1) || (mbtrain_cs ==  DATATRAINCENTER2) || (mbtrain_cs ==  LINKSPEED)) || ((mbinit_cs == REVERSALMB) || (mbinit_cs == REPAIRMB))) ) begin
      data_out_mp <= {48'h0, faulty_lanes_reg};
      encoder_en_mp <= 1'b1;
      sb_exit_mp <= 1'b0;
      flag_2 <= 0;
      trainerror_flag <= 1'b0;    
    end else begin
      data_out_mp <= 64'b0;
      encoder_en_mp <= 1'b0;
      sb_exit_mp <= 1'b0;
      flag_2 <= 0;
      trainerror_flag <= 1'b0;    
    end

  end else begin

    sb_exit_mp <= 1'b0;             
    trainerror_hs_mp <= 1'b0;      
    trainerror_flag <= 1'b0;     
    //error_threshold <= 16'b0;   
    start_mb_mp <= 1'b0; 
    //width_degrade_mp <= 3'b0; 
    data_out_mp <= 64'b0;  
    encoder_en_mp <= 1'b0;   
    flag_2 <= 0;
    flag_sb <= 0;
    flag_mb <= 0;
    speed_idle_req_mp <= 1'b0;
    repair_req_mp <= 1'b0;
    width_update <= 1'b0;
    test_resp_mp <= 1'b0;

  end


end


endmodule




