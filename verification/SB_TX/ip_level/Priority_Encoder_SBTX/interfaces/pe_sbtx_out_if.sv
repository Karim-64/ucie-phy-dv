interface pe_sbtx_out_if #(
  parameter DATA_WIDTH = 64
) (
  input wire logic clk
);
  wire logic                  fifo_wr;
  wire logic [DATA_WIDTH-1:0] fifo_data;
  wire logic                  data_marker;
  wire logic                  d2d_phy_marker;
  wire logic                  comp_marker;

  clocking mon_cb @(posedge clk);
    input fifo_wr;
    input fifo_data;
    input data_marker;
    input d2d_phy_marker;
    input comp_marker;
  endclocking
endinterface : pe_sbtx_out_if

