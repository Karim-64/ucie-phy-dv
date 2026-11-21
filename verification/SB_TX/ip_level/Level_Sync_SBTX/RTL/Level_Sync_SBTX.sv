module Level_Sync_SBTX
(
    input  logic CLK         ,    // Destination clock domain
    input  logic RST_n       ,    // Active-low asynchronous reset
    input  logic Async_Signal,    // Asynchronous input signal
    output logic Sync_Signal      // Synchronized output signal
);

    // Internal flip-flop stages
    logic ff1, ff2;

    always_ff @(posedge CLK or negedge RST_n) begin
        if (~RST_n) begin
            ff1 <= 1'b0;
            ff2 <= 1'b0;
        end else begin
            ff1 <= Async_Signal;  // First stage
            ff2 <= ff1;           // Second stage
        end
    end

    assign Sync_Signal = ff2;

endmodule

