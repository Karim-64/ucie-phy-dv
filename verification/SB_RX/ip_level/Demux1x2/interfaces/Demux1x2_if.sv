interface Demux1x2_if #(
  parameter DATA_WIDTH = 64
) (input logic CLK);
  wire logic [DATA_WIDTH-1:0] data_in;
  wire logic sel;

  wire logic [DATA_WIDTH-1:0] out0;
  wire logic [DATA_WIDTH-1:0] out1;

  clocking drv_cb @(posedge CLK);
    // signals driven by the driver
    output data_in;
    output sel;
  endclocking

  clocking mon_cb @(posedge CLK);
    // signals sampled by the monitor
    input out0;
    input out1;
  endclocking
endinterface
