interface mem_if #(
  parameter DATA_WIDTH = 128,
  parameter ADDRESS_WIDTH = 4
) (input logic clk);
  wire logic rst;
  wire logic cs;
  wire logic we;
  wire logic[ADDRESS_WIDTH-1 : 0] addr;
  wire logic[DATA_WIDTH-1 : 0] data_in;

  wire logic[DATA_WIDTH-1 : 0] data_out;
  wire logic valid_out;

  clocking drv_cb @(posedge clk);
    // signals driven by the driver
    output rst;
    output cs;
    output we;
    output addr;
    output data_in;
  endclocking

  clocking mon_cb @(posedge clk);
    // signals sampled by the monitor
    input data_out;
    input valid_out;
  endclocking
endinterface
