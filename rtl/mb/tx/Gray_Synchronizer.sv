//implementing DataBus Gray Convertor Synchronizer
module Gray_Synchronizer  #( parameter DATA_SIZE = 2 )
(
  input   logic                   MB_CLK,      // Destination clock domain
  input   logic                   RST_n,       // Active-low asynchronous reset (synch. to destination clock domain)
  input   logic  [DATA_SIZE-1:0]  Async_Data,  // Binary input

  output  logic  [DATA_SIZE-1:0]  Sync_Data    // Synchronized Binary output
  );


//internal signals
logic  [DATA_SIZE-1:0]  Async_Data_Gray;   // Converting Binary input into Gray
logic  [DATA_SIZE-1:0]  Sync_Data_Gray;    // Synchronized Gray input
logic  [DATA_SIZE-1:0]  ff1, ff2;          // Internal flip-flop stages


always_comb begin
        Async_Data_Gray = Async_Data ^ (Async_Data >> 1);
end


always_ff @(posedge MB_CLK or negedge RST_n) begin
  if (!RST_n) begin
    ff1 <= 'b0;
    ff2 <= 'b0;
  end else begin
    ff1 <= Async_Data_Gray;  // First stage
    ff2 <= ff1;           // Second stage
  end
end


assign Sync_Data_Gray = ff2;


// Convert Gray to Binary
always_comb begin
  Sync_Data[DATA_SIZE-1] = Sync_Data_Gray[DATA_SIZE-1];  // MSB stays the same
  for (int i = DATA_SIZE-2; i >= 0; i--) begin
    Sync_Data[i] = Sync_Data[i+1] ^ Sync_Data_Gray[i];
  end
end


endmodule 

