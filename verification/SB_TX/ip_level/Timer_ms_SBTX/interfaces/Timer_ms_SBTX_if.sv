interface Timer_ms_SBTX_if #(
  parameter CLK_FREQ_HZ = 800_000_000,
  parameter FACTOR = 1000
) (input logic clk);
  wire logic rst_n;
  wire logic start;

  wire logic alarm;
  wire logic patt_alarm;

  clocking drv_cb @(posedge clk);
    // signals driven by the driver
    output rst_n;
    output start;
  endclocking

  clocking mon_cb @(posedge clk);
    // signals sampled by the monitor
    input alarm;
    input patt_alarm;
  endclocking
endinterface
