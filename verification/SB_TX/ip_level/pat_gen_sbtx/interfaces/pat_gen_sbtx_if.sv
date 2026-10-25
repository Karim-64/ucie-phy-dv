interface pat_gen_sbtx_if #(
) (input logic CLK);
  wire logic RST_n;
  wire logic Patt_Gen_En;

  wire logic start_64;
  wire logic SBTX_DATA;

  clocking drv_cb @(posedge CLK);
    // signals driven by the driver
    output RST_n;
    output Patt_Gen_En;
  endclocking

  clocking mon_cb @(posedge CLK);
    // signals sampled by the monitor
    input start_64;
    input SBTX_DATA;
  endclocking
endinterface
