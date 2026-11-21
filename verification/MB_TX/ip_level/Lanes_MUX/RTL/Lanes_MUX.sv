//implementing 2x1 Lanes Multiplexer
module Lanes_MUX (
  input        [7:0]   IN_0 [15:0],
  input        [7:0]   IN_1 [15:0], 
  input                SEL_2,
  output  reg  [7:0]   OUT  [15:0]
 );

 
assign OUT = SEL_2 ? IN_1 : IN_0 ;
 
 
endmodule
