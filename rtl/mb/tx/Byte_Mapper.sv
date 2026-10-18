//implementing Byte to Lane Mapper
module Byte_Mapper (
  input                MB_CLK, 
  input                BYTE_MAP_EN,     
  input        [1:0]   width_degrade_LTSM_Synch,
  input  [63:0][7:0]   lp_data_Synch,

  output  reg  [7:0]   Lanes [15:0],
  output  reg  [7:0]   Valid,
  output  reg          VLD_SER_EN,
  output  reg          LANE_SER_EN,
  output  reg          Done_2
  );


  logic [5:0] byte_index = 0;    // Index for tracking the byte group (0 to 63)
  logic [2:0] counter = 0;
  logic       flag = 1'b0;
  logic       flag_2 = 1'b0;
  //int j = 0;
  reg   [63:0][7:0] lp_data_reg;


  // Byte-to-Lane Mapping
  always @(posedge MB_CLK)
   begin

     if (BYTE_MAP_EN)
       begin

        if(counter == 0)
         begin
          if(!flag_2)
           begin

             counter <= counter + 1;
             if(!flag)
               begin
                 for (int i = 0; i < 64; i = i + 1) begin
                     lp_data_reg[i] = lp_data_Synch[i];
                 end
                 flag <= 1'b1;
               end

             case(width_degrade_LTSM_Synch)

                  2'b00: begin
                           for (int i = 0; i < 16; i++) begin
                               Lanes[i] <= 8'b0;      // High-impedance state
                            end
                            Valid <= 8'b0;
                            VLD_SER_EN <= 0;
                            LANE_SER_EN <= 0;
                            byte_index <= 0; // Reset index
                            Done_2 <= 1'b0;
                            flag <= 1'b0;
                            flag_2 <= 1'b0;
                          end

                  2'b01: begin
                           for (int m = 8; m < 16; m++) begin
                               Lanes[m] <= 8'b0;      // High-impedance state
                           end

                           // Map bytes from lp_data to Lanes
                           // Normal mapping: map 8 bytes starting from the first available lane
                           for (int i = 0; i < 8; i++) begin
                              Lanes[i] <= lp_data_reg[byte_index + i];
                           end
                              

                           // Update byte_index for next 8-byte group
                           if (byte_index + 8 < 64) 
                              begin
                                byte_index <= byte_index + 8;
                                //j <= 0;
                                Done_2 <= 1'b0;
                              end 
                          else 
                            begin
                              byte_index <= 0; // All bytes are processed
                              Done_2 <= 1'b1;
                              flag <= 1'b0;
                              flag_2 <= 1'b1;
                              //j <= 0;
                            end

                         // Valid output & Serializers enable signals
                         Valid <= 8'b00001111;
                         VLD_SER_EN <= 1;
                         LANE_SER_EN <= 1;
                      end

               2'b10: begin
                        for (int m = 0; m < 8; m++) begin
                            Lanes[m] <= 8'b0;      // High-impedance state
                        end

                        // Map bytes from lp_data to Lanes
                        // Normal mapping: map 8 bytes starting from the first available lane
                        for (int i = 8; i < 16; i++) begin
                           Lanes[i] <= lp_data_reg[byte_index + (i-8)];
                           //Lanes[i] <= lp_data_reg[byte_index + j];
                           //j++;
                        end


                       // Update byte_index for next 8-byte group
                       if (byte_index + 8 < 64) 
                          begin
                            byte_index <= byte_index + 8;
                            //j <= 0;
                            Done_2 <= 1'b0;
                          end 
                      else 
                        begin
                          byte_index <= 0; // All bytes are processed
                          Done_2 <= 1'b1;
                          flag <= 1'b0;
                          flag_2 <= 1'b1;
                          //j <= 0;
                        end

                      // Valid output & Serializers enable signals
                      Valid <= 8'b00001111;
                      VLD_SER_EN <= 1;
                      LANE_SER_EN <= 1;
                   end

            2'b11: begin
                     // Map bytes from lp_data to Lanes
                     // Normal mapping: map 16 bytes starting from the first available lane
                     for (int i = 0; i < 16; i++) begin
                        Lanes[i] <= lp_data_reg[byte_index + i];
                     end


                     // Update byte_index for next 16-byte group
                     if (byte_index + 16 < 64) 
                        begin
                          byte_index <= byte_index + 16;
                          //j <= 0;
                          Done_2 <= 1'b0;
                        end 
                     else 
                       begin
                         byte_index <= 0; // All bytes are processed
                         Done_2 <= 1'b1;
                         flag <= 1'b0;
                         flag_2 <= 1'b1;
                         //j <= 0;
                       end

                     // Valid output & Serializers enable signals
                     Valid <= 8'b00001111;
                     VLD_SER_EN <= 1;
                     LANE_SER_EN <= 1;
                  end
           endcase
         end

        else
         begin
             Valid <= 8'b0;
             VLD_SER_EN <= 0;
             Done_2 <= 1'b0;
             for (int i = 0; i < 16; i++) begin
               Lanes[i] <= 8'b0;
             end
         end

     end

      else 
        begin
          counter <= counter + 1;
          if( counter == 3'b111 )
            counter <= 0;
        end 

    end
     

    else 
       begin
         // Reset outputs when not enabled
         for (int i = 0; i < 16; i++) begin
             Lanes[i] <= 8'b0;
         end
         Valid <= 8'b0;
         VLD_SER_EN <= 0;
         LANE_SER_EN <= 0;
         byte_index <= 0; // Reset index
         counter <= 0;
         //j <= 0;
         Done_2 <= 1'b0;
         flag <= 1'b0;
         flag_2 <= 1'b0;
       end
end


endmodule