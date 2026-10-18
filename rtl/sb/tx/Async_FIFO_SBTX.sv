
module Async_fifo_SBTX #(
  parameter DATA_SIZE  = 64 ,                        // data size
  parameter F_DEPTH    = 64 ,                        // fifo depth
  parameter P_SIZE     = 7 
)
 (
   input  logic                       i_w_clk         ,      // write domian operating clock
   input  logic                       i_w_rstn        ,      // write domian active low reset  
   input  logic                       i_w_inc         ,      // write control signal 
   input  logic                       i_r_clk         ,      // read domian operating clock
   input  logic                       i_r_rstn        ,      // read domian active low reset 
   input  logic                       i_r_inc         ,      // read control signal
   input  logic [DATA_SIZE-1:0]       i_w_data        ,      // write data bus
   input  logic                       i_Data_Marker   ,      // Message with Data Marker
   input  logic                       i_D2D_PHY_Marker,      // Message from D2D or PHY Marker
   input  logic                       i_Comp_Marker   ,      // Message is completion or not 
   output logic [DATA_SIZE-1:0]       o_r_data        ,      // read data bus
   output logic                       o_Data_Marker   ,      // Message with Data Marker
   output logic                       o_D2D_PHY_Marker,      // Message from D2D or PHY Marker
   output logic                       o_Comp_Marker   ,      // Message is completion or not 
   output logic                       o_full          ,      // fifo full flag
   output logic                       o_empty                // fifo empty flag
);


bit   [P_SIZE-2:0] r_addr , w_addr ;
bit   [P_SIZE-1:0] w2r_ptr , r2w_ptr ;
logic [P_SIZE-1:0] gray_w_ptr , gray_rd_ptr ;

 
fifo_mem_SBTX #(.F_DEPTH(F_DEPTH),.DATA_SIZE(DATA_SIZE),.P_SIZE(P_SIZE)) u_fifo_mem 
(
.w_clk(i_w_clk),              
.w_rstn(i_w_rstn),
.w_inc(i_w_inc),                             
.w_full(o_full),              
.w_addr(w_addr),
.r_inc(i_r_inc),           
.r_addr(r_addr),
.w_data(i_w_data),
.w_Data_Marker(i_Data_Marker),         
.w_D2D_PHY_Marker(i_D2D_PHY_Marker), 
.w_Comp_Marker(i_Comp_Marker),                          
.r_data(o_r_data),
.r_Data_Marker(o_Data_Marker),    
.r_D2D_PHY_Marker(o_D2D_PHY_Marker),
.r_Comp_Marker(o_Comp_Marker)
); 


fifo_rd_SBTX # (.P_SIZE(P_SIZE)) fifo_rd (
.r_clk(i_r_clk),              
.r_rstn(i_r_rstn),             
.r_inc(i_r_inc),              
.sync_wr_ptr(w2r_ptr),                
.rd_addr(r_addr),            
.gray_rd_ptr(gray_rd_ptr),        
.empty(o_empty)
);


BIT_SYNC_SBTX #(.NUM_STAGES(2) , .BUS_WIDTH(P_SIZE)) R_P_SYNC
(
.CLK(i_w_clk) ,
.RST(i_w_rstn) ,
.ASYNC(gray_rd_ptr) ,
.SYNC(r2w_ptr)
);


fifo_wr_SBTX # (.P_SIZE(P_SIZE)) fifo_wr (            
.w_clk(i_w_clk),              
.w_rstn(i_w_rstn),             
.w_inc(i_w_inc),            
.sync_rd_ptr(r2w_ptr),                
.w_addr(w_addr),            
.gray_w_ptr(gray_w_ptr),        
.full(o_full)
); 

BIT_SYNC_SBTX #(.NUM_STAGES(2) , .BUS_WIDTH(P_SIZE)) W_P_SYNC (
.CLK(i_r_clk) ,
.RST(i_r_rstn) ,
.ASYNC(gray_w_ptr) ,
.SYNC(w2r_ptr)
);


endmodule


