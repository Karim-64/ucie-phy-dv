interface gray_synchronizer_sbtx_if #(
  parameter DATA_SIZE = 2
) (input logic CLK);
  wire logic RST_n;
  wire logic [1:0] Async_Data;

  wire logic [1:0] Sync_Data;

  clocking drv_cb @(posedge CLK);
    // signals driven by the driver
    output RST_n;
    output Async_Data;
  endclocking

  clocking mon_cb @(posedge CLK);
    // signals sampled by the monitor
    input Sync_Data;
  endclocking
endinterface
