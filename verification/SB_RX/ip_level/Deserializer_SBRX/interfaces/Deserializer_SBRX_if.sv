interface Deserializer_SBRX_if #(
  parameter DATA_WIDTH = 64
) (input logic sb_clk , input logic RXCKSB);
  wire logic sb_sys_rst;
  wire logic RXDATASB;

  wire logic [DATA_WIDTH-1:0] deser_data_out;
  wire logic data_valid;

  clocking drv_cb @(posedge sb_clk);
    // signals driven by the driver
    output sb_sys_rst;
  endclocking

  clocking mon_cb @(posedge sb_clk);
    // signals sampled by the monitor
    input sb_sys_rst;
    input deser_data_out;
    input data_valid;
  endclocking

  clocking drv_cb2 @(negedge RXCKSB);
    // signals driven by the driver
    output RXDATASB;
  endclocking

  clocking mon_cb2 @(negedge RXCKSB);
    // signals sampled by the monitor
    input RXDATASB;
  endclocking
endinterface
