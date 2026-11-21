module Synchronizer_SBRX (
    input  clk_dst,       // destination clock
    input  rst_n,         // active-low async reset
    input  signal_src,    // asynchronous signal from source domain
    output signal_dst     // synchronized signal in destination domain
);

    reg sync_ff1, sync_ff2;

    always @(posedge clk_dst or negedge rst_n) begin
        if (!rst_n) begin
            sync_ff1 <= 1'b0;
            sync_ff2 <= 1'b0;
        end else begin
            sync_ff1 <= signal_src;
            sync_ff2 <= sync_ff1;
        end
    end

    assign signal_dst = sync_ff2;

endmodule
