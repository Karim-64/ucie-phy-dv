//implementing PerLane ID Generator
module PerLaneID_Generator (
  input                MB_CLK, 
  input                PerLaneID_EN,
  input        [1:0]   width_degrade_LTSM_Synch,

  output  reg  [7:0]   Lanes [15:0],
  output  reg  [7:0]   Valid,
  output  reg          VLD_SER_EN,
  output  reg          LANE_SER_EN,
  output  reg          Done_3
  );


  logic [2:0] byte_count = 3'b0;
  logic       byte_position = 1'b0;
  logic [7:0] iteration_count = 8'b0;
  logic       flag = 1'b0;
  logic [15:0] PerLaneID_Pattern [15:0];

	always @(*) begin
		for (int i = 0; i < 16; i = i + 1) begin
			PerLaneID_Pattern[i] = (PerLaneID_EN) ? ({4'b1010, i[7:0] , 4'b1010}) : 0;   // PerLaneID Pattern Generation
			end
   end


  // PerLane ID Generator
  always @(posedge MB_CLK)
   begin

     if (PerLaneID_EN)
       begin
        
        if(byte_count == 0)
          begin
            if(!flag)
              begin
                byte_count <= byte_count + 1'b1;

                if(byte_position == 0)
                  begin
                    byte_position <= 1'b1;
                    Done_3 <= 1'b0;
                    
                    // Normal mapping: map first pattern bytes starting from the first available lane
                    // Assign Lanes based on width_degrade_LTSM_Synch encoding
                    case (width_degrade_LTSM_Synch)
                      2'b00: begin // All Lanes have zeros
                         for (int i = 0; i < 16; i++) begin
                              Lanes[i] <= 8'b0;
                          end
                          // Valid output & Serializers enable signals
                          Valid <= 8'b0;
                          VLD_SER_EN <= 0;
                          LANE_SER_EN <= 0;
                      end
                      2'b01: begin // Lanes 0-7 have data, 8-15 have zeros
                         for (int i = 0; i < 8; i++) begin
                            Lanes[i] <= PerLaneID_Pattern[i][7:0];
                         end
                         for (int i = 8; i < 16; i++) begin
                             Lanes[i] <= 8'b0;
                         end
                         // Valid output & Serializers enable signals
                         Valid <= 8'b00001111;
                         VLD_SER_EN <= 1;
                         LANE_SER_EN <= 1;
                      end
                      2'b10: begin // Lanes 8-15 have data, 0-7 have zeros
                         for (int i = 0; i < 8; i++) begin
                            Lanes[i] <= 8'b0;
                         end
                         for (int i = 8; i < 16; i++) begin
                            Lanes[i] <= PerLaneID_Pattern[i][7:0];
                         end
                         // Valid output & Serializers enable signals
                         Valid <= 8'b00001111;
                         VLD_SER_EN <= 1;
                         LANE_SER_EN <= 1;
                      end
                      2'b11: begin // All Lanes have data
                         for (int i = 0; i < 16; i++) begin
                            Lanes[i] <= PerLaneID_Pattern[i][7:0];
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
                    byte_position <= 1'b0;

                    // Normal mapping: map last pattern bytes starting from the first available lane
                    // Assign Lanes based on width_degrade_LTSM_Synch encoding
                    case (width_degrade_LTSM_Synch)
                      2'b00: begin // All Lanes have zeros
                         for (int i = 0; i < 16; i++) begin
                              Lanes[i] <= 8'b0;
                          end
                          // Valid output & Serializers enable signals
                         Valid <= 8'b0;
                         VLD_SER_EN <= 0;
                         LANE_SER_EN <= 0;
                      end
                      2'b01: begin // Lanes 0-7 have data, 8-15 have zeros
                         for (int i = 0; i < 8; i++) begin
                            Lanes[i] <= PerLaneID_Pattern[i][15:8];
                         end
                         for (int i = 8; i < 16; i++) begin
                             Lanes[i] <= 8'b0;
                         end
                         // Valid output & Serializers enable signals
                         Valid <= 8'b00001111;
                         VLD_SER_EN <= 1;
                         LANE_SER_EN <= 1;
                      end
                      2'b10: begin // Lanes 8-15 have data, 0-7 have zeros
                         for (int i = 0; i < 8; i++) begin
                            Lanes[i] <= 8'b0;
                         end
                         for (int i = 8; i < 16; i++) begin
                            Lanes[i] <= PerLaneID_Pattern[i][15:8];
                         end
                         // Valid output & Serializers enable signals
                         Valid <= 8'b00001111;
                         VLD_SER_EN <= 1;
                         LANE_SER_EN <= 1;
                      end
                      2'b11: begin // All Lanes have data
                         for (int i = 0; i < 16; i++) begin
                            Lanes[i] <= PerLaneID_Pattern[i][15:8];
                         end
                         // Valid output & Serializers enable signals
                         Valid <= 8'b00001111;
                         VLD_SER_EN <= 1;
                         LANE_SER_EN <= 1;
                      end
                    endcase

                   iteration_count <= iteration_count + 1'b1;
                   if(iteration_count == 8'b01111111)
                     begin
                      iteration_count <= 8'b0;
                      Done_3 <= 1'b1;      // Mark process as done after 128 iterations
                      flag <= 1'b1;
                     end
                   else
                     begin
                      Done_3 <= 1'b0;
                     end
                 end

           end
         else
           begin
             Valid <= 8'b0;
             VLD_SER_EN <= 0;
             Done_3 <= 1'b0;
             for (int i = 0; i < 16; i++) begin
               Lanes[i] <= 8'b0;
             end
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
         // Reset outputs when not enabled
         for (int i = 0; i < 16; i++) begin
             Lanes[i] <= 8'b0;
         end
         Valid <= 8'b0;
         VLD_SER_EN <= 0;
         LANE_SER_EN <= 0;
         iteration_count <= 8'b0;
         byte_count <= 0;
         byte_position <= 1'b0;
         Done_3 <= 1'b0;
         flag <= 1'b0;
       end
end


endmodule