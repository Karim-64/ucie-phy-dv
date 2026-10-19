//implementing 3x1 Valid Multiplexer
module VLD_MUX (
  input        [7:0]   IN_0, 
  input        [7:0]   IN_1,
  input        [7:0]   IN_2,
  input        [7:0]   IN_3,
  input        [1:0]   SEL_1,
  output  reg  [7:0]   OUT
 );


always @(*)
 begin
   case(SEL_1)
     2'b00: begin
             OUT = IN_0;
            end
     2'b01: begin
             OUT = IN_1;
            end
     2'b10: begin
             OUT = IN_2;
            end  
     2'b11: begin
             OUT = IN_3;
            end  
     default : begin 
              	OUT = 'b0;
               end	              
   endcase
 end
 

endmodule