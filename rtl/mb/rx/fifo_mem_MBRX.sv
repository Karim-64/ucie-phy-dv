module fifo_mem_MBRX #(
  parameter W_D_SIZE = 128 ,                      // write data size in bits
  parameter R_D_SIZE_Bytes = 64 ,                 // read data size in bytes
  parameter F_DEPTH  = 8   ,                      // fifo depth 
  parameter P_SIZE   = 4 
)
  (   
   input  logic                         w_clk,              // write domian operating clock
   input  logic                         w_rstn,             // write domian active low reset       
   input  logic                         w_full,             // full flag
   input  logic                         w_inc,              // write Enable
   input  logic [P_SIZE-2:0]            w_addr,             // write pointer
   input  logic [P_SIZE-2:0]            r_addr,             // Read  pointer
   input  logic [W_D_SIZE-1:0]          w_data,             // write data bus
   output logic [R_D_SIZE_Bytes-1:0][7:0] r_data        // read data bus
  );

integer i,j,k ;

//FIFO Memory
logic [W_D_SIZE-1:0] FIFO_MEM [F_DEPTH-1:0]; 

// writing data

always_ff @(posedge w_clk or negedge w_rstn)

 begin
  if(!w_rstn)
   begin 
    for(k=0;k<F_DEPTH;k=k+1) 
     FIFO_MEM[k] <= {W_D_SIZE{1'b0}} ;
   end
 else if (!w_full && w_inc)
    FIFO_MEM[w_addr] <= w_data ;
 end


// reading domain
always_comb begin
    for (i = 0; i < 4; i = i + 1) begin
        for (j = 0; j < 16; j = j + 1) begin
            r_data[i * 16 + j] = FIFO_MEM[r_addr + i][(j + 1) * 8 - 1 -: 8];
        end
    end
end

endmodule

