
/*---------Description------------------//

this Module Handles all the Cases that returns 
Credits for D2D after 
1-serializing Remote D2D Messages
2-Handling a Local RAR
3-Detecting an UIE
4-Returning UR Completions

//---------------------------------------*/

module Credits_Handler_SBTX 
(
    input  logic CLK, RST_n,
    input  logic Comp_Sent, UIE,
    input  logic Credit,
    input  logic D2D_PHY_Marker, Data_Marker, Comp_Marker,
    output logic pl_cfg_crd
);

    // Internal Signals
    logic D2D_Credit, Completion;
    logic [1:0] Saved_Credit;
    logic Prev_Comp_Sent;

    // Signal Assignments
    assign D2D_Credit = D2D_PHY_Marker & ~Data_Marker & ~Comp_Marker;
    assign Completion = Comp_Sent & ~Prev_Comp_Sent;

    always_ff @(posedge CLK or negedge RST_n) begin

        if (!RST_n) begin

            pl_cfg_crd      <= 1'b0;
            Saved_Credit    <= 2'b00;
            Prev_Comp_Sent  <= 1'b0;

        end else begin

            // Save credits based on event combinations
            if (Completion & D2D_Credit & UIE)

                Saved_Credit <= 2'b10;

            else if ((Completion & D2D_Credit) ||
                     (Completion & UIE) ||
                     (D2D_Credit & UIE) ||
                     (Credit & UIE))

                Saved_Credit <= 2'b01;

            // Set pl_cfg_crd when any event occurs
            if (Completion || UIE || D2D_Credit || Credit) begin

                pl_cfg_crd <= 1'b1;

            end else if (Saved_Credit > 2'b00) begin

                pl_cfg_crd   <= 1'b1;
                Saved_Credit <= Saved_Credit - 2'b01;

            end else begin

                pl_cfg_crd <= 1'b0;

            end

            // Update previous states
            Prev_Comp_Sent <= Comp_Sent;
        end
    end
endmodule