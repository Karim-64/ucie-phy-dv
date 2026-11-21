// Generates the SBINIT sideband training pattern and starts the 64-cycle timer.
// Each enabled clock cycle outputs the current pattern bit and toggles the
// internal pattern state. Disabling the generator re-arms the pattern to one.

module Pattern_Generator_SBTX (
    input  logic CLK,
    input  logic RST_n,
    input  logic Patt_Gen_En,
    output logic start_64,
    output logic SBTX_DATA
);

    logic Pattern;

    always_ff @(posedge CLK or negedge RST_n) begin
        if (!RST_n) begin
            Pattern <= 1'b1;
        end else if (Patt_Gen_En) begin
            Pattern <= ~Pattern;
        end else begin
            Pattern <= 1'b1;
        end
    end

    always_ff @(posedge CLK or negedge RST_n) begin
        if (!RST_n) begin
            SBTX_DATA <= 1'b0;
            start_64  <= 1'b0;
        end else if (Patt_Gen_En) begin
            SBTX_DATA <= Pattern;
            start_64  <= 1'b1;
        end else begin
            SBTX_DATA <= 1'b0;
            start_64  <= 1'b0;
        end
    end

endmodule