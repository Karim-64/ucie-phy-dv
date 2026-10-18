
module fifo_wr_MBRX #(parameter P_SIZE = 4)
(
   input  logic                    w_clk,              // write domian operating clock
   input  logic                    w_rstn,             // write domian active low reset 
   input  logic                    w_inc,              // write Enable
   input  logic     [P_SIZE-1:0]   sync_rd_ptr,        // synced gray coded read pointer         
   output logic     [P_SIZE-2:0]   w_addr,             // generated binary write address
   output logic   [P_SIZE-1:0]     gray_w_ptr,         // generated gray coded write address
   output logic                    full                // fifo full flag

);

logic [P_SIZE-1:0]  w_ptr ;
integer i;

// increment binary pointer
always_ff @(posedge w_clk or negedge w_rstn)
begin

  if(!w_rstn) begin 
    w_ptr <= 0 ;
  end 
  else if (!full && w_inc) begin
    w_ptr <= w_ptr + 1;
  end

end

// generation of write address
assign w_addr = w_ptr[P_SIZE-2:0];

// converting binary write pointer to gray coded
always_ff @(posedge w_clk or negedge w_rstn)
 begin
  if(!w_rstn)
   begin
    gray_w_ptr <= 0 ;
   end
 else
  begin
   gray_w_ptr[P_SIZE-1]<=w_ptr[P_SIZE-1];
   for(i=P_SIZE-2;i>=0;i=i-1)
   gray_w_ptr[i]<=w_ptr[i+1]^w_ptr[i];
  end
 end


// generation of full flag
assign full =(sync_rd_ptr[P_SIZE-1]!= gray_w_ptr[P_SIZE-1] && sync_rd_ptr[P_SIZE-2]!= gray_w_ptr[P_SIZE-2] && sync_rd_ptr[P_SIZE-3:0]== gray_w_ptr[P_SIZE-3:0]);

endmodule


