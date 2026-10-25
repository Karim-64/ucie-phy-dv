interface mux_sbrx_if #(
  parameter INPUT_WIDTH = 5
) (input logic clk);
  wire logic [INPUT_WIDTH-1:0] in0;
  wire logic [INPUT_WIDTH-1:0] in1;
  wire logic sel;

  wire logic [INPUT_WIDTH-1:0] out;

  clocking drv_cb @(posedge clk);
    // signals driven by the driver
    output in0;
    output in1;
    output sel;
  endclocking

  clocking mon_cb @(posedge clk);
    // signals sampled by the monitor
    input out;
  endclocking
endinterface
