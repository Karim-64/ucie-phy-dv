module Demux1x2 #(
	parameter DATA_WIDTH = 64 					// Generic parameter for data width (default is 64 bits)
)(
    input 		[DATA_WIDTH-1:0] 	data_in	, 	// Input Data
    input 							sel		, 	// Select Line
    output reg 	[DATA_WIDTH-1:0] 	out0	, 	// Output 0
    output reg 	[DATA_WIDTH-1:0] 	out1 		// Output 1
);

    always @(*) begin
		// Default all outputs to 0
        out0 = {DATA_WIDTH{1'b0}};
        out1 = {DATA_WIDTH{1'b0}};

        // Route data_in to the selected output
        case (sel)
            1'b0: out0 = data_in;
            1'b1: out1 = data_in;
        endcase
    end

endmodule