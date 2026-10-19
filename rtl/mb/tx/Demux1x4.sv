module Demux_1x4 #(
	parameter DATA_WIDTH 		= 64, 		// Width of input data
	parameter DESTINATION_SEL 	= 2
)(
    input 		[DATA_WIDTH:0] 			din	,       	// Single input
    input 		[DESTINATION_SEL-1:0] 	sel	, 			// 2-bit select signal
    output reg 	[DATA_WIDTH:0]			d0	,        	// Output 0
    output reg 	[DATA_WIDTH:0] 			d1	,        	// Output 1
    output reg 	[DATA_WIDTH:0]			d2	,        	// Output 2
    output reg	[DATA_WIDTH:0]			d3         		// Output 3
);

    always @(*) begin
		// Default all outputs to 0 
        d0 = 0;
        d1 = 0;
        d2 = 0;
        d3 = 0;
		
        // Route din to the selected output
        case (sel)
            2'b00: d0 = din;
            2'b01: d1 = din;
            2'b10: d2 = din;
            2'b11: d3 = din;
        endcase
    end

endmodule
