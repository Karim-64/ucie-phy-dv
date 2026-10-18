module fifo_mem_SBTX #(
  parameter DATA_SIZE = 64   ,                      // write data size in bits
  parameter F_DEPTH   = 64   ,                      // fifo depth 
  parameter P_SIZE    = 7 
)
  (   
   input   logic                    w_clk           ,             // write domian operating clock
   input   logic                    w_rstn          ,             // write domian active low reset       
   input   logic                    w_full          ,             // full flag
   input   logic                    w_inc           ,             // write Enable
   input   logic [P_SIZE-2:0]       w_addr          ,             // write pointer
   input   logic                    r_inc           ,             // Read  Enable
   input   logic [P_SIZE-2:0]       r_addr          ,             // Read  pointer
   input   logic [DATA_SIZE-1:0]    w_data          ,             // write data bus
   input   logic                    w_Data_Marker   ,             // Message with Data Marker
   input   logic                    w_D2D_PHY_Marker,             // Message from D2D or PHY Marker
   input   logic                    w_Comp_Marker   ,             // Message is completion or not 
   output  logic [DATA_SIZE-1:0]    r_data          ,             // read data bus
   output  logic                    r_Data_Marker   ,             // Message with Data Marker
   output  logic                    r_D2D_PHY_Marker,             // Message from D2D or PHY Marker
   output  logic                    r_Comp_Marker                 // Message is completion or not  
  );

//Internal Signals
integer i;
logic [F_DEPTH-1:0] Data_Marker_reg;
logic [F_DEPTH-1:0] D2D_PHY_Marker_reg;
logic [F_DEPTH-1:0] Comp_Marker_reg;



//FIFO Memory
logic [DATA_SIZE-1:0] FIFO_MEM [F_DEPTH-1:0]; 

// writing data
always_ff @(posedge w_clk or negedge w_rstn) begin
  
  if(!w_rstn) begin 

    for(i=0;i<F_DEPTH;i=i+1) 
     FIFO_MEM[i] <= {DATA_SIZE{1'b0}} ;

  end else if (!w_full && w_inc) begin 

    FIFO_MEM[w_addr] <= w_data ;

  end

end 


//Control Info.
always_ff @(posedge w_clk or negedge w_rstn) begin

  if(!w_rstn) begin 

     Data_Marker_reg    <='b0;
     D2D_PHY_Marker_reg <='b0;
     Comp_Marker_reg    <='b0;

  end else if (!w_full && w_inc) begin 

    Data_Marker_reg   [w_addr] <=w_Data_Marker;
    D2D_PHY_Marker_reg[w_addr] <=w_D2D_PHY_Marker;
    Comp_Marker_reg   [w_addr] <=w_Comp_Marker;
    
  end 

 end


// reading domain
always_comb begin

r_data          = (r_inc)? FIFO_MEM[r_addr] :'b0;
r_Data_Marker   = (r_inc)? Data_Marker_reg[r_addr] :'b0; 
r_D2D_PHY_Marker= (r_inc)? D2D_PHY_Marker_reg[r_addr]:'b0;
r_Comp_Marker   = (r_inc)? Comp_Marker_reg[r_addr]:'b0;

end 

endmodule

