interface level_sync_sbtx_if #(
) (input logic CLK);
  wire logic RST_n;
  wire logic Async_Signal;

  wire logic Sync_Signal;

  clocking drv_cb @(posedge CLK);
    // signals driven by the driver
    output RST_n;
    output Async_Signal;
  endclocking

  clocking mon_cb @(posedge CLK);
    // signals sampled by the monitor
    input Sync_Signal;
  endclocking
endinterface
