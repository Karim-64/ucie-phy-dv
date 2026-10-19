import Universal_pkg ::* ; 

/*---------Description------------------//

this Module represents the SideBand transmitter that deals with D2D, 
Handles Local Register Access Requests & their Completions,
Handles Interaction with Controller to send Training & RDI Messages 
and sends the Training SBINIT Pattern.

//---------------------------------------*/


module SB_TX_Top #(parameter NC=32,FIFO_DEPTH=64,DATA_WIDTH=64)
(top_if.sbtx ST_IF);
 logic LCLK,RST_n                        ;  // Controller & D2D clock domain
 logic SBCLK,SB_RST_n                    ;  // SB Bus clock domain

 logic lp_cfg_vld                        ;  // Messages coming from D2D on RDI
 logic [NC-1:0] lp_cfg                   ;
 logic [1:0] State                       ;  // important LTSM States related to SB_TX Functionality (RESET/SBINIT/ACTIVE)
 logic Pattern_Detected                  ;  // signal that marks the detection of the pattern by the Pattern_Detector in the SB_RX
 logic Send_Pattern                      ;  // signal that inform the SB_TX to start with the Pattern Cycle
 logic Progress_Stop                     ;  // signal to inform the SB_TX to stop processing D2D Messages in preparation for PHYRETRAIN/TRAINERROR entry

 logic Encoder_Mess_Valid                ;  // Message coming from the Encoder (Module/Module_Partner_RDI)
 logic [DATA_WIDTH-1:0] Encoder_Message  ;  
 logic  PHY_Data_Marker                  ;  // signal to mark that the current Message from Encoder is with data for the SB_TX Credit System
 
 logic PHY_Resend_Req                    ;  // signal represents the Priority Encoder is now busy to deal with the Encoder         

 logic UIRB_Done                         ;  // signals that deal with the Configuration space to handle Register Access Requests(RAR)
 logic [DATA_WIDTH-1:0] UIRB_Resp        ;
 logic UIRB_RD_EN,UIRB_WR_EN             ;
 logic [ADDR_LENGTH-1:0]UIRB_Addr        ;
 logic [DATA_WIDTH-1:0]UIRB_Data         ;
 logic [BE_LENGTH-1:0] UIRB_BE           ;  

 logic pl_cfg_crd                        ;  // signal that retuen a Credit for the D2D Credit System

 logic SBTX_CLK,SBTX_DATA                ;  // SB Bus
 logic Comp_Vld                          ;  // RAR Completion Messages sent by the SB_RX to the D2D
 logic [DATA_WIDTH-1:0]Completion_Message;

 logic UIE                               ;  // signal that marks the detection of a parity error in D2D messages received on RDI

 logic Pattern_Done                      ;  // signal that marks Finishing the SBINIT Pattern Cycle
 logic Ser_Done                          ;   // signal that indicates all messages in the FIFO are sent on the SB Bus

 logic Pattern_Done_Synch                 ;


assign LCLK                = ST_IF.lclk ;
assign RST_n               = ST_IF.RST_n ;
assign SB_RST_n            = ST_IF.RST_n;
assign SBCLK               = ST_IF.sb_clk ;
assign lp_cfg_vld          = ST_IF.lp_cfg_vld ;
assign lp_cfg              = ST_IF.lp_cfg ;
assign State               = ST_IF.state ;
assign Encoder_Mess_Valid  = ST_IF.encoder_msg_vld ;
assign Encoder_Message     = ST_IF.encoder_msg;
assign Pattern_Detected    = ST_IF.pattern_detected;
assign Send_Pattern        = ST_IF.send_pattern;
assign UIRB_Done           = ST_IF.UIRB_done;
assign UIRB_Resp           = ST_IF.UIRB_response;
assign Progress_Stop       = ST_IF.Progress_Stop;
assign PHY_Data_Marker     =ST_IF.PHY_Data_Marker;
assign ST_IF.pl_cfg_crd    = pl_cfg_crd ;
assign ST_IF.txclk_sb      = SBTX_CLK ;
assign ST_IF.txdata_sb     = SBTX_DATA ;
assign ST_IF.UIRB_WR_EN    = UIRB_WR_EN ;
assign ST_IF.UIRB_RD_EN    = UIRB_RD_EN ;
assign ST_IF.UIRB_addr     = UIRB_Addr ;
assign ST_IF.UIRB_data     = UIRB_Data ;
assign ST_IF.UIRB_BE       = UIRB_BE ;
assign ST_IF.comp_msg_vld  = Comp_Vld ;
assign ST_IF.comp_msg      = Completion_Message ;
assign ST_IF.UIE           = UIE ;
assign ST_IF.pattern_done  = Pattern_Done ;
assign ST_IF.pattern_done_synch  = Pattern_Done_Synch ;
assign ST_IF.ser_done      = Ser_Done ;
assign ST_IF.PHY_Resend_Req = PHY_Resend_Req;


//******************************Internal_Signals********************************************//

// Send Pattern Data Synchronizer
logic Send_Pattern_sync;

// Demux 
logic[DATA_WIDTH-1:0] dout3;

// WR_Control
logic [DATA_WIDTH-1:0] Interface_Message                                                       ; 
logic Data_Marker_WC,Reg_Acc_Marker_WC,Reg_Acc_Data_Marker_WC,Comp_Marker_WC,Req_Resp_Marker_WC;
logic FIFO_WR_WC                                                                               ;  
logic Error_Handler                                                                            ;
                                                                            
// Sync.FIFO
logic [DATA_WIDTH-1:0] data_out                                         ;
logic Data_Marker_F,Reg_Acc_Marker_F,Reg_Acc_Data_Marker_F,Comp_Marker_F;  
logic empty,rd_ack                                                      ;

//Decoder
logic RD_EN,D2D_En                           ;   
logic [1:0] Sel                              ;                                  
logic Data_Marker_D,Comp_Marker_D            ;                       
logic [DATA_WIDTH-1:0] Output_Message        ;

// Priority Encoder                               
logic  Data_Marker_D2D,Comp_Marker_D2D                 ;
logic  [DATA_WIDTH-1:0] D2D_Data                       ;
logic  FIFO_WR_P                                       ;
logic  [DATA_WIDTH-1:0] FIFO_Data                      ;
logic  Data_Marker_P,D2D_PHY_Marker,Comp_Marker_P      ; 
logic  D2D_Resend_Req                                  ; 

// Async. FIFO
logic o_Data_Marker,o_D2D_PHY_Marker,o_Comp_Marker          ;
logic o_Data_Marker_AF,o_D2D_PHY_Marker_AF,o_Comp_Marker_AF ;
logic i_r_inc                                               ;    
logic [DATA_WIDTH-1:0] o_r_data                             ;     
logic o_full,o_empty                                        ;  

// TX FSM
logic  alarm_64,alarm_32;        
logic  alarm_1ms        ;        
logic  patt_alarm       ;
logic  Start_1ms        ;
logic  Ser_En           ;        
logic  Patt_Gen_En      ; 
logic Pattern_Done_Asyn ;
logic Ser_Done_Asyn     ; 
logic [1:0] OPCODE      ; 
logic Out_Reset_Mess    ;         

// Serializer
logic start_p_g,start_s;
logic Pattern,Ser_Data ;
logic Credit           ;     
logic [DATA_WIDTH-1:0] Mux_Out;

//****************************************************************************************//

//synchronizer for the level signal(Send_Pattern)
Level_Sync_SBTX Level_Sync_U0
(
    .CLK(SBCLK)                   ,    // Destination clock domain
    .RST_n(SB_RST_n)              ,    // Active-low asynchronous reset
    .Async_Signal(Send_Pattern)   ,    // Asynchronous input signal
    .Sync_Signal(Send_Pattern_sync)      // Synchronized output signal
);


//Inistantiate WR_Control
WR_Control_SBTX #(.NC(NC)) WR_Control_U0
(
.CLK(LCLK)                                  ,
.RST_n(RST_n)                               , // LCLK and its Domain reset
.lp_cfg_vld(lp_cfg_vld)                     , // interface signal that indicate new data is available from the adapter
.lp_cfg(lp_cfg)                             , // Data from the adapter
.Interface_Message(Interface_Message)       , // 2 phases from the message  (Data or Header)
.Data_Marker(Data_Marker_WC)                ,
.Reg_Acc_Marker(Reg_Acc_Marker_WC)          , // marker to mark that the Message is with Data/is Register Access Request
.Reg_Acc_Data_Marker(Reg_Acc_Data_Marker_WC),
.Comp_Marker(Comp_Marker_WC)                , // marker to mark that the RAR is with Data/is completion Message
.Error_Handler(Error_Handler)               ,                                                                        
.Req_Resp_Marker (Req_Resp_Marker_WC)       , // marker to mark that the Message is Request or Response
.FIFO_WR(FIFO_WR_WC)                        , // write enable for the FIFO to write the 2 phases
.UIE(UIE)                                     // uncorrectable internal error is detected 
);


//Inistantiate synchronous FIFO
FIFO_SBTX #(.FIFO_WIDTH(DATA_WIDTH),.FIFO_DEPTH(FIFO_DEPTH)) FIFO_U0
(
.clk(LCLK)                                       , 
.rst_n(RST_n)                                    , 
.wr_en(FIFO_WR_WC)                               , 
.rd_en(RD_EN)                                    ,          // LCLK and its domain Reset
.data_in(Interface_Message)                      ,  
.Data_Marker(Data_Marker_WC)                     ,          // a Marker is used to indicate whether Message is with data or not 
.Reg_Acc_Marker(Reg_Acc_Marker_WC)               ,          // a Marker is used to indicate whether Message is register access request or not 
.Reg_Acc_Data_Marker(Reg_Acc_Data_Marker_WC)     ,          // a Marker is used to indicate whether the RAR is with 32b/64b data
.Comp_Marker(Comp_Marker_WC)                     ,          // a Marker is used to indicate whether Message is Completion Message
.Req_Resp_Marker(Req_Resp_Marker_WC)             ,          // a Marker is used to indicate whether Message is Request or Response
.data_out(data_out)                              ,
.Data_Marker_Out(Data_Marker_F)                  ,
.Reg_Acc_Marker_Out(Reg_Acc_Marker_F)            ,
.Reg_Acc_Data_Marker_Out(Reg_Acc_Data_Marker_F)  ,         
.Comp_Marker_Out (Comp_Marker_F)                 ,   
.empty(empty)                                    ,
.UIE(UIE)                                        ,        
.rd_ack(rd_ack)
);


//Inistantiate Decoder
Decoder_SBTX #(.NC(NC))  Decoder_U0
(
.CLK(LCLK)                                       ,
.RST_n(RST_n)                                    ,     // LCLK and its domain reset
.state(State)                                    ,     // state of the LTSM to indicate the operation mode of the Decoder 
.Empty_Flag(empty)                               ,     // SYNC FIFO Empty Flag 
.Interface_Message(data_out)                     ,     // Data from the FIFO
.Data_Marker_Out(Data_Marker_F)                  ,
.Reg_Acc_Marker_Out(Reg_Acc_Marker_F)            ,     // some Info bits that helps identifying the Incoming Message
.Reg_Acc_Data_Marker_Out(Reg_Acc_Data_Marker_F)  ,
.Comp_Marker_Out(Comp_Marker_F)                  ,
.rd_ack (rd_ack)                                 ,
.RD_EN(RD_EN)                                    ,     // SYNC FIFO Read Enable  
.UIRB_Done(UIRB_Done)                            ,     // signals carrying the requested data from the UIRB for local RARs
.UIRB_Resp(UIRB_Resp)                            ,             
.UIRB_WR_EN(UIRB_WR_EN)                          ,
.UIRB_BE(UIRB_BE)                                ,   
.Progress_Stop(Progress_Stop)                    ,     // signal to stop decoding Messages from the D2D to prepare for TRAINERROR State
.UIRB_RD_EN(UIRB_RD_EN)                          ,     // UIRB control signals
.UIRB_Addr(UIRB_Addr)                            ,
.D2D_Resend_Req(D2D_Resend_Req)                  ,     // signal from Priority Encoder inserted when PHY message is prioritized 
.Sel(Sel)                                        ,     // Demux select to determine data goes to UIRB or CDC FIFO or D2D
.D2D_En(D2D_En)                                  ,
.Data_Marker(Data_Marker_D)                      ,
.Comp_Marker(Comp_Marker_D)                      ,  
.Credit(Credit)                                  ,   
.Output_Message(Output_Message)                       // output message to UIRB or CDC FIFO or Completion directed to D2D
);

assign  Comp_Vld = Sel[1];    

//Inistantiate Demux
demux_SBTX #(.DATA_WIDTH(DATA_WIDTH)) demux_U0
( 
    .din(Output_Message)      ,   
    .sel(Sel)                 ,       
    .dout0(UIRB_Data)         , 
    .dout1(D2D_Data)          ,
    .dout2(Completion_Message), 
    .dout3(dout3)  
);

//Inistantiate Priority_Encoder
Priority_Encoder_SBTX #(.DATA_WIDTH(DATA_WIDTH)) Priority_Encoder_U0
(
    .CLK(LCLK)                       , 
    .RST_n(RST_n)                    ,
    .PHY_En(Encoder_Mess_Valid)      , 
    .D2D_En(D2D_En)                  ,
    .Data_Marker_D2D(Data_Marker_D)  , 
    .Data_Marker_PHY(PHY_Data_Marker),
    .Comp_Marker_D2D(Comp_Marker_D)  ,
    .PHY_Data(Encoder_Message)       , 
    .D2D_Data(D2D_Data)              ,
    .FIFO_WR(FIFO_WR_P)              ,
    .FIFO_Data(FIFO_Data)            ,
    .Data_Marker(Data_Marker_P)      , 
    .D2D_PHY_Marker(D2D_PHY_Marker)  ,
    .Comp_Marker(Comp_Marker_P)      ,                   // Control bits saved in the CDC FIFO
    .D2D_Resend_Req(D2D_Resend_Req)  ,
    .PHY_Resend_Req(PHY_Resend_Req)                      // Notifies D2D to resend if PHY was chosen
);


//Inistantiate Credits_Handler
Credits_Handler_SBTX  Credits_Handler_U0
(
    .CLK(LCLK)                            , 
    .RST_n(RST_n)                         ,
    .Comp_Sent(Sel[1])                    ,
    .D2D_PHY_Marker(o_D2D_PHY_Marker_AF)  ,
    .Data_Marker(o_Data_Marker_AF)        ,
    .Comp_Marker(o_Comp_Marker_AF)        ,
    .Credit(Credit)                       ,  
    .UIE(Error_Handler)                   ,            
    .pl_cfg_crd(pl_cfg_crd)
);


 //Inistantiate Pulse Synchronizers for Credits_Handler
Pulse_synchronizer_sf_SBTX  Pulse_synchronizer_sf_U0
(
    .slow_clk        (SBCLK)            ,  // Slow clock  
    .fast_clk        (LCLK)             ,  // Fast clock  
    .s_rst_n         (SB_RST_n)         ,  // Slow active-low reset  
    .f_rst_n         (RST_n)            ,  // Fast active-low reset  
    .event_in        (o_Data_Marker)    ,  // Event signal from the slow clock domain  
    .event_out       (o_Data_Marker_AF)   // Synchronized event signal in the fast clock domain  
);

Pulse_synchronizer_sf_SBTX  Pulse_synchronizer_sf_U1
(
    .slow_clk        (SBCLK)               ,  
    .fast_clk        (LCLK)                , 
    .s_rst_n         (SB_RST_n)            ,   
    .f_rst_n         (RST_n)               ,    
    .event_in        (o_D2D_PHY_Marker)    ,   
    .event_out       (o_D2D_PHY_Marker_AF)           
);

Pulse_synchronizer_sf_SBTX  Pulse_synchronizer_sf_U2
(
    .slow_clk        (SBCLK)               ,  
    .fast_clk        (LCLK)                , 
    .s_rst_n         (SB_RST_n)            ,   
    .f_rst_n         (RST_n)               ,    
    .event_in        (o_Comp_Marker)       ,   
    .event_out       (o_Comp_Marker_AF)           
);


//Inistantiate Asynchronous FIFO 
Async_fifo_SBTX #(.DATA_SIZE(DATA_WIDTH),.F_DEPTH(FIFO_DEPTH),.P_SIZE(7)) Async_fifo_U0

 (
    .i_w_clk          (LCLK)              ,  // write domain operating clock
    .i_w_rstn         (RST_n)             ,  // write domain active low reset  
    .i_w_inc          (FIFO_WR_P)         ,  // write control signal 
    .i_r_clk          (SBCLK)             ,  // read domain operating clock
    .i_r_rstn         (SB_RST_n)          ,  // read domain active low reset 
    .i_r_inc          (i_r_inc)           ,  // read control signal
    .i_w_data         (FIFO_Data)         ,  // write data bus
    .i_Data_Marker    (Data_Marker_P)     ,  // Message with Data Marker
    .i_D2D_PHY_Marker (D2D_PHY_Marker)    ,  // Message from D2D or PHY Marker
    .i_Comp_Marker    (Comp_Marker_P)     ,  // Message is completion or not 
    .o_r_data         (o_r_data)          ,  // read data bus
    .o_Data_Marker    (o_Data_Marker)     ,  // Message with Data Marker
    .o_D2D_PHY_Marker (o_D2D_PHY_Marker)  ,  // Message from D2D or PHY Marker
    .o_Comp_Marker    (o_Comp_Marker)     ,  // Message is completion or not 
    .o_full           (o_full)            ,  // FIFO full flag
    .o_empty          (o_empty)              // FIFO empty flag

);


//Inistantiate SB_FSM
TX_FSM_SBTX TX_FSM_U0
(
    .CLK               (SBCLK)             ,  // SB clock & reset signals  
    .RST_n             (SB_RST_n)          ,  
    .OPCODE            (OPCODE)            ,  // Opcode signal indicating state (pattern or operational) 
    .Empty_Flag        (o_empty)           ,  // FIFO empty flag for serializer loading  
    .Patt_Recev        (Pattern_Detected)  ,  // Pattern received signal from pattern detector  
    .Send_Pattern      (Send_Pattern_sync) ,  // Controller signal to start clock pattern cycle  
    .Data_Marker_Out   (o_Data_Marker)     ,  // Indicates if the sent message contains data  
    .alarm_64          (alarm_64)          ,  // Alarm signals for Timer_64  
    .alarm_32          (alarm_32)          ,  // Alarm signals for Timer_32  
    .alarm_1ms         (alarm_1ms)         ,  // Alarm for 1ms timer used with clock pattern  
    .patt_alarm        (patt_alarm)        ,  // Pattern alarm signal  
    .Start_1ms         (Start_1ms)         ,  // Start signal for 1ms timer  
    .Ser_En            (Ser_En)            ,  // Enable for serializer  
    .Patt_Gen_En       (Patt_Gen_En)       ,  // Enable for pattern generator  
    .FIFO_RD           (i_r_inc)           ,  // FIFO read enable 
    .Out_Reset_Mess    (Out_Reset_Mess)    ,  // signal to load the serializer with the SBINIT_Out_of_Reset Message
    .Patt_Cycle_Done   (Pattern_Done) ,  // Marks completion of 4 clock patterns  
    .Ser_Done          (Ser_Done_Asyn)        // Serializer done signal                           
                                             //  signal to indicate that the Whole Message is fully Serialized  
);


//Inistantiate Data Sync for State
Gray_Synchronizer_SBTX  #(.DATA_SIZE(2)) Gray_Synchronizer_U0
(
  .CLK(SBCLK),     
  .RST_n(SB_RST_n),      
  .Async_Data(State),  
  .Sync_Data(OPCODE)    
);


//Inistantiate Timer 1ms
Timer_ms_SBTX #(.CLK_FREQ_HZ(SB_CLK_FREQ_HZ),.FACTOR(SB_FACTOR))  Timer_1ms_U0
(
    .clk(SBCLK)           ,                     // Clock input
    .rst_n(SB_RST_n)      ,                     // Active-low reset
    .start(Start_1ms)     ,                     // Start signal
    .alarm(alarm_1ms)     ,                     // Alarm asserted after 1ms
    .patt_alarm(patt_alarm)                     
);


//Inistantiate Clock Generator
Clk_Gate_SBTX  Clk_Gate_U0
(
.CLK(SBCLK)                   ,
.Enable(Patt_Gen_En | Ser_En) , // used by both Serializer & Pattern_Generator
.Load(i_r_inc || Out_Reset_Mess),
.SBTX_CLK(SBTX_CLK)
);


//Inistantiate Pattern_Generator
Pattern_Generator_SBTX  Pattern_Generator_U0
(
    .CLK(SBCLK)               ,
    .RST_n(SB_RST_n)          ,         // Clock & Active-low reset
    .Patt_Gen_En(Patt_Gen_En) ,         // Enable signal to start
    .start_64(start_p_g)      ,         // Trigger for the 64-cycle timer
    .SBTX_DATA(Pattern)                 // Serialized output (1-bit)
);


//Inistantiate Mux for serializer input
MUX_SBTX  #(.INPUT_WIDTH(DATA_WIDTH)) MUX_U1
(
  .IN_0(o_r_data),
  .IN_1(SBINIT_out_of_Reset_Message), 
  .Mux_Sel(Send_Pattern_sync),    // as the serializer should send the SBINIT_Out_of_Reset message as long as the Send_Pattern Signal is high
  .OUT(Mux_Out)
 );


//Inistantiate Serializer
Serializer_64_SBTX #(.DATA_WIDTH(DATA_WIDTH)) Serializer_64_U0
(
    .clk(SBCLK)                      , // Clock input
    .rst_n(SB_RST_n)                 , // Active-low reset
    .load(i_r_inc || Out_Reset_Mess) , // signal to load the data to be serialized on the SB Bus(from FIFO or SBINIT_Out_of_Reset_Message)
    .Enable(Ser_En)                  , // Enable signal to Serialize the Data_in
    .data_in(Mux_Out)                , // 64-bit parallel input from the FIFO
    .data_out(Ser_Data)              , // Serialized 1-bit output
    .start_64(start_s)                 // signal to start the 64 cycles timer
);


//Inistantiate Timer_64
Timer_SBTX #(.NO_OF_CYCLES(64)) Timer_64_U0
(
    .clk  (SBCLK)  ,                // Clock input
    .rst_n(SB_RST_n),               // Active-low reset
    .start(start_s | start_p_g),    // Start signal to activate the timer used by Serializer & Pattern_Generator
    .alarm(alarm_64)                // Alarm signal after 64 clock cycles

);


//Inistantiate Timer_32
Timer_SBTX #(.NO_OF_CYCLES(32)) Timer_32_U0
(
    .clk  (SBCLK)   ,               // Clock input
    .rst_n(SB_RST_n),               // Active-low reset
    .start(alarm_64),               // Start signal to activate the timer
    .alarm(alarm_32)                // Alarm signal after 32 clock cycles

);


//Inistantiate Mux for the SB Bus
MUX_SBTX  #(.INPUT_WIDTH(1)) MUX_U0
(
  .IN_0(Ser_Data)      ,
  .IN_1(Pattern)       , 
  .Mux_Sel(Patt_Gen_En),
  .OUT(SBTX_DATA)

 );


 //Inistantiate Pulse Synchronizers for Pattern_Done & Ser_Done
Pulse_synchronizer_sf_SBTX  Pulse_synchronizer_sf_U3
(
    .slow_clk        (SBCLK)            ,  // Slow clock  
    .fast_clk        (LCLK)             ,  // Fast clock  
    .s_rst_n         (SB_RST_n)         ,  // Slow active-low reset  
    .f_rst_n         (RST_n)            ,  // Fast active-low reset  
    .event_in        (Pattern_Done),  // Event signal from the slow clock domain  
    .event_out       (Pattern_Done_Synch)         // Synchronized event signal in the fast clock domain  
);

Pulse_synchronizer_sf_SBTX  Pulse_synchronizer_sf_U4
(
    .slow_clk        (SBCLK)               ,  
    .fast_clk        (LCLK)                , 
    .s_rst_n         (SB_RST_n)            ,   
    .f_rst_n         (RST_n)               ,    
    .event_in        (Ser_Done_Asyn & o_empty),   // all Messages should be sent before entering TrainError/PHYRETRAIN State 
    .event_out       (Ser_Done)           
);


endmodule

