interface Lanes_MUX_if #(
) (input logic CLK);
  wire logic [7:0] IN_0 [15:0];
  wire logic [7:0] IN_1 [15:0];
  wire logic SEL_2;

  wire logic [7:0] OUT [15:0];

  clocking drv_cb @(posedge CLK);
    // signals driven by the driver
    output IN_0;
    output IN_1;
    output SEL_2;
  endclocking

  clocking mon_cb @(posedge CLK);
    // signals sampled by the monitor
    input OUT;
  endclocking
endinterface
