interface Timer_SBTX_if #(
  parameter NO_OF_CYCLES = 32
) (input logic clk);
  wire logic rst_n;
  wire logic start;

  wire logic alarm;

  clocking drv_cb @(posedge clk);
    // signals driven by the driver
    output rst_n;
    output start;
  endclocking

  clocking mon_cb @(posedge clk);
    // signals sampled by the monitor
    input alarm;
  endclocking
endinterface
