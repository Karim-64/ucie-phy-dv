module Async_FIFO #(
    parameter DATA_WIDTH = 64,   // Width of data in FIFO
    parameter FIFO_DEPTH = 4     // FIFO depth (must be power of 2)
)(
    input  wire                          lclk,           // Write clock
    input  wire                          lclk_RST,       // Active-low write domain (lclk) reset
    input  wire                          MB_CLK,         // Read clock
    input  wire                          rst_n,          // Active-low read domain (MB_CLK) reset
    input  wire                          lp_valid,       // from RDI Interface
    input  wire                          lp_irdy,        // from RDI Interface
    input  wire                          wr_en,          // from LTSM
    input  wire  [DATA_WIDTH-1:0] [7:0]  lp_data,        // Write data input
    input  wire                          RD_EN,          // Read enable
    output reg   [DATA_WIDTH-1:0] [7:0]  lp_data_Synch,  // Read data output (sequential)
    output wire                          FULL,           // FIFO full flag
    output wire                          EMPTY           // FIFO empty flag
);
    
    localparam ADDR_WIDTH = $clog2(FIFO_DEPTH);
    localparam PTR_WIDTH = ADDR_WIDTH + 1;  // for gray pointer

    integer i;
    reg [DATA_WIDTH-1:0] [7:0] FIFO_Mem [FIFO_DEPTH-1:0];

    reg [ADDR_WIDTH:0] wr_ptr_bin = 0, rd_ptr_bin = 0;
    reg [ADDR_WIDTH:0] wr_ptr_gray = 0, rd_ptr_gray = 0;

    reg [ADDR_WIDTH:0] wr_ptr_gray_sync1, wr_ptr_gray_sync2;
    reg [ADDR_WIDTH:0] rd_ptr_gray_sync1, rd_ptr_gray_sync2;
    wire [PTR_WIDTH-1:0] wr_ptr_bin_next;
    wire [PTR_WIDTH-1:0] rd_ptr_bin_next;

    wire WR_EN;
    assign WR_EN = lp_valid && lp_irdy && wr_en;

    assign wr_ptr_bin_next = (wr_ptr_bin + 1) & ((1 << PTR_WIDTH) - 1);
    assign rd_ptr_bin_next = (rd_ptr_bin + 1) & ((1 << PTR_WIDTH) - 1);


    // Write Process
    always @(posedge lclk or negedge lclk_RST) begin
        if (!lclk_RST) begin
            wr_ptr_bin <= 0;
            wr_ptr_gray <= 0;
            // Clear the FIFO memory
            for (i = 0; i < FIFO_DEPTH; i = i + 1) begin
               FIFO_Mem[i] <= '0;
            end
        end else if (WR_EN && !FULL) begin
            FIFO_Mem[wr_ptr_bin[ADDR_WIDTH-1:0]] <= lp_data;
            wr_ptr_bin  <= wr_ptr_bin_next;
            wr_ptr_gray <= wr_ptr_bin_next ^ (wr_ptr_bin_next >> 1);   // binary to gray
        end
    end


    // Read Process
    always @(posedge MB_CLK or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr_bin <= 0;
            rd_ptr_gray <= 0;
            lp_data_Synch <= 0;
        end else if (RD_EN && !EMPTY) begin
            lp_data_Synch <= FIFO_Mem[rd_ptr_bin[ADDR_WIDTH-1:0]];
            rd_ptr_bin <= rd_ptr_bin_next;
            rd_ptr_gray <= rd_ptr_bin_next ^ (rd_ptr_bin_next >> 1);  // binary to gray
        end
    end


    // Synchronize Read Pointer into Write Domain
    always @(posedge lclk or negedge lclk_RST) begin
        if (!lclk_RST) begin
            rd_ptr_gray_sync1 <= 0;
            rd_ptr_gray_sync2 <= 0;
        end else begin
            rd_ptr_gray_sync1 <= rd_ptr_gray;
            rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;
        end
    end


    // Synchronize Write Pointer into Read Domain
    always @(posedge MB_CLK or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr_gray_sync1 <= 0;
            wr_ptr_gray_sync2 <= 0;
        end else begin
            wr_ptr_gray_sync1 <= wr_ptr_gray;
            wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;
        end
    end


    // Full and Empty Logic (using synchronized pointers)
    assign FULL = ( (wr_ptr_gray[ADDR_WIDTH]   != rd_ptr_gray_sync2[ADDR_WIDTH]) &&
                    (wr_ptr_gray[ADDR_WIDTH-1] != rd_ptr_gray_sync2[ADDR_WIDTH-1]) &&
                    (wr_ptr_gray[ADDR_WIDTH-2:0] == rd_ptr_gray_sync2[ADDR_WIDTH-2:0]) );

    assign EMPTY = (rd_ptr_gray == wr_ptr_gray_sync2);


endmodule

