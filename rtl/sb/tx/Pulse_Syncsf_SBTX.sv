module Pulse_synchronizer_sf_SBTX (
    input  logic        slow_clk,   // Slow clock
    input  logic        fast_clk,   // Fast clock
    input  logic        s_rst_n,    // Slow active-low reset
    input  logic        f_rst_n,    // Fast active-low reset
    input  logic        event_in,   // Event signal from the slow clock domain
    output logic        event_out   // Synchronized event signal in the fast clock domain
);

    // Slow clock domain logic
    logic toggle_ff; // Toggles when `event_in` is detected

    always_ff @(posedge slow_clk or negedge s_rst_n) begin
        if (!s_rst_n) begin
            toggle_ff <= 0;
        end else if (event_in) begin
            toggle_ff <= ~toggle_ff; // Toggle when event is detected
        end
    end

    // Fast clock domain logic
    logic sync_ff1, sync_ff2; // Synchronizing flip-flops
    logic toggle_sync;        // Edge detection for the toggle signal

    always_ff @(posedge fast_clk or negedge f_rst_n) begin
        if (!f_rst_n) begin
            sync_ff1 <= 0;
            sync_ff2 <= 0;
            toggle_sync <= 0;
        end else begin
            sync_ff1 <= toggle_ff;           // First stage synchronization
            sync_ff2 <= sync_ff1;           // Second stage synchronization
            toggle_sync <= sync_ff2; // Detect toggle in the fast clock domain
        end
    end

    assign event_out = toggle_sync ^ sync_ff2; // Asserted for one clock cycle in the fast clock domain

endmodule

