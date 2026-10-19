//implementing Valid Pattern Generator
module VALTRAIN_Generator (
  input                MB_CLK, 
  input                VALTRAIN_EN,

  output  reg  [7:0]   Valid,
  output  reg          VLD_SER_EN,
  output  reg          Done_1
  );


  logic [2:0] byte_count = 3'b0;
  logic [7:0] iteration_count = 8'b0;
  logic       flag = 1'b0;

  // PerLane ID Generator
  always @(posedge MB_CLK)
   begin

     if (VALTRAIN_EN)
       begin
      
           if(byte_count == 0)
            begin

             if(!flag)
              begin
                byte_count <= byte_count + 1'b1;
                // Valid output pattern
                Valid <= 8'b00001111;
                iteration_count <= iteration_count + 1'b1;
                if(iteration_count == 8'b01111111)
                  begin
                    iteration_count <= 8'b0;
                    Done_1 <= 1'b1;      // Mark process as done after 128 iterations
                    flag <= 1'b1;
                  end
                else
                  Done_1 <= 1'b0;

                // Valid Serializer enable signal
                VLD_SER_EN <= 1;
             end

            else
             begin
              Valid <= 8'b0;
              VLD_SER_EN <= 0;
              Done_1 <= 1'b0;
             end

           end

          else 
             begin
               byte_count <= byte_count + 1'b1;
               if( byte_count == 3'b111 )
                 byte_count <= 0;
             end 

      end

     else 
       begin
         Valid <= 8'b0;
         VLD_SER_EN <= 0;
         iteration_count <= 8'b0;
         byte_count <= 0;
         Done_1 <= 1'b0;
         flag <= 1'b0;
       end
end


endmodule