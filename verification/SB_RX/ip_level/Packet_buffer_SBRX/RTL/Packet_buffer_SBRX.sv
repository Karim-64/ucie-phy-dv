module Packet_buffer_SBRX #(
    parameter DATA_WIDTH 	= 64,
    parameter DEPTH 		= 2
) (
    input                   	lclk 	, 	// Clock signal
    input                   	sys_rst , 	// Active-low reset
    input                   	wr_en 	, 	// Write enable signal
    input                   	rd_en 	, 	// Read enable signal
	input      [DATA_WIDTH:0] 	wr_data , 	// Data to be written 
    output reg [DATA_WIDTH:0] 	rd_data	, 	// Data read 
    output wire               	full 	, 	// full flag
    output wire              	empty 		// empty flag
);

    // Compute the required address width based on depth
    localparam ADDR_WIDTH = $clog2(DEPTH);

    // memory array
    reg [DATA_WIDTH:0] mem [DEPTH-1:0];
    
    // Read and Write pointers (extra bit for full/empty detection)
    reg [ADDR_WIDTH:0]   wr_ptr, rd_ptr;
	
	// Write Operation
	always @(posedge lclk or negedge sys_rst) begin
		if (~sys_rst) begin
			wr_ptr <= 0;
		end else if (wr_en && ~full) begin
			mem[wr_ptr[ADDR_WIDTH-1:0]] <= wr_data;
			wr_ptr 						<= wr_ptr + 1;
		end
	end
	
	// Read Operation
	always @(posedge lclk or negedge sys_rst) begin
		if (~sys_rst) begin
			rd_data <= 0;
			rd_ptr 	<= 0;
		end else if (rd_en && ~empty) begin
			rd_data <= mem[rd_ptr[ADDR_WIDTH-1:0]];
			rd_ptr 	<= rd_ptr + 1;
		end
	end
	
    // Full condition: Difference between write and read pointers reaches depth
	assign full = (wr_ptr - rd_ptr == DEPTH);
            
    // Empty condition: Write and read pointers are equal
    assign empty = (wr_ptr == rd_ptr);
	
endmodule
