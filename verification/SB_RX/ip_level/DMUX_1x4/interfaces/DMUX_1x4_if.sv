interface DMUX_1x4_if #(
  parameter DATA_WIDTH = 64,
  parameter DESTINATION_SEL = 2
) (input logic clk);
  wire logic[DATA_WIDTH-1 : 0] din;
  wire logic[DESTINATION_SEL-1 : 0] sel;

  wire logic[DATA_WIDTH-1 : 0] d0;
  wire logic[DATA_WIDTH-1 : 0] d1;
  wire logic[DATA_WIDTH-1 : 0] d2;
  wire logic[DATA_WIDTH-1 : 0] d3;

  clocking drv_cb @(posedge clk);
    // signals driven by the driver
    output din;
    output sel;
  endclocking

  clocking mon_cb @(posedge clk);
    // signals sampled by the monitor
    input d0;
    input d1;
    input d2;
    input d3;
  endclocking
endinterface
