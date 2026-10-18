module Pulse_Synchronizer ( 
    input  logic src_CLK,      // Source clock
    input  logic src_RST,      // Active-low Source reset
    input  logic src_pulse,    // Pulse generated in lclk domain
    input  logic dst_CLK,      // Destination clock
    input  logic dst_RST,      // Active-low Destination reset
    output logic dst_pulse     // Synchronized pulse in MB_CLK domain
);

    // Synchronization signals
    logic src_pulse_ff;               // Pulse registered in src_clk domain
    logic toggle;                     // Toggle signal in src_clk domain
    logic toggle_sync1, toggle_sync2; // Synchronizers
    logic toggle_dst_d;               // Delayed toggle in dst_clk domain

    // Generate toggle in src_CLK domain when pulse happens
    always_ff @(posedge src_CLK or negedge src_RST) begin
        if (!src_RST) begin
            src_pulse_ff <= 1'b0;
            toggle       <= 1'b0;
        end else begin
            src_pulse_ff <= src_pulse;
            if (src_pulse && !src_pulse_ff)
                toggle <= ~toggle;
            else
                toggle <= toggle; // Hold the value if no new pulse
        end
    end

    // Synchronize the toggle into dst_CLK domain (using 2 flip-flops)
    always_ff @(posedge dst_CLK or negedge dst_RST) begin
        if (!dst_RST) begin
            toggle_sync1 <= 1'b0;
            toggle_sync2 <= 1'b0;
        end else begin
            toggle_sync1 <= toggle;
            toggle_sync2 <= toggle_sync1;
        end
    end

    // Detect toggle edge in dst_CLK domain and generate a one-cycle pulse
    always_ff @(posedge dst_CLK or negedge dst_RST) begin
        if (!dst_RST) begin
            toggle_dst_d <= 1'b0;
            dst_pulse    <= 1'b0;
        end else begin
            toggle_dst_d <= toggle_sync2;
            dst_pulse    <= toggle_sync2 ^ toggle_dst_d;
        end
    end

endmodule

