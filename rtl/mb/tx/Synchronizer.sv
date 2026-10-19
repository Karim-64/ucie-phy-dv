//implementing inputs synchronizer
module Synchronizer
(
  input        CLK, 
  input        RST, 
  input        UnSynch_Input,    
    
  output  reg  Synch_Output 
  );
  

  //internal signals
  logic  UnSynch_Input_reg;

  logic  UnSynch_Input_reg_2;


  //Synchronizing input signals
  always @(posedge CLK or negedge RST)
   begin
     if(!RST) begin
       UnSynch_Input_reg <= 1'b0;
       UnSynch_Input_reg_2 <= 1'b0;
     end else begin
       UnSynch_Input_reg <= UnSynch_Input;
       UnSynch_Input_reg_2 <= UnSynch_Input_reg;
     end

   end


assign  Synch_Output  =  UnSynch_Input_reg_2;


endmodule