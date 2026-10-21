interface wr_control_if #(
  parameter W_D_SIZE = 128,
  parameter WIDTH_DEGRADE_LENGTH = 3
) (input logic CLK);
  wire logic R_RST_n;
  wire logic [W_D_SIZE-1:0] Ip_Bytes;
  wire logic EN;
  wire logic Deser_Done;
  wire logic [WIDTH_DEGRADE_LENGTH-1:0] Width_Degrade;

  wire logic WR_EN;
  wire logic [W_D_SIZE-1:0] WR_DATA;

  clocking drv_cb @(posedge CLK);
    // signals driven by the driver
    output R_RST_n;
    output Ip_Bytes;
    output EN;
    output Deser_Done;
    output Width_Degrade;
  endclocking

  clocking mon_cb @(posedge CLK);
    // signals sampled by the monitor
    input WR_EN;
    input WR_DATA;
  endclocking
endinterface
