interface Packet_buffer_SBRX_if #(
  parameter DATA_WIDTH = 64,
  parameter DEPTH = 2
) (input logic lclk);
  wire logic sys_rst;
  wire logic wr_en;
  wire logic rd_en;
  wire logic[DATA_WIDTH+1-1 : 0] wr_data;

  wire logic[DATA_WIDTH+1-1 : 0] rd_data;
  wire logic full;
  wire logic empty;

  clocking drv_cb @(posedge lclk);
    // signals driven by the driver
    output sys_rst;
    output wr_en;
    output rd_en;
    output wr_data;
  endclocking

  clocking mon_cb @(posedge lclk);
    // signals sampled by the monitor
    input rd_data;
    input full;
    input empty;
  endclocking
endinterface
