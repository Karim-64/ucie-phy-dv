//implementing Serializer
module Serializer (
  input                MB_CLK, 
  input                SER_EN,
  input        [7:0]   DATA,     // 8-bit parallel input

  output  logic        SER_OUT        // Serialized output
  );


  //internal signals
  reg   [7:0]  in_data;         // declare 8-bit register
  logic [3:0] counter = 4'b0;
  logic       flag = 0;
  logic       SER_OUT_reg; 


// Assign Data_Out
assign SER_OUT = (SER_EN && !flag) ? DATA[0] : ((SER_EN && flag) ? SER_OUT_reg : 1'b0);



  always@(posedge MB_CLK)
    begin
      if(SER_EN && !flag) begin
          flag <= 1;
          SER_OUT_reg <= DATA[1];         
          in_data <= DATA;
          counter <= 4'b0010;
      end else if(SER_EN && flag)begin
          SER_OUT_reg <= in_data[2];         // Transmit the remaining 6 bits
	  in_data[2] <= in_data[3];
	  in_data[3] <= in_data[4];
	  in_data[4] <= in_data[5];
	  in_data[5] <= in_data[6];
	  in_data[6] <= in_data[7];
          counter <= counter + 1'b1;
          if( counter == 4'b1000 ) begin
             counter <= 'b0;
             flag <= 0;
          end
            
          
      end else begin
          SER_OUT_reg <= 1'b0;
          in_data <= 'b0;
          counter <= 'b0;
          flag <= 0;
      end
      
    end


endmodule 
