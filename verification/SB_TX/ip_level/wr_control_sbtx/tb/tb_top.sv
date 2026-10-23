`timescale 1ns/1ns
module tb_top();
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import wr_control_sbtx_pkg::*;

  bit CLK;

  // Clock generator
  initial begin
    CLK = 0;
    forever begin
      #1 CLK = ~CLK;
    end
  end

  // Interface instantiation
  wr_control_sbtx_if #(.NC(NC))
  wr_control_sbtx_if_inst (.CLK(CLK));
  

  // DUT instantiation
  WR_Control_SBTX #(
    .NC(NC)
  ) dut (
    .CLK(CLK),
    .RST_n(wr_control_sbtx_if_inst.RST_n),
    .lp_cfg_vld(wr_control_sbtx_if_inst.lp_cfg_vld),
    .lp_cfg(wr_control_sbtx_if_inst.lp_cfg),
    .Interface_Message(wr_control_sbtx_if_inst.Interface_Message),
    .Data_Marker(wr_control_sbtx_if_inst.Data_Marker),
    .Reg_Acc_Marker(wr_control_sbtx_if_inst.Reg_Acc_Marker),
    .Reg_Acc_Data_Marker(wr_control_sbtx_if_inst.Reg_Acc_Data_Marker),
    .Comp_Marker(wr_control_sbtx_if_inst.Comp_Marker),
    .Req_Resp_Marker(wr_control_sbtx_if_inst.Req_Resp_Marker),
    .Error_Handler(wr_control_sbtx_if_inst.Error_Handler),
    .FIFO_WR(wr_control_sbtx_if_inst.FIFO_WR),
    .UIE(wr_control_sbtx_if_inst.UIE)
  );

  bind dut wr_ctrl_sbtx_sva wr_ctrl_sbtx_sva_inst (tb_top.wr_control_sbtx_if_inst);

  WR_Control_SBTX_ref#(
    .NC(NC)
  ) gm (
    .CLK(CLK),
    .RST_n(wr_control_sbtx_if_inst.RST_n),
    .lp_cfg_vld(wr_control_sbtx_if_inst.lp_cfg_vld),
    .lp_cfg(wr_control_sbtx_if_inst.lp_cfg),
    .Interface_Message_exp(wr_control_sbtx_if_inst.Interface_Message_exp),
    .Data_Marker_exp(wr_control_sbtx_if_inst.Data_Marker_exp),
    .Reg_Acc_Marker_exp(wr_control_sbtx_if_inst.Reg_Acc_Marker_exp),
    .Reg_Acc_Data_Marker_exp(wr_control_sbtx_if_inst.Reg_Acc_Data_Marker_exp),
    .Comp_Marker_exp(wr_control_sbtx_if_inst.Comp_Marker_exp),
    .Req_Resp_Marker_exp(wr_control_sbtx_if_inst.Req_Resp_Marker_exp),
    .Error_Handler_exp(wr_control_sbtx_if_inst.Error_Handler_exp),
    .FIFO_WR_exp(wr_control_sbtx_if_inst.FIFO_WR_exp),
    .UIE_exp(wr_control_sbtx_if_inst.UIE_exp)
  );

  // Config DB & test start
  initial begin
    uvm_config_db#(virtual wr_control_sbtx_if#(NC))::set(
        null, "uvm_test_top", "WR_CONTROL_SBTX_VIF", wr_control_sbtx_if_inst);
    run_test();
  end
endmodule
