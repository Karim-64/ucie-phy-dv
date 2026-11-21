//implementing 2x1 bit Multiplexer
module MUX_SBRX #(parameter INPUT_WIDTH=5)
(
  input   logic [INPUT_WIDTH-1:0] in0   ,
  input   logic [INPUT_WIDTH-1:0] in1   , 
  input                           sel,
  output  logic [INPUT_WIDTH-1:0] out
 );

 
assign out = sel ? in1 : in0 ;
 
 
endmodule
