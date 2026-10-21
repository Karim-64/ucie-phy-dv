import Universal_pkg ::* ; 

module WR_Control_MBRX #(parameter W_D_SIZE=128, parameter WIDTH_DEGRADE_LENGTH=3)
(
input  logic                 CLK,R_RST_n                , // MB CLK
input  logic [W_D_SIZE-1:0]  Ip_Bytes                   , // Data Lanes to be sent to the D2D
input  logic                 EN                         ,    
input  logic                 Deser_Done                 , // signal that indicate that Data was Deserialized 
input  logic [WIDTH_DEGRADE_LENGTH-1:0] Width_Degrade   , // (011->all lanes Operational, 001->7:0(Least Significant Lanes Operational), 010->15:8 (Most Significant Lanes Operational))
output logic                 WR_EN                      , // FIFO Write Enable & Data
output logic [W_D_SIZE-1:0]  WR_DATA                    
);

//-------------------Internal Signals-----------------------//
logic [63:0] back_reg;   // to back the first 8 byte when width degrade is applied
//---------------------------------------------------------//

//-------------------FSM-----------------------------------//

typedef enum logic {
   First_Frame  = 1'b0,
   Second_Frame = 1'b1
} state_t;
state_t current_state, next_state;

always_ff @(posedge CLK or negedge R_RST_n) begin //**********states_transition************//
   if (!R_RST_n) begin
      current_state <= First_Frame;
   end else begin
      current_state <= next_state;
   end
end

always_comb begin
   case (current_state)
      First_Frame: begin
         if (EN && Deser_Done) begin
            if (Width_Degrade != 3'b011) begin
               next_state = Second_Frame;
            end else begin
               next_state = current_state;
            end
         end else begin
            next_state = current_state;
         end
      end

      Second_Frame: begin
         if (EN && Deser_Done) begin
            next_state = First_Frame;
         end else begin
            next_state = current_state;
         end
      end
   endcase
end

always_ff @(posedge CLK or negedge R_RST_n) begin //**********outputs_transition************//
   if (!R_RST_n) begin
      WR_EN   <= 'b0;
      back_reg <= 'b0;
      WR_DATA <= 'b0;
   end else if (current_state == First_Frame) begin
      WR_EN <= 'b0;

      if (EN && Deser_Done) begin
         if (Width_Degrade == 3'b001) begin
            back_reg <= Ip_Bytes[63:0];
         end else if (Width_Degrade == 3'b010) begin
            back_reg <= Ip_Bytes[127:64];
         end else if (Width_Degrade == 3'b011) begin
            WR_EN   <= 1'b1;
            WR_DATA <= Ip_Bytes;
         end else begin
            WR_EN <= 1'b0;
         end
      end
   end else if (current_state == Second_Frame) begin
      if (EN && Deser_Done) begin
         WR_EN <= 1'b1;
         if (Width_Degrade == 3'b001)
            WR_DATA <= {Ip_Bytes[63:0], back_reg};
         else if (Width_Degrade == 3'b010) 
            WR_DATA <= {Ip_Bytes[127:64], back_reg};
         else 
            WR_EN <= 1'b0;
      end
   end
end

//------------------------------------------------------------------//

endmodule
