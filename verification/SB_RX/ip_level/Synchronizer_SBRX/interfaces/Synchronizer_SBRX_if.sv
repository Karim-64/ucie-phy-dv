interface Synchronizer_SBRX_if #(
) (input logic clk_dst);
  wire logic rst_n;
  wire logic signal_src;

  wire logic signal_dst;

  clocking drv_cb @(posedge clk_dst);
    // signals driven by the driver
    output rst_n;
    output signal_src;
  endclocking

  clocking mon_cb @(posedge clk_dst);
    // signals sampled by the monitor
    input signal_dst;
  endclocking
endinterface
