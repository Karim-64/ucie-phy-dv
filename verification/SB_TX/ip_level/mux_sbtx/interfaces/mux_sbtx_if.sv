interface mux_sbtx_if #(
  parameter INPUT_WIDTH = 5
) (input logic clk);
  wire logic [INPUT_WIDTH-1:0] IN_0;
  wire logic [INPUT_WIDTH-1:0] IN_1;
  wire logic Mux_Sel;

  wire logic [INPUT_WIDTH-1:0] OUT;

  clocking drv_cb @(posedge clk);
    // signals driven by the driver
    output IN_0;
    output IN_1;
    output Mux_Sel;
  endclocking

  clocking mon_cb @(posedge clk);
    // signals sampled by the monitor
    input OUT;
  endclocking
endinterface
