module Deserializer_SBRX #(
    parameter DATA_WIDTH = 64 						// Generic parameter for data width (default is 64 bits)
)(
    input 						sb_clk			, 	// System clock for synchronization
    input 						sb_sys_rst		, 	// Active-low reset signal
    input 						RXCKSB			, 	// Clock signal for serial data (capture on negative edge)
    input 						RXDATASB		, 	// Serial data input
    output reg [DATA_WIDTH-1:0] deser_data_out	, 	// Parallel output data
    output reg 					data_valid 			// Data valid signal (asserted when DATA is valid)
);

    // Internal shift register to accumulate serial data
    reg [DATA_WIDTH-1:0] shift_reg;

    // Bit counter to track the number of bits received
    reg [$clog2(DATA_WIDTH)-1:0] bit_counter;

    // Signal to indicate that a full data has been assembled
    wire data_valid_pulse;
	reg  data_valid_sync1, data_valid_sync2;

    // Reset and initialization logic (synchronized to sb_clk)
    always @(posedge sb_clk or negedge sb_sys_rst) begin
        if (~sb_sys_rst) begin
            data_valid 			<= 1'b0;
			data_valid_sync1 	<= 1'b0;
            data_valid_sync2 	<= 1'b0;
        end else begin
            // Synchronize data_valid_pulse to sb_clk domain
            data_valid_sync1 	<= data_valid_pulse;
            data_valid_sync2 	<= data_valid_sync1;
            data_valid 			<= data_valid_sync2;
        end
    end

    // Serial data capture logic (synchronized to negative edge of RXCKSB)
    always @(negedge RXCKSB or negedge sb_sys_rst) begin
        if (!sb_sys_rst) begin
            shift_reg 		<= {DATA_WIDTH{1'b0}};
            bit_counter 	<= 0; 
			deser_data_out 	<= 0;
        end else begin
            // Shift in the new bit from RXDATASB
            shift_reg <= {RXDATASB, shift_reg[DATA_WIDTH-1:1]};

            // Increment the bit counter
            bit_counter <= bit_counter + 1;

            // Check if all bits have been received
            if (bit_counter == DATA_WIDTH - 1) begin
                // Assign the fully assembled data to the output
                deser_data_out 	<= {RXDATASB, shift_reg[DATA_WIDTH-1:1]};
                bit_counter 	<= 0; // Reset the bit counter for the next word
            end
        end
    end
	
	assign data_valid_pulse = (bit_counter == DATA_WIDTH - 1) ? 1'b1 : 1'b0;
endmodule