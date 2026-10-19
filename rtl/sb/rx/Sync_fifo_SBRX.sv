module Sync_fifo_SBRX #(
    parameter DATA_WIDTH = 64,  // Width of each data entry in the FIFO
    parameter FIFO_DEPTH = 64  // Number of storage locations in the FIFO
) (
    input                   	lclk 	, 	// Clock signal
    input                   	sys_rst , 	// Active-low reset
    input                   	wr_en 	, 	// Write enable signal
    input                   	rd_en 	, 	// Read enable signal
	input      [DATA_WIDTH:0] 	wr_data	, 	// Data to be written into FIFO
    output reg [DATA_WIDTH:0] 	rd_data , 	// Data read from FIFO
    output wire               	full	, 	// FIFO full flag
    output wire              	empty 		// FIFO empty flag
);

    // Compute the required address width based on FIFO depth
    localparam ADDR_WIDTH = $clog2(FIFO_DEPTH);

    // FIFO memory array
    reg [DATA_WIDTH:0] mem [FIFO_DEPTH-1:0];
    
    // Read and Write pointers (extra bit for full/empty detection)
    reg [ADDR_WIDTH:0]   wr_ptr, rd_ptr;

    always @(posedge lclk or negedge sys_rst) begin
        if (~sys_rst) begin
            // Reset logic: Initialize pointers and status flags
            wr_ptr 	<= 0;
            rd_ptr 	<= 0;
			rd_data <= 0;
        end else begin
            // Write operation
            if (wr_en && ~full) begin
                mem[wr_ptr[ADDR_WIDTH-1:0]] <= wr_data; 	// Write data to FIFO
                wr_ptr 						<= wr_ptr + 1; 	// Increment write pointer
            end
            
            // Read operation
            if (rd_en && ~empty) begin
                rd_data <= mem[rd_ptr[ADDR_WIDTH-1:0]]; // Read data from FIFO
                rd_ptr  <= rd_ptr + 1; 					// Increment read pointer
            end
        end
    end
	
    // Full condition: Difference between write and read pointers reaches FIFO depth
	assign full = (wr_ptr - rd_ptr == FIFO_DEPTH);
            
    // Empty condition: Write and read pointers are equal
    assign empty = (wr_ptr == rd_ptr);
	
endmodule
