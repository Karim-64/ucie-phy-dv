module demux_SBTX #(parameter DATA_WIDTH = 64) (
    
    input  logic [DATA_WIDTH-1:0] din,   // Data input
    input  logic [1:0] sel,        // Select signal (2-bit for 4 outputs)
    output logic [DATA_WIDTH-1:0] dout0, // Output 0
    output logic [DATA_WIDTH-1:0] dout1, // Output 1
    output logic [DATA_WIDTH-1:0] dout2, // Output 2
    output logic [DATA_WIDTH-1:0] dout3  // Output 3
);

always_comb begin
    // Default values (prevent latches)
    dout0 = '0;
    dout1 = '0;
    dout2 = '0;
    dout3 = '0;

    case (sel)
        2'b00: dout0 = din;
        2'b01: dout1 = din;
        2'b10: dout2 = din;
        2'b11: dout3 = din;
        default: ; // Do nothing (default case)
    endcase
end

endmodule

