import shared_package ::*;
//implementing the Module Partner block of the SB Controller
module Module_Partner #( parameter DATA_WIDTH = 64 )
(
  input                          lclk, 
  input                          RST, 
  input                          Module_Partner_EN,              // from SB_RX Decoder
  input        [DATA_WIDTH-1:0]  DATA_IN,                       // from SB_RX Decoder
  input 			 error,                        // from SB_RX Decoder
  input        [2:0]             cs,                          // from LTSM
  input        [2:0]             mbinit_cs,                  // from LTSM
  input        [3:0]             mbtrain_cs,                // from LTSM
  input 	                 End_MB,                   // from MB_TX
  input 		         pattern_detected,        // from SB_RX pattern detector
  input                          valid_frame_error,      // from MB_RX    indicates if valid test passed or not "1 means failed"
  input                          detec_succ,            // from MB_RX    indicates if valid test passed or not "1 means passed"
  input        [15:0]            faulty_lanes,         // from MB_RX    indicates if lanes test passed or not "1 means good" & "0 means fault"
  input                          Comparison_Done,     // from MB_RX    indicates that the faulty_lanes has a valid value
  input                          sb_exit_module,     // from SB Controller "Module" block indicating that it is ready for state transition
  input        [2:0]             Retrain_Encoding,  // from SB Controller "Module" block indicating the local die retrain encoding 
  

  output  reg 			 sb_exit,                   // to LTSM
  output  reg 			 trainerror_hs,            // to LTSM
  output  reg 			 trainerror_flag,         // to SB Controller "Module" block
  output  reg  [15:0] 	         Error_Threshold,        // to MB_RX    
  output  reg          	         Start_MB,              // to MB_TX    when sending the {Start Rx Init D to C point test resp} msg from module partner block
  output  reg  [2:0]		 width_degrade_MB,     // to MB_RX
  output  reg                    Width_Update,        // to MB_RX along with the width_degrade
  output  reg  [DATA_WIDTH-1:0]  DATA_OUT,           // to SB_TX Encoder (i.e. to SB Controller Arbiter)
  output  reg                    Encoder_EN,        // to SB_TX Encoder  (i.e. to SB Controller Arbiter)
  output  reg                    PhyRetrain_req,   // to LTSM to transition from LINKSPEED to PHYRETRAIN 
  output  reg                    SpeedIdle_req,   // to LTSM to transition from LINKSPEED to SPEEDIDLE  
  output  reg                    Repair_req      // to LTSM to transition from LINKSPEED to REPAIR  
  );


//internal signals
logic                   flag = 0;    //to wait for the data part of msg reg
logic                   flag_2 = 0;  //to send the data part of msg response in the next cycle
logic                   flag_sb = 0; //to be checked for sb_exit condition
logic                   flag_mb = 0; //to wait for the End_MB signal 
logic [DATA_WIDTH-1:0]  DATA_IN_reg;
logic [DATA_WIDTH-1:0]  DATA_IN_PARAM;
logic [2:0]             Resolved_Encoding;
logic [15:0]            faulty_lanes_reg;
logic                   failed;


integer i;
reg [4:0] count;
logic status;


always @(*) begin
    if(valid_frame_error || detec_succ) begin
       if(valid_frame_error)
          failed = 1'b1;
       else
          failed = 1'b0;
    end else begin
       failed = failed;
    end

    if(Comparison_Done) begin
      faulty_lanes_reg = faulty_lanes;
      count = 0;
      for (i = 0; i < 16; i = i + 1) begin
         count = count + faulty_lanes[i];
      end
    end else begin
      faulty_lanes_reg = faulty_lanes_reg;
      count = count;
    end

end


assign status = (count >= 8) ? 1'b1 : 1'b0;


always @(posedge lclk or negedge RST) begin

  if(!RST) begin

     sb_exit <= 1'b0;             
     trainerror_hs <= 1'b0;      
     trainerror_flag <= 1'b0;     
     Error_Threshold <= 16'b0;   
     Start_MB <= 1'b0; 
     width_degrade_MB <= 3'b0; 
     DATA_OUT <= 64'b0;  
     Encoder_EN <= 1'b0;   
     flag <= 0;
     flag_2 <= 0;
     flag_sb <= 0;
     flag_mb <= 0;
     PhyRetrain_req <= 1'b0;
     SpeedIdle_req <= 1'b0;
     Repair_req <= 1'b0;
     Width_Update <= 1'b0;
  
  end else if(Module_Partner_EN) begin

    case(cs)
     RESET : begin 	
              if(pattern_detected)
                sb_exit <= 1'b1;
              else
                sb_exit <= 1'b0;    
     end

     SBINIT : begin 
               // DATA_IN = {SBINIT done req}
               if( (DATA_IN[21:14] == 8'h95) && (DATA_IN[39:32] == 8'h01) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0] & MsgSubcode[7:0] match or not
                  // DATA_OUT = {SBINIT done resp}
                  DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h01 , DATA_IN[31:22] , 8'h9A , DATA_IN[13:0] }; 
                  Encoder_EN <= 1'b1;
                  if(sb_exit_module) begin
                    sb_exit <= 1'b1;
                    flag_sb <= 0;
                  end else begin
                    sb_exit <= 1'b0;
                    flag_sb <= 1;
                  end
 
               end else begin
                  DATA_OUT <= 64'b0;
                  trainerror_flag <= 1'b1;
                  Encoder_EN <= 1'b0;
                  sb_exit <= 1'b0;
                  flag_sb <= 0;
               end
     end

     MBINIT: begin
              case(mbinit_cs)
		PARAM: begin
                       // DATA_IN = {TRAINERROR Entry req}
                       if( (DATA_IN[21:14] == 8'hE5) && (DATA_IN[39:32] == 8'h00) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0] & MsgSubcode[7:0] match or not
                          // DATA_OUT = {TRAINERROR Entry resp}
                          DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h00 , DATA_IN[31:22] , 8'hEA , DATA_IN[13:0] }; 
                          Encoder_EN <= 1'b1;
                          sb_exit <= 1'b0;
                          trainerror_hs <= 1'b1;
                          flag_sb <= 0;
                          flag <= 0; 
                          flag_2 <= 0;

                       // DATA_IN = {MBINIT.PARAM configuration req}
                       end else if( (DATA_IN[21:14] == 8'hA5) && (DATA_IN[39:32] == 8'h00) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0] & MsgSubcode[7:0] match or not
                          flag <= 1;  // to wait for the 64 bit of data 
                          DATA_IN_reg <= DATA_IN;       //storing the msg 
                          DATA_OUT <= 64'b0; 
                          Encoder_EN <= 1'b0;
                          sb_exit <= 1'b0;
                          flag_sb <= 0;
                          flag_2 <= 0;

                       end else if( flag && !error ) begin
                          flag <= 0;
                          DATA_IN_PARAM <= DATA_IN;       //storing the data field of the msg req
                          // DATA_OUT = {MBINIT.PARAM configuration resp}
                          DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN_reg[61:40] , 8'h00 , DATA_IN_reg[31:22] , 8'hAA , DATA_IN_reg[13:0] };  
                          Encoder_EN <= 1'b1;
                          sb_exit <= 1'b0;
                          trainerror_hs <= 1'b0;
                          flag_sb <= 0;
                          flag_2 <= 1;    // to send the remainig data part of the resp in the next cycle

                       end else begin
                           DATA_OUT <= 64'b0;
                           trainerror_flag <= 1'b1;
                           Encoder_EN <= 1'b0;
                           sb_exit <= 1'b0;
                           trainerror_hs <= 1'b0;
                           flag_sb <= 0;
                           flag <= 0; 
                           flag_2 <= 0;
                        end

                end

		CAL: begin
                        // DATA_IN = {TRAINERROR Entry req}
                        if( (DATA_IN[21:14] == 8'hE5) && (DATA_IN[39:32] == 8'h00) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0] & MsgSubcode[7:0] match or not
                          // DATA_OUT = {TRAINERROR Entry resp}
                          DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h00 , DATA_IN[31:22] , 8'hEA , DATA_IN[13:0] }; 
                          Encoder_EN <= 1'b1;
                          sb_exit <= 1'b0;
                          trainerror_hs <= 1'b1;
                          flag_sb <= 0;

                       // DATA_IN = {MBINIT.CAL Done req} 
                       end else if( (DATA_IN[21:14] == 8'hA5) && (DATA_IN[39:32] == 8'h02) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0] & MsgSubcode[7:0] match or not
                          // DATA_OUT = {MBINIT.CAL Done resp}
                          DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h02 , DATA_IN[31:22] , 8'hAA , DATA_IN[13:0] }; 
                          Encoder_EN <= 1'b1;
                          trainerror_hs <= 1'b0;
                          if(sb_exit_module) begin
                            sb_exit <= 1'b1;
                            flag_sb <= 0;
                          end else begin
                            sb_exit <= 1'b0;
                            flag_sb <= 1;
                          end
                         
                        end else begin
                           DATA_OUT <= 64'b0;
                           trainerror_flag <= 1'b1;
                           Encoder_EN <= 1'b0;
                           sb_exit <= 1'b0;
                           trainerror_hs <= 1'b0;
                           flag_sb <= 0;
                        end
                end

		REPAIRCLK: begin
                            // DATA_IN = {TRAINERROR Entry req}
                            if( (DATA_IN[21:14] == 8'hE5) && (DATA_IN[39:32] == 8'h00) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0] & MsgSubcode[7:0] match or not
                              // DATA_OUT = {TRAINERROR Entry resp}
                              DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h00 , DATA_IN[31:22] , 8'hEA , DATA_IN[13:0] }; 
                              Encoder_EN <= 1'b1;
                              sb_exit <= 1'b0;
                              trainerror_hs <= 1'b1;
                              flag_sb <= 0;

                            // DATA_IN = {MBINIT.REPAIRCLK init req}
                            end else if( (DATA_IN[21:14] == 8'hA5) && (DATA_IN[39:32] == 8'h03) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0] & MsgSubcode[7:0] match or not
                               // DATA_OUT = {MBINIT.REPAIRCLK init resp}
                               DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h03 , DATA_IN[31:22] , 8'hAA , DATA_IN[13:0] }; 
                               Encoder_EN <= 1'b1;
                               sb_exit <= 1'b0;
                               trainerror_hs <= 1'b0;
                               flag_sb <= 0;

                             // DATA_IN = {MBINIT.REPAIRCLK result req}
                             end else if( (DATA_IN[21:14] == 8'hA5) && (DATA_IN[39:32] == 8'h04) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0] & MsgSubcode[7:0] match or not
                               // DATA_OUT = {MBINIT.REPAIRCLK result resp}
                               DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h04 , DATA_IN[31:22] , 8'hAA , DATA_IN[13:0] }; 
                               Encoder_EN <= 1'b1;
                               sb_exit <= 1'b0;
                               trainerror_hs <= 1'b0;
                               flag_sb <= 0;

                             // DATA_IN = {MBINIT.REPAIRCLK done req}
                             end else if( (DATA_IN[21:14] == 8'hA5) && (DATA_IN[39:32] == 8'h08) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0] & MsgSubcode[7:0] match or not
                               // DATA_OUT = {MBINIT.REPAIRCLK done resp}
                               DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h08 , DATA_IN[31:22] , 8'hAA , DATA_IN[13:0] }; 
                               Encoder_EN <= 1'b1;
                               trainerror_hs <= 1'b0;
                               if(sb_exit_module) begin
                                 sb_exit <= 1'b1;
                                 flag_sb <= 0;
                               end else begin
                                 sb_exit <= 1'b0;
                                 flag_sb <= 1;
                               end

                             end else begin
                               DATA_OUT <= 64'b0;
                               trainerror_flag <= 1'b1;
                               Encoder_EN <= 1'b0;
                               sb_exit <= 1'b0;
                               trainerror_hs <= 1'b0;
                               flag_sb <= 0;
                             end
                end

		REPAIRVAL: begin
                            // DATA_IN = {TRAINERROR Entry req}
                            if( (DATA_IN[21:14] == 8'hE5) && (DATA_IN[39:32] == 8'h00) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0] & MsgSubcode[7:0] match or not
                              // DATA_OUT = {TRAINERROR Entry resp}
                              DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h00 , DATA_IN[31:22] , 8'hEA , DATA_IN[13:0] }; 
                              Encoder_EN <= 1'b1;
                              sb_exit <= 1'b0;
                              trainerror_hs <= 1'b1;
                              flag_sb <= 0;

                            // DATA_IN = {MBINIT.REPAIRVAL init req}
                            end else if( (DATA_IN[21:14] == 8'hA5) && (DATA_IN[39:32] == 8'h09) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0] & MsgSubcode[7:0] match or not
                               // DATA_OUT = {MBINIT.REPAIRVAL init resp}
                               DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h09 , DATA_IN[31:22] , 8'hAA , DATA_IN[13:0] }; 
                               Encoder_EN <= 1'b1;
                               sb_exit <= 1'b0;
                               trainerror_hs <= 1'b0;
                               flag_sb <= 0;

                             // DATA_IN = {MBINIT.REPAIRVAL result req}
                             end else if( (DATA_IN[21:14] == 8'hA5) && (DATA_IN[39:32] == 8'h0A) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0] & MsgSubcode[7:0] match or not
                               // DATA_OUT = {MBINIT.REPAIRVAL result resp}
                               if(failed) begin                     // valid test failed "valid bit is 0"
                                  DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:42] , 1'b0 , 1'b0 , 8'h0A , DATA_IN[31:22] , 8'hAA , DATA_IN[13:0] }; 
                                  Encoder_EN <= 1'b1;
                                  sb_exit <= 1'b0;
                                  trainerror_hs <= 1'b0;
                                  flag_sb <= 0;
                               end else begin                                 // valid test passed "valid bit is 1"
                                  DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:42] , 1'b0 , 1'b1 , 8'h0A , DATA_IN[31:22] , 8'hAA , DATA_IN[13:0] }; 
                                  Encoder_EN <= 1'b1;
                                  sb_exit <= 1'b0;
                                  trainerror_hs <= 1'b0;
                                  flag_sb <= 0;
                               end

                             // DATA_IN = {MBINIT.REPAIRVAL done req}
                             end else if( (DATA_IN[21:14] == 8'hA5) && (DATA_IN[39:32] == 8'h0C) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0] & MsgSubcode[7:0] match or not
                               // DATA_OUT = {MBINIT.REPAIRVAL done resp}
                               DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h0C , DATA_IN[31:22] , 8'hAA , DATA_IN[13:0] }; 
                               Encoder_EN <= 1'b1;
                               trainerror_hs <= 1'b0;
                               if(sb_exit_module) begin
                                 sb_exit <= 1'b1;
                                 flag_sb <= 0;
                               end else begin
                                 sb_exit <= 1'b0;
                                 flag_sb <= 1;
                               end

                             end else begin
                               DATA_OUT <= 64'b0;
                               trainerror_flag <= 1'b1;
                               Encoder_EN <= 1'b0;
                               sb_exit <= 1'b0;
                               trainerror_hs <= 1'b0;
                               flag_sb <= 0;
                             end
                end

		REVERSALMB: begin
                             // DATA_IN = {TRAINERROR Entry req}
                             if( (DATA_IN[21:14] == 8'hE5) && (DATA_IN[39:32] == 8'h00) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0] & MsgSubcode[7:0] match or not
                               // DATA_OUT = {TRAINERROR Entry resp}
                               DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h00 , DATA_IN[31:22] , 8'hEA , DATA_IN[13:0] }; 
                               Encoder_EN <= 1'b1;
                               sb_exit <= 1'b0;
                               trainerror_hs <= 1'b1;
                               flag_sb <= 0;
                               flag_2 <= 0;

                             // DATA_IN = {MBINIT.REVERSALMB init req}
                             end else if( (DATA_IN[21:14] == 8'hA5) && (DATA_IN[39:32] == 8'h0D) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0] & MsgSubcode[7:0] match or not
                               // DATA_OUT = {MBINIT.REVERSALMB init resp}
                               DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h0D , DATA_IN[31:22] , 8'hAA , DATA_IN[13:0] }; 
                               Encoder_EN <= 1'b1;
                               sb_exit <= 1'b0;
                               flag_sb <= 0;
                               flag_2 <= 0;

                             // DATA_IN = {MBINIT.REVERSALMB clear error req}
                             end else if( (DATA_IN[21:14] == 8'hA5) && (DATA_IN[39:32] == 8'h0E) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0] & MsgSubcode[7:0] match or not
                               // DATA_OUT = {MBINIT.REVERSALMB clear error resp}
                               DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h0E , DATA_IN[31:22] , 8'hAA , DATA_IN[13:0] }; 
                               Encoder_EN <= 1'b1;
                               sb_exit <= 1'b0;
                               flag_sb <= 0;
                               flag_2 <= 0;

                             // DATA_IN = {MBINIT.REVERSALMB result req}
                             end else if( (DATA_IN[21:14] == 8'hA5) && (DATA_IN[39:32] == 8'h0F) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0] & MsgSubcode[7:0] match or not
                               // DATA_OUT = {MBINIT.REVERSALMB result resp}
                               DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h0F , DATA_IN[31:22] , 8'hAA , DATA_IN[13:0] }; 
                               Encoder_EN <= 1'b1;
                               sb_exit <= 1'b0;
                               flag_sb <= 0;
                               flag_2 <= 1;    // to send the remainig data part of the resp in the next cycle
                             
                             // DATA_IN = {MBINIT.REVERSALMB done req} 
                             end else if( (DATA_IN[21:14] == 8'hA5) && (DATA_IN[39:32] == 8'h10) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0] & MsgSubcode[7:0] match or not
                               // DATA_OUT = {MBINIT.REVERSALMB done resp}
                               DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h10 , DATA_IN[31:22] , 8'hAA , DATA_IN[13:0] }; 
                               Encoder_EN <= 1'b1;
                               flag_2 <= 0;
                               if(sb_exit_module) begin
                                 sb_exit <= 1'b1;
                                 flag_sb <= 0;
                               end else begin
                                 sb_exit <= 1'b0;
                                 flag_sb <= 1;
                               end

                             end else begin
                               DATA_OUT <= 64'b0;
                               trainerror_flag <= 1'b1;
                               Encoder_EN <= 1'b0;
                               sb_exit <= 1'b0;
                               flag_sb <= 0;
                               flag_2 <= 0;
                             end
                end

		REPAIRMB: begin
                           // DATA_IN = {TRAINERROR Entry req}
                           if( (DATA_IN[21:14] == 8'hE5) && (DATA_IN[39:32] == 8'h00) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0] & MsgSubcode[7:0] match or not
                               // DATA_OUT = {TRAINERROR Entry resp}
                               DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h00 , DATA_IN[31:22] , 8'hEA , DATA_IN[13:0] }; 
                               Encoder_EN <= 1'b1;
                               sb_exit <= 1'b0;
                               trainerror_hs <= 1'b1;
                               flag_sb <= 0;
                               flag_2 <= 0;
                               flag <= 0; 
                               Width_Update <= 1'b0;

                            // DATA_IN = {MBINIT.REPAIRMB start req}
                            end else if( (DATA_IN[21:14] == 8'hA5) && (DATA_IN[39:32] == 8'h11) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                               // DATA_OUT = {MBINIT.REPAIRMB start resp}
                               DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h11 , DATA_IN[31:22] , 8'hAA , DATA_IN[13:0] }; 
                               Encoder_EN <= 1'b1;
                               sb_exit <= 1'b0;
                               flag_sb <= 0;
                               flag_2 <= 0;
                               flag <= 0; 
                               Width_Update <= 1'b0;

                            // DATA_IN = {Start Tx Init D to C point test req}
                            end else if( (DATA_IN[21:14] == 8'h85) && (DATA_IN[39:32] == 8'h01) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                flag <= 1;  // to wait for the 64 bit of data 
                                Error_Threshold <= DATA_IN[55:40];
                                DATA_IN_reg <= DATA_IN;       //storing the msg 
                                DATA_OUT <= 64'b0; 
                                Encoder_EN <= 1'b0;
                                sb_exit <= 1'b0;
                                flag_sb <= 0;
                                flag_2 <= 0;
                                Width_Update <= 1'b0;

                             end else if( flag && !error ) begin
                                 flag <= 0;
                                 // DATA_OUT = {Start Tx Init D to C point test resp}
                                 DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN_reg[61:56] , 15'h0000 , 8'h01 , DATA_IN_reg[31:22] , 8'h8A , DATA_IN_reg[13:0] }; 
                                 Encoder_EN <= 1'b1;
                                 sb_exit <= 1'b0;
                                 trainerror_hs <= 1'b0;
                                 flag_sb <= 0;
                                 flag_2 <= 0;
                                 Width_Update <= 1'b0;

                              // DATA_IN = {LFSR_clear_error req}
                              end else if( (DATA_IN[21:14] == 8'h85) && (DATA_IN[39:32] == 8'h02) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                 // DATA_OUT = {LFSR_clear_error resp}
                                 DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h02 , DATA_IN[31:22] , 8'h8A , DATA_IN[13:0] }; 
                                 Encoder_EN <= 1'b1;
                                 sb_exit <= 1'b0;
                                 trainerror_hs <= 1'b0;
                                 flag_sb <= 0;
                                 flag_2 <= 0;
                                 flag <= 0; 
                                 Width_Update <= 1'b0;

                              // DATA_IN = {Tx Init D to C results req}
                              end else if( (DATA_IN[21:14] == 8'h85) && (DATA_IN[39:32] == 8'h03) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                             
                                  // DATA_OUT = {Tx Init D to C results resp}
                                  // PerLaneID test passed "status bit is 1"    // PerLaneID test failed "status bit is 0"
                                  DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:45] , status , DATA_IN[43:40] , 8'h03 , DATA_IN[31:22] , 8'h8A , DATA_IN[13:0] }; 
                                  Encoder_EN <= 1'b1;
                                  sb_exit <= 1'b0;
                                  trainerror_hs <= 1'b0;
                                  flag <= 0;
                                  flag_2 <= 1;    // to send the remainig data part of the resp in the next cycle 
                                  flag_sb <= 0;
                                  Width_Update <= 1'b0;

                               // DATA_IN =  {End Tx Init D to C point test req}
                               end else if( (DATA_IN[21:14] == 8'h85) && (DATA_IN[39:32] == 8'h04) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                  // DATA_OUT = {End Tx Init D to C point test resp}
                                  DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h04 , DATA_IN[31:22] , 8'h8A , DATA_IN[13:0] }; 
                                  Encoder_EN <= 1'b1;
                                  sb_exit <= 1'b0;
                                  trainerror_hs <= 1'b0;
                                  flag <= 0;
                                  flag_sb <= 0;
                                  flag_2 <= 0;
                                  Width_Update <= 1'b0;

                            // DATA_IN = {MBINIT.REPAIRMB apply degrade req}
                            end else if( (DATA_IN[21:14] == 8'hA5) && (DATA_IN[39:32] == 8'h14) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                               // DATA_OUT = {MBINIT.REPAIRMB apply degrade resp}
                               DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:56] , 16'h0000 , 8'h14 , DATA_IN[31:22] , 8'hAA , DATA_IN[13:0] }; 
                               Encoder_EN <= 1'b1;
                               sb_exit <= 1'b0;
                               width_degrade_MB <= DATA_IN[42:40];
                               Width_Update <= 1'b1;
                               flag_sb <= 0;
                               flag_2 <= 0;
                               flag <= 0;

                             // DATA_IN = {MBINIT.REPAIRMB end req} 
                             end else if( (DATA_IN[21:14] == 8'hA5) && (DATA_IN[39:32] == 8'h13) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                               // DATA_OUT = {MBINIT.REPAIRMB end resp}
                               DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h13 , DATA_IN[31:22] , 8'hAA , DATA_IN[13:0] }; 
                               Encoder_EN <= 1'b1;
                               flag_2 <= 0;
                               flag <= 0;
                               Width_Update <= 1'b0;
                               if(sb_exit_module) begin
                                 sb_exit <= 1'b1;
                                 flag_sb <= 0;
                               end else begin
                                 sb_exit <= 1'b0;
                                 flag_sb <= 1;
                               end

                             end else begin
                               DATA_OUT <= 64'b0;
                               trainerror_flag <= 1'b1;
                               Encoder_EN <= 1'b0;
                               sb_exit <= 1'b0;
                               flag_sb <= 0;
                               flag_2 <= 0;
                               flag <= 0;
                               Width_Update <= 1'b0;
                             end
                end

		default: begin
                          sb_exit <= 1'b0;             
                          trainerror_hs <= 1'b0;      
                          trainerror_flag <= 1'b0;     
                          //Error_Threshold <= 16'b0;   
                          Start_MB <= 1'b0; 
                          //width_degrade_MB <= 3'b0; 
                          DATA_OUT <= 64'b0;  
                          Encoder_EN <= 1'b0;  
                          flag <= 0;
                          flag_2 <= 0;
                          flag_sb <= 0;
                          PhyRetrain_req <= 1'b0;
                          SpeedIdle_req <= 1'b0;
                          Repair_req <= 1'b0;
                          Width_Update <= 1'b0;
                end

	      endcase
     end

     MBTRAIN : begin
                case(mbtrain_cs)
                  VALVREF: begin
                             // DATA_IN = {TRAINERROR Entry req}
                             if( (DATA_IN[21:14] == 8'hE5) && (DATA_IN[39:32] == 8'h00) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                               // DATA_OUT = {TRAINERROR Entry resp}
                               DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h00 , DATA_IN[31:22] , 8'hEA , DATA_IN[13:0] }; 
                               Encoder_EN <= 1'b1;
                               sb_exit <= 1'b0;
                               Start_MB <= 1'b0;
                               trainerror_hs <= 1'b1;
                               flag <= 0;
                               flag_sb <= 0;
                               flag_mb <= 0;

                             // DATA_IN = {MBTRAIN.VALVREF start req}
                             end else if( (DATA_IN[21:14] == 8'hB5) && (DATA_IN[39:32] == 8'h00) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                               // DATA_OUT = {MBTRAIN.VALVREF start resp}
                               DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h00 , DATA_IN[31:22] , 8'hBA , DATA_IN[13:0] }; 
                               Encoder_EN <= 1'b1;
                               sb_exit <= 1'b0;
                               Start_MB <= 1'b0;
                               trainerror_hs <= 1'b0;
                               flag <= 0;
                               flag_sb <= 0;
                               flag_mb <= 0;

                             // DATA_IN = {Start Rx Init D to C point test req}
                             end else if( (DATA_IN[21:14] == 8'h85) && (DATA_IN[39:32] == 8'h07) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                               flag <= 1;  // to wait for the 64 bit of data 
                               DATA_IN_reg <= DATA_IN;       //storing the msg 
                               flag_sb <= 0;

                             end else if( flag && !error ) begin
                               flag <= 0;
                               // DATA_OUT = {Start Rx Init D to C point test resp}
                               DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN_reg[61:56] , 15'h0000 , 8'h07 , DATA_IN_reg[31:22] , 8'h8A , DATA_IN_reg[13:0] }; 
                               Encoder_EN <= 1'b1;
                               sb_exit <= 1'b0;
                               Start_MB <= 1'b0;
                               trainerror_hs <= 1'b0;
                               flag_sb <= 0;
                               flag_mb <= 0;

                             // DATA_IN = {LFSR_clear_error req}
                             end else if( (DATA_IN[21:14] == 8'h85) && (DATA_IN[39:32] == 8'h02) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                               // DATA_OUT = {LFSR_clear_error resp}
                               DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h02 , DATA_IN[31:22] , 8'h8A , DATA_IN[13:0] }; 
                               Encoder_EN <= 1'b1;
                               sb_exit <= 1'b0;
                               Start_MB <= 1'b1;
                               flag_mb <= 1;
                               flag_sb <= 0;
                               flag <= 0; 

                             // DATA_IN = {Rx Init D to C Tx Count Done resp}
                             end else if( (DATA_IN[21:14] == 8'h8A) && (DATA_IN[39:32] == 8'h08) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                               // DATA_OUT
                               DATA_OUT <= 64'b0;
                               Encoder_EN <= 1'b0;
                               sb_exit <= 1'b0;
                               Start_MB <= 1'b0;
                               trainerror_hs <= 1'b0; 
                               flag <= 0;
                               flag_sb <= 0;
                               flag_mb <= 0;
                               
                             // DATA_IN =  {End Rx Init D to C point test req}
                             end else if( (DATA_IN[21:14] == 8'h85) && (DATA_IN[39:32] == 8'h09) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                               // DATA_OUT =  {End Rx Init D to C point test resp}
                               DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h09 , DATA_IN[31:22] , 8'h8A , DATA_IN[13:0] }; 
                               Encoder_EN <= 1'b1;
                               sb_exit <= 1'b0;
                               Start_MB <= 1'b0;
                               trainerror_hs <= 1'b0;
                               flag <= 0;
                               flag_sb <= 0;
                               flag_mb <= 0;

                             // DATA_IN = {MBTRAIN.VALVREF end req}
                             end else if( (DATA_IN[21:14] == 8'hB5) && (DATA_IN[39:32] == 8'h01) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                               // DATA_OUT =  {MBTRAIN.VALVREF end resp}
                               DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h01 , DATA_IN[31:22] , 8'hBA , DATA_IN[13:0] }; 
                               Encoder_EN <= 1'b1;
                               Start_MB <= 1'b0;
                               trainerror_hs <= 1'b0;
                               flag <= 0;
                               flag_mb <= 0;
                               if(sb_exit_module) begin
                                 sb_exit <= 1'b1;
                                 flag_sb <= 0;
                               end else begin
                                 sb_exit <= 1'b0;
                                 flag_sb <= 1;
                               end

                             end else begin
                               DATA_OUT <= 64'b0;
                               trainerror_flag <= 1'b1;
                               Encoder_EN <= 1'b0;
                               sb_exit <= 1'b0;
                               Start_MB <= 1'b0;
                               trainerror_hs <= 1'b0;
                               flag <= 0;
                               flag_sb <= 0;
                               flag_mb <= 0;
                             end
                               
                  end

		  DATAVREF: begin
                             // DATA_IN = {TRAINERROR Entry req}
                             if( (DATA_IN[21:14] == 8'hE5) && (DATA_IN[39:32] == 8'h00) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                               // DATA_OUT = {TRAINERROR Entry resp}
                               DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h00 , DATA_IN[31:22] , 8'hEA , DATA_IN[13:0] }; 
                               Encoder_EN <= 1'b1;
                               sb_exit <= 1'b0;
                               Start_MB <= 1'b0;
                               trainerror_hs <= 1'b1;
                               flag <= 0;
                               flag_sb <= 0;
                               flag_mb <= 0;

                             // DATA_IN = {MBTRAIN.DATAVREF start req}
                             end else if( (DATA_IN[21:14] == 8'hB5) && (DATA_IN[39:32] == 8'h02) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                               // DATA_OUT =  {MBTRAIN.DATAVREF start resp}
                               DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h02 , DATA_IN[31:22] , 8'hBA , DATA_IN[13:0] }; 
                               Encoder_EN <= 1'b1;
                               sb_exit <= 1'b0;
                               Start_MB <= 1'b0;
                               trainerror_hs <= 1'b0;
                               flag <= 0;
                               flag_sb <= 0;
                               flag_mb <= 0;

                             // DATA_IN = {Start Rx Init D to C point test req}
                             end else if( (DATA_IN[21:14] == 8'h85) && (DATA_IN[39:32] == 8'h07) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                               flag <= 1;  // to wait for the 64 bit of data 
                               DATA_IN_reg <= DATA_IN;       //storing the msg 
                               flag_sb <= 0;
                               flag_mb <= 0;

                             end else if( flag && !error ) begin
                               flag <= 0;
                               // DATA_OUT = {Start Rx Init D to C point test resp}
                               DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN_reg[61:56] , 15'h0000 , 8'h07 , DATA_IN_reg[31:22] , 8'h8A , DATA_IN_reg[13:0] }; 
                               Encoder_EN <= 1'b1;
                               sb_exit <= 1'b0;
                               Start_MB <= 1'b0;
                               trainerror_hs <= 1'b0;
                               flag_sb <= 0;
                               flag_mb <= 0;

                             // DATA_IN = {LFSR_clear_error req}
                             end else if( (DATA_IN[21:14] == 8'h85) && (DATA_IN[39:32] == 8'h02) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                               // DATA_OUT = {LFSR_clear_error resp}
                               DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h02 , DATA_IN[31:22] , 8'h8A , DATA_IN[13:0] }; 
                               Encoder_EN <= 1'b1;
                               sb_exit <= 1'b0;
                               Start_MB <= 1'b1;
                               flag_mb <= 1;
                               flag_sb <= 0;
                               flag <= 0; 

                             // DATA_IN = {Rx Init D to C Tx Count Done resp}
                             end else if( (DATA_IN[21:14] == 8'h8A) && (DATA_IN[39:32] == 8'h08) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                               // DATA_OUT
                               DATA_OUT <= 64'b0;
                               Encoder_EN <= 1'b0;
                               sb_exit <= 1'b0;
                               Start_MB <= 1'b0;
                               trainerror_hs <= 1'b0; 
                               flag <= 0;
                               flag_sb <= 0;
                               flag_mb <= 0;

                             // DATA_IN =  {End Rx Init D to C point test req}
                             end else if( (DATA_IN[21:14] == 8'h85) && (DATA_IN[39:32] == 8'h09) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                               // DATA_OUT =  {End Rx Init D to C point test resp}
                               DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h09 , DATA_IN[31:22] , 8'h8A , DATA_IN[13:0] }; 
                               Encoder_EN <= 1'b1;
                               sb_exit <= 1'b0;
                               Start_MB <= 1'b0;
                               trainerror_hs <= 1'b0;
                               flag <= 0;
                               flag_sb <= 0;
                               flag_mb <= 0;

                             // DATA_IN = {MBTRAIN.DATAVREF end req}
                             end else if( (DATA_IN[21:14] == 8'hB5) && (DATA_IN[39:32] == 8'h03) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                               // DATA_OUT = {MBTRAIN.DATAVREF end resp}
                               DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h03 , DATA_IN[31:22] , 8'hBA , DATA_IN[13:0] }; 
                               Encoder_EN <= 1'b1;          
                               Start_MB <= 1'b0;
                               trainerror_hs <= 1'b0;
                               flag <= 0;
                               flag_mb <= 0;
                               if(sb_exit_module) begin     // to wait for module sb_exit signal
                                 sb_exit <= 1'b1;
                                 flag_sb <= 0;
                               end else begin
                                 sb_exit <= 1'b0;
                                 flag_sb <= 1;
                               end

                             end else begin
                               DATA_OUT <= 64'b0;
                               trainerror_flag <= 1'b1;
                               Encoder_EN <= 1'b0;
                               sb_exit <= 1'b0;
                               Start_MB <= 1'b0;
                               trainerror_hs <= 1'b0;
                               flag <= 0;
                               flag_sb <= 0;
                               flag_mb <= 0;
                             end

                  end

		  SPEEDIDLE: begin
                               // DATA_IN = {TRAINERROR Entry req}
                               if( (DATA_IN[21:14] == 8'hE5) && (DATA_IN[39:32] == 8'h00) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                 // DATA_OUT = {TRAINERROR Entry resp}
                                 DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h00 , DATA_IN[31:22] , 8'hEA , DATA_IN[13:0] }; 
                                 Encoder_EN <= 1'b1;
                                 sb_exit <= 1'b0;
                                 trainerror_hs <= 1'b1;
                                 flag_sb <= 0;

                               // DATA_IN = {MBTRAIN.SPEEDIDLE done req}
                               end else if( (DATA_IN[21:14] == 8'hB5) && (DATA_IN[39:32] == 8'h04) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                 // DATA_OUT = {MBTRAIN.SPEEDIDLE done resp}
                                 DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h04 , DATA_IN[31:22] , 8'hBA , DATA_IN[13:0] }; 
                                 Encoder_EN <= 1'b1;
                                 trainerror_hs <= 1'b0;
                                 if(sb_exit_module) begin     // to wait for module sb_exit signal
                                   sb_exit <= 1'b1;
                                   flag_sb <= 0;
                                 end else begin
                                   sb_exit <= 1'b0;
                                   flag_sb <= 1;
                                 end

                               end else begin
                                  DATA_OUT <= 64'b0;
                                  trainerror_flag <= 1'b1;
                                  Encoder_EN <= 1'b0;
                                  sb_exit <= 1'b0;
                                  trainerror_hs <= 1'b0;
                                  flag_sb <= 0;
                               end
                              
                  end   
 
		  TXSELFCAL: begin
                               // DATA_IN = {TRAINERROR Entry req}
                               if( (DATA_IN[21:14] == 8'hE5) && (DATA_IN[39:32] == 8'h00) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                 // DATA_OUT = {TRAINERROR Entry resp}
                                 DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h00 , DATA_IN[31:22] , 8'hEA , DATA_IN[13:0] }; 
                                 Encoder_EN <= 1'b1;
                                 sb_exit <= 1'b0;
                                 trainerror_hs <= 1'b1;
                                 flag_sb <= 0;

                               // DATA_IN =  {MBTRAIN.TXSELFCAL Done req}
                               end else if( (DATA_IN[21:14] == 8'hB5) && (DATA_IN[39:32] == 8'h05) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                 // DATA_OUT =  {MBTRAIN.TXSELFCAL Done resp}
                                 DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h05 , DATA_IN[31:22] , 8'hBA , DATA_IN[13:0] }; 
                                 Encoder_EN <= 1'b1;
                                 trainerror_hs <= 1'b0;
                                 if(sb_exit_module) begin     // to wait for module sb_exit signal
                                   sb_exit <= 1'b1;
                                   flag_sb <= 0;
                                 end else begin
                                   sb_exit <= 1'b0;
                                   flag_sb <= 1;
                                 end

                               end else begin
                                 DATA_OUT <= 64'b0;
                                 trainerror_flag <= 1'b1;
                                 Encoder_EN <= 1'b0;
                                 sb_exit <= 1'b0;
                                 trainerror_hs <= 1'b0;
                                 flag_sb <= 0;
                               end

                  end   

		  RXCLKCAL: begin
                              // DATA_IN = {TRAINERROR Entry req}
                               if( (DATA_IN[21:14] == 8'hE5) && (DATA_IN[39:32] == 8'h00) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                 // DATA_OUT = {TRAINERROR Entry resp}
                                 DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h00 , DATA_IN[31:22] , 8'hEA , DATA_IN[13:0] }; 
                                 Encoder_EN <= 1'b1;
                                 sb_exit <= 1'b0;
                                 trainerror_hs <= 1'b1;
                                 flag_sb <= 0;

                              // DATA_IN = {MBTRAIN.RXCLKCAL start req}
                              end else if( (DATA_IN[21:14] == 8'hB5) && (DATA_IN[39:32] == 8'h06) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                               // DATA_OUT = {MBTRAIN.RXCLKCAL start resp}
                               DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h06 , DATA_IN[31:22] , 8'hBA , DATA_IN[13:0] }; 
                               Encoder_EN <= 1'b1;
                               sb_exit <= 1'b0;
                               trainerror_hs <= 1'b0;
                               flag_sb <= 0;

                             // DATA_IN = {MBTRAIN.RXCLKCAL done req}
                             end else if( (DATA_IN[21:14] == 8'hB5) && (DATA_IN[39:32] == 8'h07) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                               // DATA_OUT = {MBTRAIN.RXCLKCAL done resp}
                               DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h07 , DATA_IN[31:22] , 8'hBA , DATA_IN[13:0] }; 
                               Encoder_EN <= 1'b1;
                               trainerror_hs <= 1'b0;
                               if(sb_exit_module) begin     // to wait for module sb_exit signal
                                  sb_exit <= 1'b1;
                                  flag_sb <= 0;
                               end else begin
                                  sb_exit <= 1'b0;
                                  flag_sb <= 1;
                               end

                             end else begin
                               DATA_OUT <= 64'b0;
                               trainerror_flag <= 1'b1;
                               Encoder_EN <= 1'b0;
                               sb_exit <= 1'b0;
                               trainerror_hs <= 1'b0;
                               flag_sb <= 0;
                             end

                  end    
  
		  VALTRAINCENTER: begin
                                    // DATA_IN = {TRAINERROR Entry req}
                                    if( (DATA_IN[21:14] == 8'hE5) && (DATA_IN[39:32] == 8'h00) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                      // DATA_OUT = {TRAINERROR Entry resp}
                                      DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h00 , DATA_IN[31:22] , 8'hEA , DATA_IN[13:0] }; 
                                      Encoder_EN <= 1'b1;
                                      sb_exit <= 1'b0;
                                      trainerror_hs <= 1'b1;
                                      flag <= 0;
                                      flag_sb <= 0;

                                    // DATA_IN = {MBTRAIN.VALTRAINCENTER start req}
                                    end else if( (DATA_IN[21:14] == 8'hB5) && (DATA_IN[39:32] == 8'h08) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                      // DATA_IN = {MBTRAIN.VALTRAINCENTER start resp}
                                      DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h08 , DATA_IN[31:22] , 8'hBA , DATA_IN[13:0] }; 
                                      Encoder_EN <= 1'b1;
                                      sb_exit <= 1'b0;
                                      trainerror_hs <= 1'b0;
                                      flag <= 0;
                                      flag_sb <= 0;

                                    // DATA_IN = {Start Tx Init D to C point test req}
                                    end else if( (DATA_IN[21:14] == 8'h85) && (DATA_IN[39:32] == 8'h01) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                       flag <= 1;  // to wait for the 64 bit of data 
                                       Error_Threshold <= DATA_IN[55:40];
                                       DATA_IN_reg <= DATA_IN;       //storing the msg 
                                       flag_sb <= 0;

                                    end else if( flag && !error ) begin
                                      flag <= 0;
                                      // DATA_OUT = {Start Tx Init D to C point test resp}
                                      DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN_reg[61:56] , 15'h0000 , 8'h01 , DATA_IN_reg[31:22] , 8'h8A , DATA_IN_reg[13:0] }; 
                                      Encoder_EN <= 1'b1;
                                      sb_exit <= 1'b0;
                                      trainerror_hs <= 1'b0;
                                      flag_sb <= 0;

                                   // DATA_IN = {LFSR_clear_error req}
                                   end else if( (DATA_IN[21:14] == 8'h85) && (DATA_IN[39:32] == 8'h02) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                      // DATA_OUT = {LFSR_clear_error resp}
                                      DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h02 , DATA_IN[31:22] , 8'h8A , DATA_IN[13:0] }; 
                                      Encoder_EN <= 1'b1;
                                      sb_exit <= 1'b0;
                                      trainerror_hs <= 1'b0;
                                      flag_sb <= 0;
                                      flag_2 <= 0;
                                      flag <= 0; 

                                    // DATA_IN = {Tx Init D to C results req}
                                    end else if( (DATA_IN[21:14] == 8'h85) && (DATA_IN[39:32] == 8'h03) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                             
                                        // DATA_OUT = {Tx Init D to C results resp}
                                        if (failed) begin    // valid test failed "valid bit is 0"
                                          DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:46] , 1'b0 , DATA_IN[44:40] , 8'h03 , DATA_IN[31:22] , 8'h8A , DATA_IN[13:0] }; 
                                          Encoder_EN <= 1'b1;
                                          sb_exit <= 1'b0;
                                          trainerror_hs <= 1'b0;
                                          flag <= 0;
                                          flag_2 <= 1;    // to send the remainig data part of the resp in the next cycle 
                                          flag_sb <= 0;
                                        end else begin    // valid test passed "valid bit is 1"
                                          DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:46] , 1'b1 , DATA_IN[44:40] , 8'h03 , DATA_IN[31:22] , 8'h8A , DATA_IN[13:0] }; 
                                          Encoder_EN <= 1'b1;
                                          sb_exit <= 1'b0;
                                          trainerror_hs <= 1'b0;
                                          flag <= 0;
                                          flag_2 <= 1;
                                          flag_sb <= 0;
                                        end 

                                   // DATA_IN =  {End Tx Init D to C point test req}
                                   end else if( (DATA_IN[21:14] == 8'h85) && (DATA_IN[39:32] == 8'h04) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                     // DATA_OUT = {End Tx Init D to C point test resp}
                                     DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h04 , DATA_IN[31:22] , 8'h8A , DATA_IN[13:0] }; 
                                     Encoder_EN <= 1'b1;
                                     sb_exit <= 1'b0;
                                     trainerror_hs <= 1'b0;
                                     flag <= 0;
                                     flag_sb <= 0;

                                   // DATA_IN = {MBTRAIN.VALTRAINCENTER done req}
                                   end else if( (DATA_IN[21:14] == 8'hB5) && (DATA_IN[39:32] == 8'h09) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                      // DATA_IN = {MBTRAIN.VALTRAINCENTER done resp}
                                      DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h09 , DATA_IN[31:22] , 8'hBA , DATA_IN[13:0] }; 
                                      Encoder_EN <= 1'b1;
                                      trainerror_hs <= 1'b0;
                                      flag <= 0;
                                      if(sb_exit_module) begin     // to wait for module sb_exit signal
                                        sb_exit <= 1'b1;
                                        flag_sb <= 0;
                                      end else begin
                                        sb_exit <= 1'b0;
                                        flag_sb <= 1;
                                      end

                                   end else begin
                                       DATA_OUT <= 64'b0;
                                       trainerror_flag <= 1'b1;
                                       Encoder_EN <= 1'b0;
                                       sb_exit <= 1'b0;
                                       trainerror_hs <= 1'b0;
                                       flag <= 0;
                                       flag_sb <= 0;
                                    end

                  end 
  
		  VALTRAINVREF: begin
                                   // DATA_IN = {TRAINERROR Entry req}
                                   if( (DATA_IN[21:14] == 8'hE5) && (DATA_IN[39:32] == 8'h00) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                      // DATA_OUT = {TRAINERROR Entry resp}
                                      DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h00 , DATA_IN[31:22] , 8'hEA , DATA_IN[13:0] }; 
                                      Encoder_EN <= 1'b1;
                                      sb_exit <= 1'b0;
                                      Start_MB <= 1'b0;
                                      trainerror_hs <= 1'b1;
                                      flag <= 0;
                                      flag_sb <= 0;
                                      flag_mb <= 0;

                                   // DATA_IN = {MBTRAIN.VALTRAINVREF start req}
                                   end else if( (DATA_IN[21:14] == 8'hB5) && (DATA_IN[39:32] == 8'h0A) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                      // DATA_OUT = {MBTRAIN.VALTRAINVREF start resp}
                                      DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h0A , DATA_IN[31:22] , 8'hBA , DATA_IN[13:0] }; 
                                      Encoder_EN <= 1'b1;
                                      sb_exit <= 1'b0;
                                      Start_MB <= 1'b0;
                                      trainerror_hs <= 1'b0;
                                      flag <= 0;
                                      flag_sb <= 0;
                                      flag_mb <= 0;

                                   // DATA_IN = {Start Rx Init D to C point test req}
                                   end else if( (DATA_IN[21:14] == 8'h85) && (DATA_IN[39:32] == 8'h07) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                     flag <= 1;  // to wait for the 64 bit of data 
                                     DATA_IN_reg <= DATA_IN;       //storing the msg 
                                     flag_sb <= 0;
                                     flag_mb <= 0;

                                   end else if( flag && !error ) begin
                                     flag <= 0;
                                     // DATA_OUT = {Start Rx Init D to C point test resp}
                                     DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN_reg[61:56] , 15'h0000 , 8'h07 , DATA_IN_reg[31:22] , 8'h8A , DATA_IN_reg[13:0] }; 
                                     Encoder_EN <= 1'b1;
                                     sb_exit <= 1'b0;
                                     Start_MB <= 1'b0;
                                     trainerror_hs <= 1'b0;
                                     flag_sb <= 0;
                                     flag_mb <= 0;

                                // DATA_IN = {LFSR_clear_error req}
                                end else if( (DATA_IN[21:14] == 8'h85) && (DATA_IN[39:32] == 8'h02) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                    // DATA_OUT = {LFSR_clear_error resp}
                                    DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h02 , DATA_IN[31:22] , 8'h8A , DATA_IN[13:0] }; 
                                    Encoder_EN <= 1'b1;
                                    sb_exit <= 1'b0;
                                    Start_MB <= 1'b1;
                                    flag_mb <= 1;
                                    flag_sb <= 0;
                                    flag <= 0; 

                                  // DATA_IN = {Rx Init D to C Tx Count Done resp}
                                  end else if( (DATA_IN[21:14] == 8'h8A) && (DATA_IN[39:32] == 8'h08) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                    // DATA_OUT
                                    DATA_OUT <= 64'b0;
                                    Encoder_EN <= 1'b0;
                                    sb_exit <= 1'b0;
                                    Start_MB <= 1'b0;
                                    trainerror_hs <= 1'b0; 
                                    flag <= 0;
                                    flag_sb <= 0;
                                    flag_mb <= 0;

                                  // DATA_IN =  {End Rx Init D to C point test req}
                                  end else if( (DATA_IN[21:14] == 8'h85) && (DATA_IN[39:32] == 8'h09) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                   // DATA_OUT =  {End Rx Init D to C point test resp}
                                   DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h09 , DATA_IN[31:22] , 8'h8A , DATA_IN[13:0] }; 
                                   Encoder_EN <= 1'b1;
                                   sb_exit <= 1'b0;
                                   Start_MB <= 1'b0;
                                   trainerror_hs <= 1'b0;
                                   flag <= 0;
                                   flag_sb <= 0;
                                   flag_mb <= 0;

                                 // DATA_IN =  {MBTRAIN.VALTRAINVREF done req}
                                 end else if( (DATA_IN[21:14] == 8'hB5) && (DATA_IN[39:32] == 8'h0B) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                   // DATA_OUT = {MBTRAIN.VALTRAINVREF done resp}
                                   DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h0B , DATA_IN[31:22] , 8'hBA , DATA_IN[13:0] }; 
                                   Encoder_EN <= 1'b1;
                                   Start_MB <= 1'b0;
                                   trainerror_hs <= 1'b0;
                                   flag <= 0;
                                   flag_mb <= 0;
                                   if(sb_exit_module) begin     // to wait for module sb_exit signal
                                     sb_exit <= 1'b1;
                                     flag_sb <= 0;
                                   end else begin
                                     sb_exit <= 1'b0;
                                     flag_sb <= 1;
                                   end

                                 end else begin
                                    DATA_OUT <= 64'b0;
                                    trainerror_flag <= 1'b1;
                                    Encoder_EN <= 1'b0;
                                    sb_exit <= 1'b0;
                                    Start_MB <= 1'b0;
                                    trainerror_hs <= 1'b0;
                                    flag <= 0;
                                    flag_sb <= 0;
                                    flag_mb <= 0;
                                 end

                  end  

		  DATATRAINCENTER1: begin
                                      // DATA_IN = {TRAINERROR Entry req}
                                      if( (DATA_IN[21:14] == 8'hE5) && (DATA_IN[39:32] == 8'h00) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                        // DATA_OUT = {TRAINERROR Entry resp}
                                        DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h00 , DATA_IN[31:22] , 8'hEA , DATA_IN[13:0] }; 
                                        Encoder_EN <= 1'b1;
                                        sb_exit <= 1'b0;
                                        trainerror_hs <= 1'b1;
                                        flag_sb <= 0;

                                      // DATA_IN = {MBTRAIN.DATATRAINCENTER1 start req}
                                      end else if( (DATA_IN[21:14] == 8'hB5) && (DATA_IN[39:32] == 8'h0C) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                        // DATA_OUT = {MBTRAIN.DATATRAINCENTER1 start resp}
                                        DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h0C , DATA_IN[31:22] , 8'hBA , DATA_IN[13:0] }; 
                                        Encoder_EN <= 1'b1;
                                        sb_exit <= 1'b0;
                                        trainerror_hs <= 1'b0;
                                        flag_sb <= 0;

                                      // DATA_IN = {Start Tx Init D to C point test req}
                                      end else if( (DATA_IN[21:14] == 8'h85) && (DATA_IN[39:32] == 8'h01) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                        flag <= 1;  // to wait for the 64 bit of data 
                                        Error_Threshold <= DATA_IN[55:40];
                                        DATA_IN_reg <= DATA_IN;       //storing the msg 
                                        flag_sb <= 0;

                                      end else if( flag && !error ) begin
                                        flag <= 0;
                                        // DATA_OUT = {Start Tx Init D to C point test resp}
                                        DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN_reg[61:56] , 15'h0000 , 8'h01 , DATA_IN_reg[31:22] , 8'h8A , DATA_IN_reg[13:0] }; 
                                        Encoder_EN <= 1'b1;
                                        sb_exit <= 1'b0;
                                        trainerror_hs <= 1'b0;
                                        flag_sb <= 0;

                                     // DATA_IN = {LFSR_clear_error req}
                                     end else if( (DATA_IN[21:14] == 8'h85) && (DATA_IN[39:32] == 8'h02) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                        // DATA_OUT = {LFSR_clear_error resp}
                                        DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h02 , DATA_IN[31:22] , 8'h8A , DATA_IN[13:0] }; 
                                        Encoder_EN <= 1'b1;
                                        sb_exit <= 1'b0;
                                        trainerror_hs <= 1'b0;
                                        flag_sb <= 0;
                                        flag_2 <= 0;
                                        flag <= 0; 

                                      // DATA_IN = {Tx Init D to C results req}
                                      end else if( (DATA_IN[21:14] == 8'h85) && (DATA_IN[39:32] == 8'h03) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                          // DATA_OUT = {Tx Init D to C results resp}
                                          // LFSR test passed "status bit is 1"    // LFSR test failed "status bit is 0"
                                          DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:45] , status , DATA_IN[43:40] , 8'h03 , DATA_IN[31:22] , 8'h8A , DATA_IN[13:0] }; 
                                          Encoder_EN <= 1'b1;
                                          sb_exit <= 1'b0;
                                          trainerror_hs <= 1'b0;
                                          flag <= 0;
                                          flag_2 <= 1;    // to send the remainig data part of the resp in the next cycle 
                                          flag_sb <= 0;

                                      // DATA_IN =  {End Tx Init D to C point test req}
                                      end else if( (DATA_IN[21:14] == 8'h85) && (DATA_IN[39:32] == 8'h04) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                        // DATA_OUT = {End Tx Init D to C point test resp}
                                        DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h04 , DATA_IN[31:22] , 8'h8A , DATA_IN[13:0] }; 
                                        Encoder_EN <= 1'b1;
                                        sb_exit <= 1'b0;
                                        trainerror_hs <= 1'b0;
                                        flag <= 0;
                                        flag_sb <= 0;

                                       // DATA_IN = {MBTRAIN.DATATRAINCENTER1 end req}
                                       end else if( (DATA_IN[21:14] == 8'hB5) && (DATA_IN[39:32] == 8'h0D) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                         // DATA_OUT = {MBTRAIN.DATATRAINCENTER1 end resp}
                                         DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h0D , DATA_IN[31:22] , 8'hBA , DATA_IN[13:0] }; 
                                         Encoder_EN <= 1'b1;
                                         trainerror_hs <= 1'b0;
                                         flag <= 0;
                                         if(sb_exit_module) begin     // to wait for module sb_exit signal
                                           sb_exit <= 1'b1;
                                           flag_sb <= 0;
                                         end else begin
                                           sb_exit <= 1'b0;
                                           flag_sb <= 1;
                                         end

                                       end else begin
                                          DATA_OUT <= 64'b0;
                                          trainerror_flag <= 1'b1;
                                          Encoder_EN <= 1'b0;
                                          sb_exit <= 1'b0;
                                          trainerror_hs <= 1'b0;
                                          flag <= 0;
                                          flag_sb <= 0;
                                       end

                  end

		  DATATRAINVREF: begin
                                    // DATA_IN = {TRAINERROR Entry req}
                                    if( (DATA_IN[21:14] == 8'hE5) && (DATA_IN[39:32] == 8'h00) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                      // DATA_OUT = {TRAINERROR Entry resp}
                                      DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h00 , DATA_IN[31:22] , 8'hEA , DATA_IN[13:0] }; 
                                      Encoder_EN <= 1'b1;
                                      sb_exit <= 1'b0;
                                      Start_MB <= 1'b0;
                                      trainerror_hs <= 1'b1;
                                      flag <= 0;
                                      flag_sb <= 0;
                                      flag_mb <= 0;

                                     // DATA_IN = {MBTRAIN.DATATRAINVREF start req}
                                     end else if( (DATA_IN[21:14] == 8'hB5) && (DATA_IN[39:32] == 8'h0E) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                        // DATA_OUT = {MBTRAIN.DATATRAINVREF start resp}
                                        DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h0E , DATA_IN[31:22] , 8'hBA , DATA_IN[13:0] }; 
                                        Encoder_EN <= 1'b1;
                                        sb_exit <= 1'b0;
                                        Start_MB <= 1'b0;
                                        trainerror_hs <= 1'b0;
                                        flag <= 0;
                                        flag_sb <= 0;
                                        flag_mb <= 0;

                                     // DATA_IN = {Start Rx Init D to C point test req}
                                     end else if( (DATA_IN[21:14] == 8'h85) && (DATA_IN[39:32] == 8'h07) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                       flag <= 1;  // to wait for the 64 bit of data 
                                       DATA_IN_reg <= DATA_IN;       //storing the msg 
                                       flag_sb <= 0;
                                       flag_mb <= 0;

                                     end else if( flag && !error ) begin
                                       flag <= 0;
                                       // DATA_OUT = {Start Rx Init D to C point test resp}
                                       DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN_reg[61:56] , 15'h0000 , 8'h07 , DATA_IN_reg[31:22] , 8'h8A , DATA_IN_reg[13:0] }; 
                                       Encoder_EN <= 1'b1;
                                       sb_exit <= 1'b0;
                                       Start_MB <= 1'b0;
                                       trainerror_hs <= 1'b0;
                                       flag_sb <= 0;
                                       flag_mb <= 0;

                                   // DATA_IN = {LFSR_clear_error req}
                                   end else if( (DATA_IN[21:14] == 8'h85) && (DATA_IN[39:32] == 8'h02) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                      // DATA_OUT = {LFSR_clear_error resp}
                                      DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h02 , DATA_IN[31:22] , 8'h8A , DATA_IN[13:0] }; 
                                      Encoder_EN <= 1'b1;
                                      sb_exit <= 1'b0;
                                      Start_MB <= 1'b1;
                                      flag_mb <= 1;
                                      flag_sb <= 0;
                                      flag <= 0; 

                                   // DATA_IN = {Rx Init D to C Tx Count Done resp}
                                   end else if( (DATA_IN[21:14] == 8'h8A) && (DATA_IN[39:32] == 8'h08) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                      // DATA_OUT
                                      DATA_OUT <= 64'b0;
                                      Encoder_EN <= 1'b0;
                                      sb_exit <= 1'b0;
                                      Start_MB <= 1'b0;
                                      trainerror_hs <= 1'b0; 
                                      flag <= 0;
                                      flag_sb <= 0;
                                      flag_mb <= 0;

                                   // DATA_IN =  {End Rx Init D to C point test req}
                                   end else if( (DATA_IN[21:14] == 8'h85) && (DATA_IN[39:32] == 8'h09) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                      // DATA_OUT =  {End Rx Init D to C point test resp}
                                      DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h09 , DATA_IN[31:22] , 8'h8A , DATA_IN[13:0] }; 
                                      Encoder_EN <= 1'b1;
                                      sb_exit <= 1'b0;
                                      Start_MB <= 1'b0;
                                      trainerror_hs <= 1'b0;
                                      flag <= 0;
                                      flag_sb <= 0;
                                      flag_mb <= 0;

                                    // DATA_IN = {MBTRAIN.DATATRAINVREF end req}
                                    end else if( (DATA_IN[21:14] == 8'hB5) && (DATA_IN[39:32] == 8'h10) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                       // DATA_OUT = {MBTRAIN.DATATRAINVREF end resp}
                                       DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h10 , DATA_IN[31:22] , 8'hBA , DATA_IN[13:0] }; 
                                       Encoder_EN <= 1'b1;
                                       Start_MB <= 1'b0;
                                       trainerror_hs <= 1'b0;
                                       flag <= 0;
                                       flag_mb <= 0;
                                       if(sb_exit_module) begin     // to wait for module sb_exit signal
                                           sb_exit <= 1'b1;
                                           flag_sb <= 0;
                                       end else begin
                                           sb_exit <= 1'b0;
                                           flag_sb <= 1;
                                       end

                                     end else begin
                                        DATA_OUT <= 64'b0;
                                        trainerror_flag <= 1'b1;
                                        Encoder_EN <= 1'b0;
                                        sb_exit <= 1'b0;
                                        Start_MB <= 1'b0;
                                        trainerror_hs <= 1'b0;
                                        flag <= 0;
                                        flag_sb <= 0;
                                        flag_mb <= 0;
                                     end

                  end

		  RXDESKEW: begin
                            // DATA_IN = {TRAINERROR Entry req}
                            if( (DATA_IN[21:14] == 8'hE5) && (DATA_IN[39:32] == 8'h00) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                // DATA_OUT = {TRAINERROR Entry resp}
                                DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h00 , DATA_IN[31:22] , 8'hEA , DATA_IN[13:0] }; 
                                Encoder_EN <= 1'b1;
                                sb_exit <= 1'b0;
                                Start_MB <= 1'b0;
                                trainerror_hs <= 1'b1;
                                flag <= 0;
                                flag_sb <= 0;
                                flag_mb <= 0;

                             // DATA_IN = {MBTRAIN.RXDESKEW start req}
                             end else if( (DATA_IN[21:14] == 8'hB5) && (DATA_IN[39:32] == 8'h11) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                // DATA_OUT = {MBTRAIN.RXDESKEW start resp}
                                DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h11 , DATA_IN[31:22] , 8'hBA , DATA_IN[13:0] }; 
                                Encoder_EN <= 1'b1;
                                sb_exit <= 1'b0;
                                Start_MB <= 1'b0;
                                trainerror_hs <= 1'b0;
                                flag <= 0;
                                flag_sb <= 0;
                                flag_mb <= 0;

                             // DATA_IN = {Start Rx Init D to C point test req}
                             end else if( (DATA_IN[21:14] == 8'h85) && (DATA_IN[39:32] == 8'h07) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                 flag <= 1;  // to wait for the 64 bit of data of the msg req
                                 DATA_IN_reg <= DATA_IN;       //storing the msg 
                                 flag_sb <= 0;
                                 flag_mb <= 0;

                             end else if( flag && !error ) begin
                                 flag <= 0;
                                 // DATA_OUT = {Start Rx Init D to C point test resp}
                                 DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN_reg[61:56] , 15'h0000 , 8'h07 , DATA_IN_reg[31:22] , 8'h8A , DATA_IN_reg[13:0] }; 
                                 Encoder_EN <= 1'b1;
                                 sb_exit <= 1'b0;
                                 Start_MB <= 1'b0;
                                 trainerror_hs <= 1'b0;
                                 flag_sb <= 0;
                                 flag_mb <= 0;

                              // DATA_IN = {LFSR_clear_error req}
                              end else if( (DATA_IN[21:14] == 8'h85) && (DATA_IN[39:32] == 8'h02) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                 // DATA_OUT = {LFSR_clear_error resp}
                                 DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h02 , DATA_IN[31:22] , 8'h8A , DATA_IN[13:0] }; 
                                 Encoder_EN <= 1'b1;
                                 sb_exit <= 1'b0;
                                 Start_MB <= 1'b1;
                                 flag_mb <= 1;
                                 flag_sb <= 0;
                                 flag <= 0; 

                              // DATA_IN = {Rx Init D to C Tx Count Done resp}
                              end else if( (DATA_IN[21:14] == 8'h8A) && (DATA_IN[39:32] == 8'h08) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                  // DATA_OUT
                                  DATA_OUT <= 64'b0;
                                  Encoder_EN <= 1'b0;
                                  sb_exit <= 1'b0;
                                  Start_MB <= 1'b0;
                                  trainerror_hs <= 1'b0; 
                                  flag <= 0;
                                  flag_sb <= 0;
                                  flag_mb <= 0;

                              // DATA_IN =  {End Rx Init D to C point test req}
                              end else if( (DATA_IN[21:14] == 8'h85) && (DATA_IN[39:32] == 8'h09) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                  // DATA_OUT =  {End Rx Init D to C point test resp}
                                  DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h09 , DATA_IN[31:22] , 8'h8A , DATA_IN[13:0] }; 
                                  Encoder_EN <= 1'b1;
                                  sb_exit <= 1'b0;
                                  Start_MB <= 1'b0;
                                  trainerror_hs <= 1'b0;
                                  flag <= 0;
                                  flag_sb <= 0;
                                  flag_mb <= 0;

                             // DATA_IN = {MBTRAIN.RXDESKEW end req}
                             end else if( (DATA_IN[21:14] == 8'hB5) && (DATA_IN[39:32] == 8'h12) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                // DATA_OUT = {MBTRAIN.RXDESKEW end resp}
                                DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h12 , DATA_IN[31:22] , 8'hBA , DATA_IN[13:0] }; 
                                Encoder_EN <= 1'b1;
                                Start_MB <= 1'b0;
                                trainerror_hs <= 1'b0;
                                flag <= 0;
                                flag_mb <= 0;
                                if(sb_exit_module) begin     // to wait for module sb_exit signal
                                  sb_exit <= 1'b1;
                                  flag_sb <= 0;
                                end else begin
                                  sb_exit <= 1'b0;
                                  flag_sb <= 1;
                                end

                              end else begin
                                 DATA_OUT <= 64'b0;
                                 trainerror_flag <= 1'b1;
                                 Encoder_EN <= 1'b0;
                                 sb_exit <= 1'b0;
                                 Start_MB <= 1'b0;
                                 trainerror_hs <= 1'b0;
                                 flag <= 0;
                                 flag_sb <= 0;
                                 flag_mb <= 0;
                              end

                  end

		  DATATRAINCENTER2: begin
                                     // DATA_IN = {TRAINERROR Entry req}
                                     if( (DATA_IN[21:14] == 8'hE5) && (DATA_IN[39:32] == 8'h00) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                       // DATA_OUT = {TRAINERROR Entry resp}
                                       DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h00 , DATA_IN[31:22] , 8'hEA , DATA_IN[13:0] }; 
                                       Encoder_EN <= 1'b1;
                                       sb_exit <= 1'b0;
                                       trainerror_hs <= 1'b1;
                                       flag <= 0;
                                       flag_sb <= 0;

                                     // DATA_IN = {MBTRAIN.DATATRAINCENTER2 start req}
                                     end else if( (DATA_IN[21:14] == 8'hB5) && (DATA_IN[39:32] == 8'h13) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                       // DATA_OUT = {MBTRAIN.DATATRAINCENTER2 start resp}
                                       DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h13 , DATA_IN[31:22] , 8'hBA , DATA_IN[13:0] }; 
                                       Encoder_EN <= 1'b1;
                                       sb_exit <= 1'b0;
                                       trainerror_hs <= 1'b0;
                                       flag <= 0;
                                       flag_sb <= 0;

                                     // DATA_IN = {Start Tx Init D to C point test req}
                                      end else if( (DATA_IN[21:14] == 8'h85) && (DATA_IN[39:32] == 8'h01) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                        flag <= 1;  // to wait for the 64 bit of data 
                                        Error_Threshold <= DATA_IN[55:40];
                                        DATA_IN_reg <= DATA_IN;       //storing the msg 
                                        flag_sb <= 0;

                                      end else if( flag && !error ) begin
                                        flag <= 0;
                                        // DATA_OUT = {Start Tx Init D to C point test resp}
                                        DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN_reg[61:56] , 15'h0000 , 8'h01 , DATA_IN_reg[31:22] , 8'h8A , DATA_IN_reg[13:0] }; 
                                        Encoder_EN <= 1'b1;
                                        sb_exit <= 1'b0;
                                        trainerror_hs <= 1'b0;
                                        flag_sb <= 0;

                                     // DATA_IN = {LFSR_clear_error req}
                                     end else if( (DATA_IN[21:14] == 8'h85) && (DATA_IN[39:32] == 8'h02) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                        // DATA_OUT = {LFSR_clear_error resp}
                                        DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h02 , DATA_IN[31:22] , 8'h8A , DATA_IN[13:0] }; 
                                        Encoder_EN <= 1'b1;
                                        sb_exit <= 1'b0;
                                        trainerror_hs <= 1'b0;
                                        flag_sb <= 0;
                                        flag_2 <= 0;
                                        flag <= 0;

                                      // DATA_IN = {Tx Init D to C results req}
                                      end else if( (DATA_IN[21:14] == 8'h85) && (DATA_IN[39:32] == 8'h03) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                          // DATA_OUT = {Tx Init D to C results resp}
                                          // LFSR test passed "status bit is 1"    // LFSR test failed "status bit is 0"
                                          DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:45] , status , DATA_IN[43:40] , 8'h03 , DATA_IN[31:22] , 8'h8A , DATA_IN[13:0] }; 
                                          Encoder_EN <= 1'b1;
                                          sb_exit <= 1'b0;
                                          trainerror_hs <= 1'b0;
                                          flag <= 0;
                                          flag_2 <= 1;    // to send the remainig data part of the resp in the next cycle
                                          flag_sb <= 0;

                                      // DATA_IN =  {End Tx Init D to C point test req}
                                      end else if( (DATA_IN[21:14] == 8'h85) && (DATA_IN[39:32] == 8'h04) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                        // DATA_OUT = {End Tx Init D to C point test resp}
                                        DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h04 , DATA_IN[31:22] , 8'h8A , DATA_IN[13:0] }; 
                                        Encoder_EN <= 1'b1;
                                        sb_exit <= 1'b0;
                                        trainerror_hs <= 1'b0;
                                        flag <= 0;
                                        flag_sb <= 0;

                                     // DATA_IN = {MBTRAIN.DATATRAINCENTER2 end req}
                                     end else if( (DATA_IN[21:14] == 8'hB5) && (DATA_IN[39:32] == 8'h14) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                        // DATA_OUT = {MBTRAIN.DATATRAINCENTER2 end resp}
                                        DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h14 , DATA_IN[31:22] , 8'hBA , DATA_IN[13:0] }; 
                                        Encoder_EN <= 1'b1;
                                        trainerror_hs <= 1'b0;
                                        flag <= 0;
                                        if(sb_exit_module) begin     // to wait for module sb_exit signal
                                           sb_exit <= 1'b1;
                                           flag_sb <= 0;
                                        end else begin
                                           sb_exit <= 1'b0;
                                           flag_sb <= 1;
                                        end

                                     end else begin
                                        DATA_OUT <= 64'b0;
                                        trainerror_flag <= 1'b1;
                                        Encoder_EN <= 1'b0;
                                        sb_exit <= 1'b0;
                                        trainerror_hs <= 1'b0;
                                        flag <= 0;
                                        flag_sb <= 0;
                                     end

                  end

		  LINKSPEED: begin
                              // DATA_IN = {TRAINERROR Entry req}
                              if( (DATA_IN[21:14] == 8'hE5) && (DATA_IN[39:32] == 8'h00) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                // DATA_OUT = {TRAINERROR Entry resp}
                                DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h00 , DATA_IN[31:22] , 8'hEA , DATA_IN[13:0] }; 
                                Encoder_EN <= 1'b1;
                                sb_exit <= 1'b0;
                                trainerror_hs <= 1'b1;
                                flag <= 0;
                                PhyRetrain_req <= 1'b0;
                                SpeedIdle_req <= 1'b0;
                                Repair_req <= 1'b0;
                                flag_sb <= 0;

                              // DATA_IN = {MBTRAIN.LINKSPEED start req}
                              end else if( (DATA_IN[21:14] == 8'hB5) && (DATA_IN[39:32] == 8'h15) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                  // DATA_OUT = {MBTRAIN.LINKSPEED start resp}
                                   DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h15 , DATA_IN[31:22] , 8'hBA , DATA_IN[13:0] }; 
                                   Encoder_EN <= 1'b1;
                                   sb_exit <= 1'b0;
                                   trainerror_hs <= 1'b0;
                                   flag <= 0;
                                   PhyRetrain_req <= 1'b0;
                                   SpeedIdle_req <= 1'b0;
                                   Repair_req <= 1'b0;
                                   flag_sb <= 0;

                              // DATA_IN = {Start Tx Init D to C point test req}
                              end else if( (DATA_IN[21:14] == 8'h85) && (DATA_IN[39:32] == 8'h01) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                  flag <= 1;  // to wait for the 64 bit of data 
                                  Error_Threshold <= DATA_IN[55:40];
                                  DATA_IN_reg <= DATA_IN;       //storing the msg 
                                  PhyRetrain_req <= 1'b0;
                                  SpeedIdle_req <= 1'b0;
                                  Repair_req <= 1'b0;
                                  flag_sb <= 0;

                               end else if( flag && !error ) begin
                                   flag <= 0;
                                   // DATA_OUT = {Start Tx Init D to C point test resp}
                                   DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN_reg[61:56] , 15'h0000 , 8'h01 , DATA_IN_reg[31:22] , 8'h8A , DATA_IN_reg[13:0] }; 
                                   Encoder_EN <= 1'b1;
                                   sb_exit <= 1'b0;
                                   trainerror_hs <= 1'b0;
                                   PhyRetrain_req <= 1'b0;
                                   SpeedIdle_req <= 1'b0;
                                   Repair_req <= 1'b0;
                                   flag_sb <= 0;

                               // DATA_IN = {LFSR_clear_error req}
                               end else if( (DATA_IN[21:14] == 8'h85) && (DATA_IN[39:32] == 8'h02) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                   // DATA_OUT = {LFSR_clear_error resp}
                                   DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h02 , DATA_IN[31:22] , 8'h8A , DATA_IN[13:0] }; 
                                   Encoder_EN <= 1'b1;
                                   sb_exit <= 1'b0;
                                   trainerror_hs <= 1'b0;
                                   PhyRetrain_req <= 1'b0;
                                   SpeedIdle_req <= 1'b0;
                                   Repair_req <= 1'b0;
                                   flag_sb <= 0;
                                   flag_2 <= 0;
                                   flag <= 0;

                                // DATA_IN = {Tx Init D to C results req}
                                end else if( (DATA_IN[21:14] == 8'h85) && (DATA_IN[39:32] == 8'h03) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                    // DATA_OUT = {Tx Init D to C results resp}
                                    // LFSR test passed "status bit is 1"    // LFSR test failed "status bit is 0"
                                    DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:45] , status , DATA_IN[43:40] , 8'h03 , DATA_IN[31:22] , 8'h8A , DATA_IN[13:0] }; 
                                    Encoder_EN <= 1'b1;
                                    sb_exit <= 1'b0;
                                    trainerror_hs <= 1'b0;
                                    flag <= 0;
                                    flag_2 <= 1;    // to send the remainig data part of the resp in the next cycle
                                    PhyRetrain_req <= 1'b0;
                                    SpeedIdle_req <= 1'b0;
                                    Repair_req <= 1'b0;
                                    flag_sb <= 0;

                                 // DATA_IN =  {End Tx Init D to C point test req}
                                 end else if( (DATA_IN[21:14] == 8'h85) && (DATA_IN[39:32] == 8'h04) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                     // DATA_OUT = {End Tx Init D to C point test resp}
                                     DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h04 , DATA_IN[31:22] , 8'h8A , DATA_IN[13:0] }; 
                                     Encoder_EN <= 1'b1;
                                     sb_exit <= 1'b0;
                                     trainerror_hs <= 1'b0;
                                     flag <= 0;
                                     PhyRetrain_req <= 1'b0;
                                     SpeedIdle_req <= 1'b0;
                                     Repair_req <= 1'b0;  
                                     flag_sb <= 0;

                                 // DATA_IN = {MBTRAIN.LINKSPEED exit to phy retrain req}
                                 end else if( (DATA_IN[21:14] == 8'hB5) && (DATA_IN[39:32] == 8'h1F) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                     // DATA_OUT = {MBTRAIN.LINKSPEED exit to phy retrain resp}
                                     DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h1F , DATA_IN[31:22] , 8'hBA , DATA_IN[13:0] }; 
                                     Encoder_EN <= 1'b1;
                                     sb_exit <= 1'b0;
                                     trainerror_hs <= 1'b0;
                                     flag <= 0;
                                     PhyRetrain_req <= 1'b1;
                                     SpeedIdle_req <= 1'b0;
                                     Repair_req <= 1'b0;
                                     flag_sb <= 0;

                                 // DATA_IN = {MBTRAIN.LINKSPEED error req}
                                 end else if( (DATA_IN[21:14] == 8'hB5) && (DATA_IN[39:32] == 8'h16) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                     // DATA_OUT = {MBTRAIN.LINKSPEED error resp}
                                     DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h16 , DATA_IN[31:22] , 8'hBA , DATA_IN[13:0] }; 
                                     Encoder_EN <= 1'b1;
                                     sb_exit <= 1'b0;
                                     trainerror_hs <= 1'b0;
                                     flag <= 0;
                                     PhyRetrain_req <= 1'b0;
                                     SpeedIdle_req <= 1'b0;
                                     Repair_req <= 1'b0;
                                     flag_sb <= 0;

                                 // DATA_IN = {MBTRAIN.LINKSPEED exit to speed degrade req}
                                 end else if( (DATA_IN[21:14] == 8'hB5) && (DATA_IN[39:32] == 8'h18) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                     // DATA_OUT = {MBTRAIN.LINKSPEED exit to speed degrade resp}
                                     DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h18 , DATA_IN[31:22] , 8'hBA , DATA_IN[13:0] }; 
                                     Encoder_EN <= 1'b1;
                                     sb_exit <= 1'b0;
                                     trainerror_hs <= 1'b0;
                                     flag <= 0;
                                     PhyRetrain_req <= 1'b0;
                                     SpeedIdle_req <= 1'b1;
                                     Repair_req <= 1'b0;
                                     flag_sb <= 0;

                                 // DATA_IN = {MBTRAIN.LINKSPEED exit to repair req}
                                 end else if( (DATA_IN[21:14] == 8'hB5) && (DATA_IN[39:32] == 8'h17) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                     // DATA_OUT = {MBTRAIN.LINKSPEED exit to repair resp}
                                     DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h17 , DATA_IN[31:22] , 8'hBA , DATA_IN[13:0] }; 
                                     Encoder_EN <= 1'b1;
                                     sb_exit <= 1'b0;
                                     trainerror_hs <= 1'b0;
                                     flag <= 0;
                                     PhyRetrain_req <= 1'b0;
                                     SpeedIdle_req <= 1'b0;
                                     Repair_req <= 1'b1;
                                     flag_sb <= 0;

                                 // DATA_IN = {MBTRAIN.LINKSPEED done req}
                                 end else if( (DATA_IN[21:14] == 8'hB5) && (DATA_IN[39:32] == 8'h19) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                                     // DATA_OUT = {MBTRAIN.LINKSPEED done resp}
                                     DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h19 , DATA_IN[31:22] , 8'hBA , DATA_IN[13:0] }; 
                                     Encoder_EN <= 1'b1;
                                     trainerror_hs <= 1'b0;
                                     flag <= 0;
                                     PhyRetrain_req <= 1'b0;
                                     SpeedIdle_req <= 1'b0;
                                     Repair_req <= 1'b0;
                                     if(sb_exit_module) begin     // to wait for module sb_exit signal
                                      sb_exit <= 1'b1;
                                      flag_sb <= 0;
                                     end else begin
                                       sb_exit <= 1'b0;
                                       flag_sb <= 1;
                                     end

                                end else begin
                                    DATA_OUT <= 64'b0;
                                    trainerror_flag <= 1'b1;
                                    trainerror_hs <= 1'b0; 
                                    Encoder_EN <= 1'b0;
                                    sb_exit <= 1'b0;
                                    flag <= 0;
                                    PhyRetrain_req <= 1'b0;
                                    SpeedIdle_req <= 1'b0;
                                    Repair_req <= 1'b0;
                                    flag_sb <= 0;
                                end

                                 

                  end

		  REPAIR: begin
                           // DATA_IN = {TRAINERROR Entry req}
                           if( (DATA_IN[21:14] == 8'hE5) && (DATA_IN[39:32] == 8'h00) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not "TRAINERROR HandShake msgs"
                             // DATA_OUT = {TRAINERROR Entry resp}
                               DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h00 , DATA_IN[31:22] , 8'hEA , DATA_IN[13:0] }; 
                               Encoder_EN <= 1'b1;
                               sb_exit <= 1'b0;
                               trainerror_hs <= 1'b1;
                               flag_sb <= 0;
                               Width_Update <= 1'b0;

                           // DATA_IN = {MBTRAIN.REPAIR init req}
                           end else if( (DATA_IN[21:14] == 8'hB5) && (DATA_IN[39:32] == 8'h1B) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                               // DATA_OUT = {MBTRAIN.REPAIR init resp}
                               DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h1B , DATA_IN[31:22] , 8'hBA , DATA_IN[13:0] }; 
                               Encoder_EN <= 1'b1;
                               sb_exit <= 1'b0;
                               trainerror_hs <= 1'b0;
                               flag_sb <= 0;
                               Width_Update <= 1'b0;

                           // DATA_IN = {MBTRAIN.REPAIR Apply degrade req}
                           end else if( (DATA_IN[21:14] == 8'hB5) && (DATA_IN[39:32] == 8'h1E) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not
                               // DATA_OUT = {MBTRAIN.REPAIR Apply degrade resp}
                               DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:56] , 16'b0 , 8'h1E , DATA_IN[31:22] , 8'hBA , DATA_IN[13:0] }; 
                               Encoder_EN <= 1'b1;
                               sb_exit <= 1'b0;
                               trainerror_hs <= 1'b0;
                               width_degrade_MB <= DATA_IN[42:40];
                               Width_Update <= 1'b1;
                               flag_sb <= 0;

                            // DATA_IN = {MBTRAIN.REPAIR end req} 
                            end else if( (DATA_IN[21:14] == 8'hB5) && (DATA_IN[39:32] == 8'h1D) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or nott
                               // DATA_OUT = {MBTRAIN.REPAIR end resp}
                               DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h1D , DATA_IN[31:22] , 8'hBA , DATA_IN[13:0] }; 
                               Encoder_EN <= 1'b1;
                               trainerror_hs <= 1'b0;
                               Width_Update <= 1'b0;
                               if(sb_exit_module) begin     // to wait for module sb_exit signal
                                  sb_exit <= 1'b1;
                                  flag_sb <= 0;
                               end else begin
                                  sb_exit <= 1'b0;
                                  flag_sb <= 1;
                               end

                             end else begin
                               DATA_OUT <= 64'b0;
                               trainerror_flag <= 1'b1;
                               trainerror_hs <= 1'b0; 
                               Encoder_EN <= 1'b0;
                               sb_exit <= 1'b0;
                               flag_sb <= 0;
                               Width_Update <= 1'b0;
                             end

                  end

		  default: begin
                            sb_exit <= 1'b0;             
                            trainerror_hs <= 1'b0;      
                            trainerror_flag <= 1'b0;     
                            //Error_Threshold <= 16'b0;   
                            Start_MB <= 1'b0; 
                            //width_degrade_MB <= 3'b0; 
                            DATA_OUT <= 64'b0;  
                            Encoder_EN <= 1'b0;   
                            flag <= 0;
                            flag_2 <= 0;
                            flag_sb <= 0;
                            flag_mb <= 0;
                            PhyRetrain_req <= 1'b0;
                            SpeedIdle_req <= 1'b0;
                            Repair_req <= 1'b0;
                            Width_Update <= 1'b0;
                  end

                endcase
     end


     PHYRETRAIN : begin     
                   // DATA_IN = {TRAINERROR Entry req}
                   if( (DATA_IN[21:14] == 8'hE5) && (DATA_IN[39:32] == 8'h00) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not "TRAINERROR HandShake msgs"
                       // DATA_OUT = {TRAINERROR Entry resp}
                       DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:40] , 8'h00 , DATA_IN[31:22] , 8'hEA , DATA_IN[13:0] }; 
                       Encoder_EN <= 1'b1;
                       sb_exit <= 1'b0;
                       trainerror_hs <= 1'b1;
                       flag_sb <= 0;   
  
                   // DATA_IN = {PHYRETRAIN.retrain start req}
                   end else if( (DATA_IN[21:14] == 8'hC5) && (DATA_IN[39:32] == 8'h01) && (DATA_IN[31:29] == 3'b010) && (DATA_IN[58:56] == 3'b110) && !error ) begin // Check if MsgCode[7:0], MsgSubcode[7:0], srcid & dstid match or not

                       case ({Retrain_Encoding , DATA_IN[42:40]})
                           6'b001_001: Resolved_Encoding <= 3'b001;
                           6'b001_100: Resolved_Encoding <= 3'b100;
                           6'b001_010: Resolved_Encoding <= 3'b010;
                           6'b100_001: Resolved_Encoding <= 3'b100;
                           6'b100_100: Resolved_Encoding <= 3'b100;
                           6'b100_010: Resolved_Encoding <= 3'b010;
                           6'b010_001: Resolved_Encoding <= 3'b010;
                           6'b010_100: Resolved_Encoding <= 3'b010;
                           6'b010_010: Resolved_Encoding <= 3'b010;
                        endcase

                       // DATA_OUT = {PHYRETRAIN.retrain start resp}
                       DATA_OUT <= { 1'b0 ,1'b0 , DATA_IN[61:43] , Resolved_Encoding , 8'h01 , DATA_IN[31:22] , 8'hCA , DATA_IN[13:0] }; 
                       Encoder_EN <= 1'b1;
                       trainerror_hs <= 1'b0;
                       if(sb_exit_module) begin     // to wait for module sb_exit signal
                         sb_exit <= 1'b1;
                         flag_sb <= 0;
                       end else begin
                         sb_exit <= 1'b0;
                         flag_sb <= 1;
                       end
 
                   end else begin
                       DATA_OUT <= 64'b0;
                       trainerror_flag <= 1'b1;
                       trainerror_hs <= 1'b0; 
                       Encoder_EN <= 1'b0;
                       sb_exit <= 1'b0;
                       flag_sb <= 0;
                   end 

     end


     default : begin     
                sb_exit <= 1'b0;             
                trainerror_hs <= 1'b0;      
                trainerror_flag <= 1'b0;     
                //Error_Threshold <= 16'b0;   
                Start_MB <= 1'b0; 
                //width_degrade_MB <= 3'b0; 
                DATA_OUT <= 64'b0;  
                Encoder_EN <= 1'b0;   
                flag <= 0;
                flag_2 <= 0;
                flag_sb <= 0;
                flag_mb <= 0;
                PhyRetrain_req <= 1'b0;
                SpeedIdle_req <= 1'b0;
                Repair_req <= 1'b0;
                Width_Update <= 1'b0;
     end	 
    endcase


  end else if((cs == MBINIT) && (mbinit_cs == PARAM) && flag_2) begin
      DATA_OUT <= DATA_IN_PARAM; 
      Encoder_EN <= 1'b1;
      flag_2 <= 0;
      if(sb_exit_module) begin
        sb_exit <= 1'b1;
        flag_sb <= 0;
      end else begin
        sb_exit <= 1'b0;
        flag_sb <= 1;
      end

  end else if((cs == MBTRAIN) && (mbtrain_cs == (VALVREF || DATAVREF || VALTRAINVREF || DATATRAINVREF || RXDESKEW)) && flag_mb) begin
    if( End_MB ) begin
      // DATA_OUT = {Rx Init D to C Tx Count Done req}
      DATA_OUT <= { 5'b0 , 3'b110 , 16'h000 , 8'h08 , 3'b010 ,7'b0 , 8'h85 , 9'b0 , 5'b10010 }; 
      Encoder_EN <= 1'b1;
      sb_exit <= 1'b0;
      Start_MB <= 1'b0;
      trainerror_hs <= 1'b0; 
      flag <= 0;
      flag_sb <= 0;
      flag_mb <= 0;
    end else begin
      DATA_OUT <= 64'b0;
      Encoder_EN <= 1'b0;
      sb_exit <= 1'b0;
      Start_MB <= 1'b0;
      trainerror_hs <= 1'b0; 
      flag <= 0;
      flag_sb <= 0;
      flag_mb <= 1;
    end

  end else if(flag_sb) begin
    DATA_OUT <= 64'b0;
    Encoder_EN <= 1'b0;
    if(sb_exit_module) begin
       sb_exit <= 1'b1;
       flag_sb <= 0;
     end else begin
       sb_exit <= 1'b0;
       flag_sb <= 1;
     end
 
  end else if(flag_2) begin
    if( (cs == MBTRAIN) && (mbtrain_cs == VALTRAINCENTER) ) begin
      DATA_OUT <= 64'b0;
      Encoder_EN <= 1'b1;
      sb_exit <= 1'b0;
      flag_2 <= 0;
    end else if( (cs == (MBTRAIN || MBINIT)) && ( (mbtrain_cs == (DATATRAINCENTER1 || DATATRAINCENTER2 || LINKSPEED)) || (mbinit_cs == (REVERSALMB || REPAIRMB)) ) ) begin
      DATA_OUT <= {48'h0, faulty_lanes_reg};
      Encoder_EN <= 1'b1;
      sb_exit <= 1'b0;
      flag_2 <= 0;
    end else begin
      DATA_OUT <= 64'b0;
      Encoder_EN <= 1'b0;
      sb_exit <= 1'b0;
      flag_2 <= 0;
    end

  end else begin

    sb_exit <= 1'b0;             
    trainerror_hs <= 1'b0;      
    trainerror_flag <= 1'b0;     
    //Error_Threshold <= 16'b0;   
    Start_MB <= 1'b0; 
    //width_degrade_MB <= 3'b0; 
    DATA_OUT <= 64'b0;  
    Encoder_EN <= 1'b0;   
    flag <= 0;
    flag_2 <= 0;
    flag_sb <= 0;
    flag_mb <= 0;
    PhyRetrain_req <= 1'b0;
    SpeedIdle_req <= 1'b0;
    Repair_req <= 1'b0;
    Width_Update <= 1'b0;

  end


end


endmodule

