interface Data_MUX_if #(
) (input logic clk);
  wire logic [63:0][7:0] IN_0;
  wire logic [63:0][7:0] IN_1;
  wire logic SEL_5;

  wire logic [63:0][7:0] OUT;

  clocking drv_cb @(posedge clk);
    // signals driven by the driver
    output IN_0;
    output IN_1;
    output SEL_5;
  endclocking

  clocking mon_cb @(posedge clk);
    // signals sampled by the monitor
    input OUT;
  endclocking
endinterface
