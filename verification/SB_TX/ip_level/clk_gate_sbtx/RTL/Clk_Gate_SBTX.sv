
/*---------Description------------------//

this Module Generates the Clock Strobe accompanied 
with Data sent on the SB Bus (Messages/Pattern).

//---------------------------------------*/


module Clk_Gate_SBTX
(
input  logic  CLK        ,
input  logic  Enable,Load,
output logic SBTX_CLK
);

//internal signals
logic latch_out;

always_latch begin

    if (!CLK) 
        latch_out = Enable | Load;

end

assign SBTX_CLK = latch_out & CLK;

endmodule
