import Universal_pkg ::*; 

module MB_RX #(parameter FRAME_LENGTH=8,LFSR_WIDTH=23,R_D_SIZE_Bytes=64)
(top_if.mbrx MR_IF);

       logic CLK,LCLK                                     ; // MBCLK, LCLK
       logic RST_n                                        ; // RST_n is the reset of the MB_Rx domain
       logic LRST_n                                       ; // LRST_n is the reset of the LCLK domain
       LTSM_states LTSM_State                             ; // State of the LTSM to handle different Tests
       logic Valid_Lane                                   ; // MB_RX Valid Lane
       logic [NUM_LANES-1:0] Data_Lanes                   ; // MB_RX Data Lanes 
       logic Width_Degrade_Update                         ; // updating the Operational Width
       logic [WIDTH_DEGRADE_LENGTH-1:0] Width_Degrade     ;
       logic [ERROR_THRESHOLD_LENGTH-1:0] Error_Threshold ; // Number or Error Bits tolerated in a Test
       logic Test_Resp                                    ; // indication that the SB sent the ready response for the Remote die so that the Transmitter can start the test   
       logic [R_D_SIZE_Bytes-1:0][7:0] pl_data            ; // a 64 byte chunk sent to D2D
       logic pl_error                                     ;
       logic pl_valid                                     ; // signals that tells about the Current Chunk sent to D2D
       logic Detec_succ_lsyn                              ; // signals that inform the Controller with the Valid/Data Tests result
       logic Valid_Frame_Error_lsyn                       ;
       logic Comparison_Done_lsyn                         ;
       logic MB_RX_Done                                   ; // signal to indicate that RX Sent all the data in its buffer and is receiving no new data
       logic [NUM_LANES-1:0] Faulty_Lanes_lsyn            ;       


assign RST_n = MR_IF.RST_n; // RST_n is the reset of the MB_Rx domain and LRST_n is driven from it
assign CLK = MR_IF.mbclk; // MBCLK
assign LCLK = MR_IF.lclk; // LCLK
assign Valid_Lane = MR_IF.RVLD_P; // MB_RX Valid Lane
assign Data_Lanes = MR_IF.RD_P; // MB_RX Data Lanes 
assign Width_Degrade_Update = MR_IF.Width_Degrade_Update_Sync; // updating the Operational Width
assign Width_Degrade = MR_IF.width_degrade2; // updating the Operational Width
assign Error_Threshold = MR_IF.Error_Threshold; // Number or Error Bits tolerated in a Test
assign Test_Resp                   = MR_IF.Test_Resp_mb_Sync; // indication that the SB sent the ready response for the Remote die so that the Transmitter can start the test
assign LTSM_State                  = LTSM_states'(MR_IF.Opcode_Sync); // State of the LTSM to handle different Tests
assign LRST_n                      = RST_n;
assign MR_IF.detec_succ            = Detec_succ_lsyn; 
assign MR_IF.valid_frame_error     = Valid_Frame_Error_lsyn;
assign MR_IF.Comparison_Done       = Comparison_Done_lsyn; 
assign MR_IF.faulty_lanes          = (~Faulty_Lanes_lsyn);

assign MR_IF.pl_data               = pl_data; // a 64 byte chunk sent to D2D
assign MR_IF.pl_error              = pl_error;
assign MR_IF.pl_valid              = pl_valid; // signals that tells about the Current Chunk sent to D2D
assign MR_IF.mb_rx_done            = MB_RX_Done; ///////


//************Internal Signals****************//

//Valid_Checker
logic Vchk_EN;
logic Seq_Done;
logic detec_succ;
logic valid_frame_error;
logic Chunk_Error_Free;     
logic Chunk_Errored; 

//LFSR
logic Descr_EN;
logic LFSR_SEL;
logic [NUM_LANES-1:0] Descr_Data_Lanes;

//PerLane_ID Generator
logic [15:0] Lanes_IDs[NUM_LANES-1:0] ;

//PerLane 
logic Comparison_Type;
logic Data_Comparator_EN;
logic Comparison_Done;
logic [NUM_LANES-1:0] faulty_lanes;

//Enable Generator
logic Deserializer_EN1;
logic Deserializer_EN2;
logic Valid_Detected;

//Demapper
logic [W_D_SIZE-1:0] All_Lanes;
logic Full,Empty;


//*******************************************//

//******************************Width_Degradation & Error_Threshold Update*************************************//

logic [WIDTH_DEGRADE_LENGTH-1:0] Width_Degrade_reg;
logic [ERROR_THRESHOLD_LENGTH-1:0] Error_Threshold_reg;

always_ff @(posedge CLK or negedge RST_n) begin    

   if(!RST_n) begin

      Width_Degrade_reg   <= 'b0;

   end else begin 
      
   if (LTSM_State==RESET) begin 

      Width_Degrade_reg   <= All_Lanes;            // All Lanes are Operational

   end else if (Width_Degrade_Update) begin 

      Width_Degrade_reg   <= Width_Degrade;
   end

   end 

end


always_ff @(posedge CLK or negedge RST_n) begin    

   if(!RST_n) begin

      Error_Threshold_reg   <= 'b0;

   end else begin 
      
   if (LTSM_State==RESET) begin 

      Error_Threshold_reg   <= 'b0;           

   end else if (Test_Resp) begin 

      Error_Threshold_reg   <= Error_Threshold;

   end

   end 

end

//**************************************************************************************//

//***********************************************//

// inistantiate pulse_sync for Valid_Frame_Error
toggle_synchronizer_MBRX toggle_synchronizer_U0 (
   .fast_clk(CLK)                 ,  
   .slow_clk(LCLK)                ,   
   .f_rst_n(RST_n)                , 
   .s_rst_n(LRST_n)               ,     
   .event_in(valid_frame_error)   ,
   .event_out(Valid_Frame_Error_lsyn)
);

// inistantiate pulse_sync for Detec_Succ
toggle_synchronizer_MBRX toggle_synchronizer_U1 (
   .fast_clk(CLK)                 ,  
   .slow_clk(LCLK)                ,   
   .f_rst_n(RST_n)                , 
   .s_rst_n(LRST_n)               ,     
   .event_in(detec_succ)          ,
   .event_out(Detec_succ_lsyn)
);

// inistantiate pulse_sync for Comparison_DONE & Faulty Lanes
Data_Sync_RA_MBRX #(.WIDTH(NUM_LANES)) Data_Sync_RA_U0
(
    .fast_clk(CLK)                ,
    .slow_clk(LCLK)               ,
    .fast_reset(RST_n)            ,   
    .slow_reset(LRST_n)           ,   
    .Req_Src(Comparison_Done)     ,
    .Req_Syn(Comparison_Done_lsyn),
    .fast_data(faulty_lanes)      ,   
    .slow_data(Faulty_Lanes_lsyn)     
);

//*************************************************//

// inistantiate the Valid_Checker

Valid_Checker_MBRX #(.FRAME_LENGTH(FRAME_LENGTH)) Valid_Checker_U0
(
.CLK(CLK)                                   ,     // Clock
.RST_n(RST_n)                               ,     // Active-low Reset
.LTSM_State(LTSM_State)                     ,     // state of the LTSM to indicate the sequnece to be checked 
.Sampled_Bit(Valid_Lane)                    ,     // Incoming serial bit from Valid lane
.Width_Degrade_Update(Width_Degrade_Update) ,
.Width_Degrade(Width_Degrade)               ,     // only half the lanes are used (001->7:0 , 010->15:8)
.Valid_EN(Vchk_EN)                          ,
.Error_Threshold(Error_Threshold_reg)       ,     
.Seq_Done(Seq_Done)                         , 
.Detec_succ(detec_succ)                     ,
.Valid_Frame_Error(valid_frame_error)       ,     // flag to indicate that a framing error was found in the Valid Frame
.Chunk_Error_Free (Chunk_Error_Free)        ,     // flag to indicate the Chunk is Error-Free
.Chunk_Errored(Chunk_Errored)       
);


// inistantiate All_Lanes_LFSRs

All_Lanes_LFSR_MBRX #(.LFSR_WIDTH(LFSR_WIDTH),.NUM_LANES(NUM_LANES)) All_Lanes_LFSR_U0
(

  .MB_CLK (CLK)              ,        // Clock signal
  .RST_n(RST_n)              ,        // Asynchronous reset
  .Opcode_Synch(LTSM_State)  ,        // to reset the LFSR on state transitions
  .EN (Descr_EN)             ,        // Enable signal
  .Data_In(Data_Lanes)       ,        // input bits of all LFSRs
  .SEL_3(LFSR_SEL)           ,        // MUX select to determine which input goes to the LFSR depending on the state
  .Data_Out(Descr_Data_Lanes)         // output scrambled of all LFSRs

);


// inistantiate the Data_Comparator

Per_Lane_MBRX #(.NUM_LANES(NUM_LANES)) Per_Lane_U0
(
.CLK(CLK)                                  ,
.RST_n(RST_n)                              ,
.LTSM_State(LTSM_State)                    ,  
.Width_Degrade_Update(Width_Degrade_Update),
.Width_Degrade(Width_Degrade)              , // only half the lanes are used (001->7:0 , 010->15:8)
.Lanes_IDs(Lanes_IDs)                      , // for the Lane_ID test
.LFSR_Pattern(Descr_Data_Lanes)            , // for the LFSR test
.Compare_ip(Data_Lanes)                    ,
.Error_Threshold(Error_Threshold_reg)      , // Threshold to determine Functional Lanes for LFSR test
.Comparison_Type(Comparison_Type)          , // signal to indicate which Test is currently needed to be carried (1--> Lane_ID, 0--> LFSR)
.Comparison_EN(Data_Comparator_EN)         , 
.Comparison_Done(Comparison_Done)          ,
.Faulty_Lanes(faulty_lanes)                  // should be sent to the transmitter (of remote die) to determine its functional lanes               
);


// inistantiate the Per_Lane_ID_Generator

Per_Lane_ID_MBRX #(.NUM_LANES(NUM_LANES)) Per_Lane_ID_U0

(.Lanes_IDs(Lanes_IDs));


// inistantiate the Enable_Generator

Enable_Generator_MBRX #(.NUM_LANES(NUM_LANES),.FRAME_LENGTH(FRAME_LENGTH)) Enable_Generator_U0
(
.CLK(CLK)                                  ,
.RST_n(RST_n)                              ,
.LTSM_State(LTSM_State)                    ,
.Width_Degrade(Width_Degrade_reg)          ,
.Valid(Valid_Lane)                         , // valid lane 
.Comparison_Done(Comparison_Done)          , // indication of Data_Comparator finished comparison
.Test_Resp(Test_Resp)                      , // indication that the SB sent the ready response for the Remote die so that the Transmitter can start the test                     
.Vchk_EN(Vchk_EN)                          ,
.Descr_EN(Descr_EN)                        ,
.Valid_Frame_Error(valid_frame_error | Chunk_Errored),
.Detec_succ(detec_succ | Chunk_Error_Free) ,
.Valid_Detected(Valid_Detected)            ,
.Deserializer_EN1(Deserializer_EN1)        , 
.Deserializer_EN2(Deserializer_EN2)        ,
.Data_Comparator_EN(Data_Comparator_EN)    ,
.Comparison_Type(Comparison_Type)          , 
.LFSR_SEL(LFSR_SEL)
);



// inistantiate the Demapper

Demapper_MBRX #(.W_D_SIZE(W_D_SIZE),.R_D_SIZE_Bytes(R_D_SIZE_Bytes)) Demapper_U0
(
 .CLK(CLK)                                      ,
 .LCLK(LCLK)                                    , 
 .R_RST_n(RST_n)                                ,                               // receiver domain reset
 .L_RST_n(LRST_n)                               ,                               // LCLK domain reset
 .Ip_Bytes(All_Lanes)                           ,                               // 16 byte of the lanes
 .Width_Degrade_reg(Width_Degrade_reg)          ,                               // Width Degrade applied 
 .Valid_Frame_Error(Chunk_Errored)              ,
 .Dete_Succ(Chunk_Error_Free)                   ,
 .Deser_Done(Seq_Done)                          ,
 .LTSM_State(LTSM_State)                        ,
 .pl_data(pl_data)                              ,                               // a 64 byte chunk
 .pl_error(pl_error)                            ,
 .pl_valid(pl_valid)                            ,
 .o_full(Full)                                  , 
 .Valid_Detected(Valid_Detected)                ,
 .MB_RX_Done(MB_RX_Done)                        ,
 .o_empty(Empty)
);


// inistantiate the Lanes Deserializers

All_Lanes_Deserializers_MBRX #(.FRAME_LENGTH(FRAME_LENGTH),.NUM_LANES(NUM_LANES),.W_D_SIZE(W_D_SIZE)) All_Lanes_Deserializers_U0 

(
.CLK(CLK)                          ,
.RST_n(RST_n)                      ,
.Deserializer_EN1(Deserializer_EN1),
.Deserializer_EN2(Deserializer_EN2),
.Data_Lanes(Descr_Data_Lanes)      ,
.All_Lanes(All_Lanes)
);

//*********************************************************//

endmodule
















