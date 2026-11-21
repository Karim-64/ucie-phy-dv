
/*---------Description------------------//

this Module Manages Messages coming from Decoder & Encoder 
and follows a Priority-Lock Mechanism accompanied with Resending Mechanism.

//---------------------------------------*/

import Universal_pkg ::* ; 

module Priority_Encoder_SBTX #(parameter DATA_WIDTH = 64)
(
    input  logic  CLK, RST_n                                      ,
    input  logic  PHY_En, D2D_En                                  ,
    input  logic  Data_Marker_D2D, Data_Marker_PHY,Comp_Marker_D2D,
    input  logic  [DATA_WIDTH-1:0] PHY_Data, D2D_Data             ,
    output logic  FIFO_WR                                         ,
    output logic  [DATA_WIDTH-1:0] FIFO_Data                      ,
    output logic  Data_Marker, D2D_PHY_Marker,Comp_Marker         ,  // Control bits saved in the CDC FIFO
    output logic  D2D_Resend_Req,PHY_Resend_Req                      // Notifies D2D to resend if PHY was chosen
);

//********** Named Priority Levels *********//
localparam NONE        = 2'b00;  // No request
localparam D2D_ONLY    = 2'b01;  // Only D2D is enabled
localparam PHY_ONLY    = 2'b10;  // Only PHY is enabled
localparam BOTH_ACTIVE = 2'b11;  // Both are enabled
//*******************************************//

// Internal Signals
logic [1:0] Priorities;
logic [1:0] Last_Priority;   // Stores last granted priority
logic Priority_Lock;         // Locks the priority for 2 cycles when Data_Marker is asserted
logic Lock_Counter;          // Counter for enforcing two-cycle rule

// Signals Assignment
assign Priorities = {PHY_En,D2D_En};

//Resend Requests logic 
always_ff @(posedge CLK or negedge RST_n) begin

  if (~RST_n) begin

    D2D_Resend_Req <= 1'b0;
    PHY_Resend_Req <= 1'b0;

  end else begin

    // Default assignments
    D2D_Resend_Req <= 1'b0;
    PHY_Resend_Req <= 1'b0;

    case (Priorities)

      PHY_ONLY: PHY_Resend_Req <= (Last_Priority != PHY_ONLY & Priority_Lock) ? 1'b1 : 1'b0;

      D2D_ONLY: D2D_Resend_Req <= (Last_Priority != D2D_ONLY & Priority_Lock) ? 1'b1 : 1'b0;

      BOTH_ACTIVE: D2D_Resend_Req <= 1'b1;

    endcase
  end

end


always_ff @(posedge CLK or negedge RST_n) begin

    if (!RST_n) begin

        Last_Priority   <= NONE;
        Priority_Lock   <= 1'b0;
        Lock_Counter    <= 1'b0;

    end else begin

        if (Priority_Lock) begin
            // Decrement the lock counter
            if (Lock_Counter) begin 
                Priority_Lock <= 1'b0; // Unlock after second cycle
                Lock_Counter  <= 1'b0;
                Last_Priority <= NONE;
            end else
                Lock_Counter <= 1'b1;

        end else begin

            case (Priorities)

                D2D_ONLY: begin
                    Last_Priority  <= D2D_ONLY;
                    if (Data_Marker_D2D)
                        Priority_Lock  <= 1'b1;
                end

                PHY_ONLY: begin
                    Last_Priority  <= PHY_ONLY;
                    if (Data_Marker_PHY)
                        Priority_Lock  <= 1'b1; 
                end

                BOTH_ACTIVE: begin
                    Last_Priority  <= PHY_ONLY;
                    if (Data_Marker_PHY)
                        Priority_Lock  <= 1'b1;
                end

                default: Last_Priority  <= NONE;

            endcase
        end
    end
end

// Combinational logic for output selection
always_comb begin
    
    // Default values
    FIFO_WR         = 'b0;
    FIFO_Data       = 'b0;
    Data_Marker     = 'b0;
    D2D_PHY_Marker  = 'b0;
    Comp_Marker     = 'b0;

    case (Last_Priority)

        D2D_ONLY: begin
            FIFO_WR = 1'b1;
            FIFO_Data = D2D_Data;
            Data_Marker = Data_Marker_D2D;
            D2D_PHY_Marker = 1'b1;
            Comp_Marker    = Comp_Marker_D2D;
        end

        PHY_ONLY: begin
            FIFO_WR = 1'b1;
            FIFO_Data = PHY_Data;
            Data_Marker = Data_Marker_PHY;
            D2D_PHY_Marker = 1'b0;
            Comp_Marker    = 1'b0;
        end
        
        default: begin
            // No operation
        end
    endcase
end

endmodule
