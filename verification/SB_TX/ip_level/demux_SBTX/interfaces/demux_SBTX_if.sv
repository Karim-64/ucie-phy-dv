interface demux_SBTX_if #(
  parameter DATA_WIDTH = 64
) (input logic clk);
  wire logic[DATA_WIDTH-1 : 0] din;
  wire logic[2-1 : 0] sel;

  wire logic[DATA_WIDTH-1 : 0] dout0;
  wire logic[DATA_WIDTH-1 : 0] dout1;
  wire logic[DATA_WIDTH-1 : 0] dout2;
  wire logic[DATA_WIDTH-1 : 0] dout3;

  clocking drv_cb @(posedge clk);
    // signals driven by the driver
    output din;
    output sel;
  endclocking

  clocking mon_cb @(posedge clk);
    // signals sampled by the monitor
    input dout0;
    input dout1;
    input dout2;
    input dout3;
  endclocking
endinterface
