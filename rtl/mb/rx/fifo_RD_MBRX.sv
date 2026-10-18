
module fifo_rd_MBRX #(parameter P_SIZE = 4)
  (
   input  logic                   r_clk,              // read domian operating clock
   input  logic                   r_rstn,             // read domian active low reset 
   input  logic                   r_inc,              // read Enable 
   input  logic   [P_SIZE-1:0]    sync_wr_ptr,        // synced gray coded write pointer         
   output logic   [P_SIZE-2:0]    rd_addr,            // generated binary read address
   output logic                   empty,              // fifo empty flag
   output logic [P_SIZE-1:0]      gray_rd_ptr         // generated gray coded read address
);

logic [P_SIZE-1:0]  rd_ptr ;
integer i;

// increment binary pointer
always_ff @(posedge r_clk or negedge r_rstn)
begin

    if(!r_rstn) begin
    rd_ptr <= 0 ;
    end
    else if (!empty && r_inc) begin
    rd_ptr <= rd_ptr + 4;
    end

 end


// generation of read address
assign rd_addr = rd_ptr[P_SIZE-2:0];

// converting binary read pointer to gray coded
always @(posedge r_clk or negedge r_rstn)
begin
 if(!r_rstn)
   begin
    gray_rd_ptr <= 0 ;
   end
 else 
  begin
   gray_rd_ptr[P_SIZE-1]<=rd_ptr[P_SIZE-1];
   for(i=P_SIZE-2;i>=0;i=i-1)
   gray_rd_ptr[i]<=rd_ptr[i+1]^rd_ptr[i];
  end
 end


// generation of empty flag
assign empty = (sync_wr_ptr == gray_rd_ptr) ;

endmodule

