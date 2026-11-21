`timescale 1ns/1ns
module tb_top();
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import wr_control_pkg::*;
  // import Universal_pkg::*;

  bit CLK;

  // Clock generator
  initial begin
    CLK = 0;
    forever begin
      #1 CLK = ~CLK;
    end
  end

  // Interface instantiation
  wr_control_if #(.W_D_SIZE(W_D_SIZE), .WIDTH_DEGRADE_LENGTH(WIDTH_DEGRADE_LENGTH))
      wr_control_if_inst (.CLK(CLK));

  // DUT instantiation
  WR_Control_MBRX #(
    .W_D_SIZE(W_D_SIZE),
    .WIDTH_DEGRADE_LENGTH(WIDTH_DEGRADE_LENGTH)
  ) dut (
    .CLK(CLK),
    .R_RST_n(wr_control_if_inst.R_RST_n),
    .Ip_Bytes(wr_control_if_inst.Ip_Bytes),
    .EN(wr_control_if_inst.EN),
    .Deser_Done(wr_control_if_inst.Deser_Done),
    .Width_Degrade(wr_control_if_inst.Width_Degrade),
    .Width_Degrade_Update(wr_control_if_inst.Width_Degrade_Update),
    .WR_EN(wr_control_if_inst.WR_EN),
    .WR_DATA(wr_control_if_inst.WR_DATA)
  );

  // Config DB & test start
  initial begin
    uvm_config_db#(virtual wr_control_if#(W_D_SIZE, WIDTH_DEGRADE_LENGTH))::set(
        null, "uvm_test_top", "WR_CONTROL_VIF", wr_control_if_inst);
    run_test();
  end
endmodule
