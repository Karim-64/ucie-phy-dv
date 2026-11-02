interface Pattern_detector_SBRX_if #(
  parameter DATA_WIDTH = 64
) (input logic sb_clk);
  wire logic sb_sys_rst;
  wire logic [DATA_WIDTH-1:0] pattern_data_in;
  wire logic data_valid;

  wire logic pattern_detected;
  wire logic sb_o_detected;

  clocking drv_cb @(posedge sb_clk);
    // signals driven by the driver
    output sb_sys_rst;
    output pattern_data_in;
    output data_valid;
  endclocking

  clocking mon_cb @(posedge sb_clk);
    // signals sampled by the monitor
    input pattern_detected;
    input sb_o_detected;
  endclocking
endinterface
