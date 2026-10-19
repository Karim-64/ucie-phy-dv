interface demux_if #(
) (input logic clk);
  wire logic [63:0][7:0] lp_data;
  wire logic SEL_4;

  wire logic [63:0][7:0] lp_data_0;
  wire logic [63:0][7:0] lp_data_1;

  clocking drv_cb @(posedge clk);
    // signals driven by the driver
    output lp_data;
    output SEL_4;
  endclocking

  clocking mon_cb @(posedge clk);
    // signals sampled by the monitor
    input lp_data_0;
    input lp_data_1;
  endclocking
endinterface
