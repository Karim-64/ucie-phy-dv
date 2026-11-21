`timescale 1ns/1ns
module tb_top();
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import Credits_Handler_SBTX_pkg::*;

  bit clk;

  // Clock generator
  initial begin
    clk = 0;
    forever begin
      #1 clk = ~clk;
    end
  end

  // Interface instantiation
  Credits_Handler_SBTX_if #(.CNT_WIDTH(CNT_WIDTH))
      Credits_Handler_SBTX_if_inst (.clk(clk));

  // DUT instantiation
  Credits_Handler_SBTX #(.CNT_WIDTH(CNT_WIDTH)
  ) dut (
    .CLK(clk),
    .RST_n(Credits_Handler_SBTX_if_inst.rst_n),
    .Comp_Sent(Credits_Handler_SBTX_if_inst.comp_sent),
    .UIE(Credits_Handler_SBTX_if_inst.UIE),
    .Credit(Credits_Handler_SBTX_if_inst.credit),
    .D2D_PHY_Marker(Credits_Handler_SBTX_if_inst.D2D_phy_marker),
    .Data_Marker(Credits_Handler_SBTX_if_inst.data_marker),
    .Comp_Marker(Credits_Handler_SBTX_if_inst.comp_marker),
    .pl_cfg_crd(Credits_Handler_SBTX_if_inst.pl_cfg_crd)
  );

  // Config DB & test start
  initial begin
    uvm_config_db#(virtual Credits_Handler_SBTX_if#())::set(
        null, "uvm_test_top", "CREDITS_HANDLER_SBTX_VIF", Credits_Handler_SBTX_if_inst);
    run_test();
  end
endmodule
