interface fifo_rd_mbrx_if #(
  parameter P_SIZE = 4
) (input logic r_clk);
  wire logic r_rstn;
  wire logic r_inc;
  wire logic [P_SIZE-1:0] sync_wr_ptr;

  wire logic [2:0] rd_addr;
  wire logic empty;
  wire logic [P_SIZE-1:0] gray_rd_ptr;

  clocking drv_cb @(posedge r_clk);
    // signals driven by the driver
    output r_rstn;
    output r_inc;
    output sync_wr_ptr;
  endclocking

  clocking mon_cb @(posedge r_clk);
    // signals sampled by the monitor
    input rd_addr;
    input empty;
    input gray_rd_ptr;
  endclocking
endinterface
