//implementing 2x1 bit Multiplexer
module MUX (
  input           IN_0,
  input           IN_1, 
  input           SEL_3,
  output  reg     OUT
 );

 
assign OUT = SEL_3 ? IN_1 : IN_0 ;
 
 
endmodule
