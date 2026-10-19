import Universal_pkg ::* ; 

module Valid_Checker_MBRX #(parameter FRAME_LENGTH=8)
(
    input  logic        CLK                                  ,
    input  logic        RST_n                                ,
    input  LTSM_states  LTSM_State                           ,
    input  logic        Sampled_Bit                          ,
    input  logic        Width_Degrade_Update                 ,
    input  logic [WIDTH_DEGRADE_LENGTH-1:0] Width_Degrade    ,
    input  logic        Valid_EN                             ,
    input  logic [ERROR_THRESHOLD_LENGTH-1:0] Error_Threshold,
    output logic        Seq_Done                             ,
    output logic        Detec_succ                           ,
    output logic        Valid_Frame_Error                    ,
    output logic        Chunk_Error_Free                     ,
    output logic        Chunk_Errored
);

//-------------------Internal Signals----------------------//

logic [WIDTH_DEGRADE_LENGTH-1:0] Width_Degrade_reg;

logic [CHUNK_LENGTH:0] Chunk_Length;

logic [$clog2(FRAME_LENGTH)-1:0] Count; 
logic [CHUNK_LENGTH-1:0] Count_Chunk;
logic [$clog2(Cons_Iterations):0] Count_MB_cons;
logic [$clog2(Total_Iterations):0] Count_MB_total;
logic [ERROR_THRESHOLD_LENGTH-1:0] Total_Errors;

logic Test_Processing;
logic Frame_Error;
logic Test_Failed;

//****************** Width_Degrade *************************//

always_ff @(posedge CLK or negedge RST_n) begin 
    if(!RST_n) begin
        Chunk_Length <= 0;
        Width_Degrade_reg <= 0;
    end else if (LTSM_State == _RESET) begin
        Chunk_Length <= 4'd4;
        Width_Degrade_reg <= 3'b011;
    end else if (Width_Degrade_Update & !(Test_Processing)) begin
        Width_Degrade_reg <= Width_Degrade;
    end else begin
        if (Width_Degrade_reg != 3'b011)
            Chunk_Length <= 4'd8;
        else
            Chunk_Length <= 4'd4;
    end 
end

//***********************Main logic ************************//

assign Frame_Error = (Sampled_Bit != Valid_Frame[Count]) ? 1'b1 : 1'b0;

always_ff @(posedge CLK or negedge RST_n) begin
    if (!RST_n) begin
        Seq_Done         <= 'b0;
        Valid_Frame_Error<= 'b0;
        Detec_succ       <= 'b0;
        Test_Processing  <= 'b0;
        Test_Failed      <= 'b0;
        Total_Errors     <= 'b0;
        Chunk_Error_Free <= 'b0;
        Chunk_Errored    <= 'b0;
    end else if (LTSM_State == _ACTIVE && Valid_EN) begin
        Seq_Done         <= 1'b0;
        Chunk_Error_Free <= 'b0;
        Chunk_Errored    <= 'b0;
        Test_Processing  <= 1'b1;

        if (Frame_Error)
            Test_Failed <= 1'b1;

        if (Count == FRAME_LENGTH - 1) begin
            Seq_Done <= 1'b1;

            if (Count_Chunk == Chunk_Length - 1) begin
                if (Test_Failed || Frame_Error) begin
                    Chunk_Error_Free <= 'b0;
                    Chunk_Errored    <= 'b1;
                end else begin
                    Chunk_Error_Free <= 'b1;
                    Chunk_Errored    <= 'b0;
                end
                Test_Processing <= 'b0;
                Test_Failed     <= 'b0;
            end
        end
    end else if (LTSM_State == _MBINIT_REPAIRVAL && Valid_EN) begin
        Test_Processing  <= 1'b1;
        Seq_Done         <= 1'b0;

        if (Frame_Error)
            Test_Failed <= 1'b1;

        if (Count == FRAME_LENGTH - 1) begin
            Seq_Done       <= 1'b1;
            Test_Failed    <= 1'b0;

            if (Count_MB_total == Total_Iterations - 1) begin
                Test_Processing <= 'b0;

                if ((Count_MB_cons == Cons_Iterations) || 
                    (Count_MB_cons == Cons_Iterations - 1 && !(Test_Failed || Frame_Error))) begin
                    Valid_Frame_Error <= 1'b0;
                    Detec_succ        <= 1'b1;
                end else begin
                    Valid_Frame_Error <= 1'b1;
                    Detec_succ        <= 1'b0;
                end
            end
        end
    end else if ((LTSM_State == _MBTRAIN_VALVREF || 
                  LTSM_State == _MBTRAIN_VALTRAINCENTER || 
                  LTSM_State == _MBTRAIN_VALTRAINVREF) && Valid_EN) begin
        Test_Processing  <= 1'b1;
        Seq_Done         <= 1'b0;

        if (Frame_Error)
            Total_Errors <= Total_Errors + 12'b1;

        if (Count == FRAME_LENGTH - 1) begin
            Seq_Done <= 1'b1;

            if (Count_MB_total == Total_Iterations - 1) begin
                Test_Processing <= 'b0;

                if (Total_Errors + Frame_Error <= Error_Threshold) begin
                    Valid_Frame_Error <= 1'b0;
                    Detec_succ        <= 1'b1;
                end else begin
                    Valid_Frame_Error <= 1'b1;
                    Detec_succ        <= 1'b0;
                end
            end
        end
    end else begin
        Seq_Done         <= 'b0;
        Valid_Frame_Error<= 'b0;
        Detec_succ       <= 'b0;
        Test_Processing  <= 'b0;
        Test_Failed      <= 'b0;
        Total_Errors     <= 'b0;
        Chunk_Error_Free <= 'b0;
        Chunk_Errored    <= 'b0;
    end
end

//**************** Count Transitions ************************//

always_ff @(posedge CLK or negedge RST_n) begin
    if (!RST_n) begin
        Count          <= 'b0;
        Count_Chunk    <= 'b0;
        Count_MB_cons  <= 'b0;
        Count_MB_total <= 'b0;
    end else if (LTSM_State == _ACTIVE && Valid_EN) begin
        Count <= Count + 1;

        if (Count == FRAME_LENGTH - 1) begin
            Count       <= 'b0;
            Count_Chunk <= Count_Chunk + 1;

            if (Count_Chunk == Chunk_Length - 1)
                Count_Chunk <= 'b0;
        end
    end else if (LTSM_State == _MBINIT_REPAIRVAL && Valid_EN) begin
        Count <= Count + 1;

        if (Count == FRAME_LENGTH - 1) begin
            Count          <= 'b0;
            Count_MB_total <= Count_MB_total + 1;

            if (Count_MB_cons < Cons_Iterations) begin
                if (Test_Failed || Frame_Error)
                    Count_MB_cons <= 'b0;
                else
                    Count_MB_cons <= Count_MB_cons + 1;
            end
        end
    end else if ((LTSM_State == _MBTRAIN_VALVREF || 
                  LTSM_State == _MBTRAIN_VALTRAINCENTER || 
                  LTSM_State == _MBTRAIN_VALTRAINVREF) && Valid_EN) begin
        Count <= Count + 1;

        if (Count == FRAME_LENGTH - 1) begin
            Count          <= 'b0;
            Count_MB_total <= Count_MB_total + 1;
        end
    end else begin
        Count          <= 'b0;
        Count_Chunk    <= 'b0;
        Count_MB_cons  <= 'b0;
        Count_MB_total <= 'b0;
    end
end

endmodule
