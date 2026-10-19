//implementing 2x1 bit Multiplexer
module MUX_SBTX #(parameter INPUT_WIDTH=5)
(
  input   logic [INPUT_WIDTH-1:0] IN_0   ,
  input   logic [INPUT_WIDTH-1:0] IN_1   , 
  input                           Mux_Sel,
  output  logic [INPUT_WIDTH-1:0] OUT
 );

 
assign OUT = Mux_Sel ? IN_1 : IN_0 ;
 
 
endmodule
