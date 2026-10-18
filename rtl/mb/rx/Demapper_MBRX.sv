import Universal_pkg ::* ; 

module Demapper_MBRX #(parameter W_D_SIZE=128,R_D_SIZE_Bytes=64)
(
 input  logic                            CLK,LCLK                   , // MBCLK & LCLK(D2D Clock)
 input  logic                            R_RST_n                    , // receiver domain reset
 input  logic                            L_RST_n                    , // LCLK domain reset
 input  logic [W_D_SIZE-1:0]             Ip_Bytes                   , // 16 byte of the lanes
 input  logic                            Valid_Detected             ,
 input  logic [WIDTH_DEGRADE_LENGTH-1:0] Width_Degrade_reg          , // Width Degrade applied 
 input  logic                            Valid_Frame_Error,Dete_Succ, // Current Chunk to be sent is Errored or not
 input  logic                            Deser_Done                 , // new 16 bytes are ready to be saved
 input  LTSM_states                      LTSM_State                 ,
 output logic                            MB_RX_Done                 ,
 output logic [R_D_SIZE_Bytes-1:0][7:0]  pl_data                    , // a 64 byte chunk needs to be sent to D2DS
 output logic                            pl_error,pl_valid          , // signals that tells about the Current Chunk sent to D2D
 output logic                            o_full,o_empty
);


logic WR_EN,RD_EN;
logic [W_D_SIZE-1:0]  WR_DATA;
logic Control_Module_EN;
logic Valid_Frame_Error_SYNC,Dete_Succ_SYNC;

assign Control_Module_EN=(LTSM_State==_ACTIVE)? 1'b1:1'b0;   // module is only enabled when current state is ACTIVE
assign pl_valid = (Valid_Frame_Error_SYNC | Dete_Succ_SYNC);
assign pl_error = Valid_Frame_Error_SYNC;


//----------------------------Still Receiving Logic----------------------------------//

logic alarm; 
logic event_in; 

always @(posedge CLK or negedge R_RST_n) begin

  if (~R_RST_n)
    event_in <= 1'b0;
  else if (alarm)
    event_in <= ~Valid_Detected;
  else
    event_in <= 1'b0;

end

toggle_synchronizer_MBRX MB_RX_Done_syn (
   .fast_clk(CLK),  
   .slow_clk(LCLK),   
   .f_rst_n(R_RST_n),  
   .s_rst_n(L_RST_n), 
   .event_in(event_in),
   .event_out(MB_RX_Done)
);

Timer_MBRX #(.NO_OF_CYCLES(3)) Timer_U0
(
    .clk(CLK)      ,               
    .rst_n(R_RST_n),               
    .start(Valid_Frame_Error | Dete_Succ),               
    .alarm(alarm)          
);

//---------------------------------------------------------------------------------//

// Inistantiate 2 PULSE_SYNCH 
toggle_synchronizer_MBRX Valid_Frame_Error_syn (
   .fast_clk(CLK),  
   .slow_clk(LCLK),   
   .f_rst_n(R_RST_n),  
   .s_rst_n(L_RST_n), 
   .event_in(Valid_Frame_Error),
   .event_out(Valid_Frame_Error_SYNC)
);

toggle_synchronizer_MBRX Dete_Succ_syn (
   .fast_clk(CLK),  
   .slow_clk(LCLK),   
   .f_rst_n(R_RST_n), 
   .s_rst_n(L_RST_n),     
   .event_in(Dete_Succ),
   .event_out(Dete_Succ_SYNC)
);

// instantiate a FIFO
Async_fifo_MBRX #(.W_D_SIZE(W_D_SIZE),.F_DEPTH(16),.P_SIZE(5),.R_D_SIZE_Bytes(R_D_SIZE_Bytes)) u_Async_FIFO
(
.i_w_clk(CLK),
.i_w_rstn(R_RST_n),                            
.i_r_clk(LCLK),              
.i_r_rstn(L_RST_n), 
.i_w_inc(WR_EN),            
.i_r_inc(pl_valid),              
.i_w_data(WR_DATA),             
.o_r_data(pl_data),           
.o_full(o_full),       
.o_empty(o_empty)             
);


// instantiate a WR_control module

WR_Control_MBRX #(.W_D_SIZE(W_D_SIZE)) wr_control_module
(
.CLK(CLK),
.R_RST_n(R_RST_n),
.Ip_Bytes(Ip_Bytes), 
.Deser_Done(Deser_Done),
.EN(Control_Module_EN),
.Width_Degrade(Width_Degrade_reg),
.WR_EN(WR_EN),
.WR_DATA(WR_DATA)
);



endmodule












