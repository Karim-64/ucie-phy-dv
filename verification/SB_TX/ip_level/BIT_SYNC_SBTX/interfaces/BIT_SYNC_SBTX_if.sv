interface BIT_SYNC_SBTX_if #(
  parameter NUM_STAGES = 2,
  parameter BUS_WIDTH = 1
) (input logic clk);
  wire logic rst_n;
  wire logic [BUS_WIDTH-1:0] async;

  wire logic [BUS_WIDTH-1:0] sync;

  clocking drv_cb @(posedge clk);
    // signals driven by the driver
    output rst_n;
    output async;
  endclocking

  clocking mon_cb @(posedge clk);
    // signals sampled by the monitor
    input sync;
  endclocking
endinterface
