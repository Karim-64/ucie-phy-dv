module Mux2x1 #(
    parameter DATA_WIDTH = 64  // Width of input data
)(
    input wire [DATA_WIDTH:0] in0, // First input
    input wire [DATA_WIDTH:0] in1, // Second input
    input wire sel,                   // Select signal
    output reg [DATA_WIDTH:0] out    // Output
);

    always @(*) begin
        out = sel ? in1 : in0;
    end

endmodule
