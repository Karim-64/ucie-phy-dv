interface Credits_Handler_SBTX_if #(CNT_WIDTH = 4
) (input logic clk);
  wire logic rst_n;
  wire logic comp_sent;
  wire logic UIE;
  wire logic credit;
  wire logic D2D_phy_marker;
  wire logic data_marker;
  wire logic comp_marker;

  wire logic pl_cfg_crd;

  clocking drv_cb @(posedge clk);
    // signals driven by the driver
    output rst_n;
    output comp_sent;
    output UIE;
    output credit;
    output D2D_phy_marker;
    output data_marker;
    output comp_marker;
  endclocking

  clocking mon_cb @(posedge clk);
    // signals sampled by the monitor
    input pl_cfg_crd;
  endclocking
endinterface
