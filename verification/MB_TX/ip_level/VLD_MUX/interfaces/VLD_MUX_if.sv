interface VLD_MUX_if (input logic clk);
  wire logic[7:0] IN_0;
  wire logic[7:0] IN_1;
  wire logic[7:0] IN_2;
  wire logic[7:0] IN_3;
  wire logic[1:0] SEL_1;

  wire logic[7:0] OUT;

  clocking drv_cb @(posedge clk);
    // signals driven by the driver
    output IN_0;
    output IN_1;
    output IN_2;
    output IN_3;
    output SEL_1;
  endclocking

  clocking mon_cb @(posedge clk);
    // signals sampled by the monitor
    input OUT;
  endclocking
endinterface
