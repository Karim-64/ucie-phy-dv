interface pe_sbtx_if #(
  parameter DATA_WIDTH = 64
) (input logic CLK);
  wire logic RST_n;
  wire logic PHY_En;
  wire logic D2D_En;
  wire logic Data_Marker_D2D;
  wire logic Data_Marker_PHY;
  wire logic Comp_Marker_D2D;
  wire logic [DATA_WIDTH-1:0] PHY_Data;
  wire logic [DATA_WIDTH-1:0] D2D_Data;

  wire logic FIFO_WR;
  wire logic [DATA_WIDTH-1:0] FIFO_Data;
  wire logic Data_Marker;
  wire logic D2D_PHY_Marker;
  wire logic Comp_Marker;
  wire logic D2D_Resend_Req;
  wire logic PHY_Resend_Req;

  clocking drv_cb @(posedge CLK);
    // signals driven by the driver
    output RST_n;
    output PHY_En;
    output D2D_En;
    output Data_Marker_D2D;
    output Data_Marker_PHY;
    output Comp_Marker_D2D;
    output PHY_Data;
    output D2D_Data;
  endclocking

  clocking mon_cb @(posedge CLK);
    // signals sampled by the monitor
    input FIFO_WR;
    input FIFO_Data;
    input Data_Marker;
    input D2D_PHY_Marker;
    input Comp_Marker;
    input D2D_Resend_Req;
    input PHY_Resend_Req;
  endclocking
endinterface
