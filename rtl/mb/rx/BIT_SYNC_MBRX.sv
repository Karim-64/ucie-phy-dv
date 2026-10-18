
module BIT_SYNC_MBRX # ( 
   parameter NUM_STAGES = 2 ,
   parameter BUS_WIDTH = 1 
)(
input    logic                         CLK,
input    logic                         RST,
input    logic     [BUS_WIDTH-1:0]   ASYNC,
output   logic       [BUS_WIDTH-1:0]   SYNC
);


logic [NUM_STAGES-1:0] sync_reg [BUS_WIDTH-1:0] ;  

integer i,j;
					 
//----------------- Multi flop synchronizer --------------

always_ff @(posedge CLK or negedge RST)
 begin
  if(!RST)   
   begin
     for (i=0; i<BUS_WIDTH; i=i+1)
      sync_reg[i] <= 'b0 ;
   end
  else
   begin
    for (i=0; i<BUS_WIDTH; i=i+1)
     sync_reg[i] <= {sync_reg[i][NUM_STAGES-2:0],ASYNC[i]};   // {SYNC,sync_reg} <= {sync_reg[NUM_STAGES-1:0],ASYNC};
   end  
 end


always_comb
 begin
  for (j=0; j<BUS_WIDTH; j=j+1)
    SYNC[j] = sync_reg[j][NUM_STAGES-1] ; 
 end  

endmodule
