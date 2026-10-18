module Asynch_fifo_SBRX #(
    parameter DATA_WIDTH = 64
)(
    input  wire                  sb_clk,            // Write clock
    input  wire                  lclk,              // Read clock
    input  wire                  sb_sys_rst,        // Active-low write reset
    input  wire                  sys_rst,           // Active-low read reset
    input  wire                  async_fifo_wr_en,  // Write enable
    input  wire [DATA_WIDTH-1:0] async_fifo_data_in,// Write data
    input  wire                  async_fifo_rd_en,  // Read enable
    output reg  [DATA_WIDTH-1:0] async_fifo_data_out,// Read data
    output wire                  async_fifo_full,   // FIFO full flag
    output wire                  async_fifo_empty   // FIFO empty flag
);

    // Only need 1-bit pointer for depth=2 (plus MSB for full/empty detection)
    reg [1:0] wr_ptr = 0;  // Write pointer (MSB for wrap-around)
    reg [1:0] rd_ptr = 0;  // Read pointer (MSB for wrap-around)
    
    // Double-flopped synchronizers
    reg [1:0] wr_ptr_sync_ff1 = 0;
    reg [1:0] wr_ptr_sync = 0;
    reg [1:0] rd_ptr_sync_ff1 = 0;
    reg [1:0] rd_ptr_sync = 0;
    
    // Memory
    reg [DATA_WIDTH-1:0] mem [0:1];
	
    // =========================================
    // Write Domain (sb_clk)
    // =========================================
    always @(posedge sb_clk or negedge sb_sys_rst) begin
        if (~sb_sys_rst) begin
            wr_ptr <= 0;
        end else if (async_fifo_wr_en && !async_fifo_full) begin
            mem[wr_ptr[0]] <= async_fifo_data_in;
            wr_ptr <= wr_ptr + 1;
        end
    end

    // =========================================
    // Read Domain (lclk)
    // =========================================
	always @(posedge lclk or negedge sys_rst) begin
		if (~sys_rst) begin
			rd_ptr <= 0;
			async_fifo_data_out <= 0;
		end else if (async_fifo_rd_en && !async_fifo_empty) begin
			rd_ptr <= rd_ptr + 1;
			async_fifo_data_out <= mem[rd_ptr[0]];
		end
	end
	
    // =========================================
    // Pointer Synchronization
    // =========================================
    // Sync write pointer to read domain
    always @(posedge lclk or negedge sys_rst) begin
        if (~sys_rst) begin
            wr_ptr_sync_ff1 <= 0;
            wr_ptr_sync <= 0;
        end else begin
            wr_ptr_sync_ff1 <= wr_ptr;
            wr_ptr_sync <= wr_ptr_sync_ff1;
        end
    end

    // Sync read pointer to write domain
    always @(posedge sb_clk or negedge sb_sys_rst) begin
        if (~sb_sys_rst) begin
            rd_ptr_sync_ff1 <= 0;
            rd_ptr_sync <= 0;
        end else begin
            rd_ptr_sync_ff1 <= rd_ptr;
            rd_ptr_sync <= rd_ptr_sync_ff1;
        end
    end

    // =========================================
    // Full/Empty Generation
    // =========================================
    assign async_fifo_full = (wr_ptr[1] != rd_ptr_sync[1]) && 
                           (wr_ptr[0] == rd_ptr_sync[0]);
    
    assign async_fifo_empty = (wr_ptr_sync == rd_ptr);
	
endmodule