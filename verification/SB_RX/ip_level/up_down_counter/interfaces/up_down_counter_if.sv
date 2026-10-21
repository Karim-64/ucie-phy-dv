interface up_down_counter_if #(
  parameter WIDTH = 5
) (input logic lclk);
  wire logic sys_rst;
  wire logic up;
  wire logic down;

  wire logic[WIDTH-1 : 0] count;

  clocking drv_cb @(posedge lclk);
    // signals driven by the driver
    output sys_rst;
    output up;
    output down;
  endclocking

  clocking mon_cb @(posedge lclk);
    // signals sampled by the monitor
    input count;
  endclocking
endinterface
