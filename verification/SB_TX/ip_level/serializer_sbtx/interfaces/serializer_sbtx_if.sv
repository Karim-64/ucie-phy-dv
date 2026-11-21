interface serializer_sbtx_if #(
  parameter DATA_WIDTH = 64
) (input logic clk);
  wire logic rst_n;
  wire logic load;
  wire logic Enable;
  wire logic [DATA_WIDTH-1:0] data_in;

  wire logic data_out;
  wire logic start_64;

  clocking drv_cb @(posedge clk);
    // signals driven by the driver
    output rst_n;
    output load;
    output Enable;
    output data_in;
  endclocking

  clocking mon_cb @(posedge clk);
    // signals sampled by the monitor
    input data_out;
    input start_64;
  endclocking
endinterface
