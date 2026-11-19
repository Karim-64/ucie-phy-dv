interface pe_sbtx_in_if #(
  parameter DATA_WIDTH = 64
) (
  input wire logic clk
);
  wire logic                  rst_n;
  wire logic                  en;
  wire logic                  data_marker;
  wire logic                  comp_marker;
  wire logic [DATA_WIDTH-1:0] data;
  wire logic                  resend_req;

  clocking drv_cb @(posedge clk);
    output rst_n; 
    output en;
    output data_marker;
    output comp_marker;
    output data;
  endclocking

  clocking mon_cb @(posedge clk);
    input  rst_n;
    input  en;
    input  data_marker;
    input  comp_marker;
    input  data;
    input  resend_req;
  endclocking
endinterface : pe_sbtx_in_if

