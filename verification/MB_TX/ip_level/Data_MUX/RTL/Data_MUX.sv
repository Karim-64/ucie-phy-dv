//implementing 2x1 Data Multiplexer
module Data_MUX (
  input        [63:0] [7:0]  IN_0,
  input        [63:0] [7:0]  IN_1, 
  input                      SEL_5,
  output  reg  [63:0] [7:0]  OUT  
 );

 
assign OUT = SEL_5 ? IN_1 : IN_0 ;
 
 
endmodule
