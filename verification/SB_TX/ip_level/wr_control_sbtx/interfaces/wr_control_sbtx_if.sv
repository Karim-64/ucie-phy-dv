interface wr_control_sbtx_if #(
  parameter NC = 32
) (input logic CLK);
  wire logic RST_n;
  wire logic lp_cfg_vld;
  wire logic [NC-1:0] lp_cfg;

  wire logic [2*NC-1:0] Interface_Message;
  wire logic Data_Marker;
  wire logic Reg_Acc_Marker;
  wire logic Reg_Acc_Data_Marker;
  wire logic Comp_Marker;
  wire logic Req_Resp_Marker;
  wire logic Error_Handler;
  wire logic FIFO_WR;
  wire logic UIE;

  wire logic [2*NC-1:0] Interface_Message_exp;
  wire logic Data_Marker_exp;
  wire logic Reg_Acc_Marker_exp;
  wire logic Reg_Acc_Data_Marker_exp;
  wire logic Comp_Marker_exp;
  wire logic Req_Resp_Marker_exp;
  wire logic Error_Handler_exp;
  wire logic FIFO_WR_exp;
  wire logic UIE_exp;

  clocking drv_cb @(posedge CLK);
    // signals driven by the driver
    output RST_n;
    output lp_cfg_vld;
    output lp_cfg;
  endclocking

  clocking mon_cb @(posedge CLK);
    // signals sampled by the monitor
    input Interface_Message;
    input Data_Marker;
    input Reg_Acc_Marker;
    input Reg_Acc_Data_Marker;
    input Comp_Marker;
    input Req_Resp_Marker;
    input Error_Handler;
    input FIFO_WR;
    input UIE;
    
    input Interface_Message_exp;
    input Data_Marker_exp;
    input Reg_Acc_Marker_exp;
    input Reg_Acc_Data_Marker_exp;
    input Comp_Marker_exp;
    input Req_Resp_Marker_exp;
    input Error_Handler_exp;
    input FIFO_WR_exp;
    input UIE_exp;
  endclocking
endinterface
