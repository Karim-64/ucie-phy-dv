//implementing 2x1 bit Multiplexer
module MUX_MBRX (
  input  logic        IN_0,
  input  logic        IN_1, 
  input  logic        SEL_3,
  output logic        OUT
 );

 
assign OUT = SEL_3 ? IN_1 : IN_0 ;
 
 
endmodule
