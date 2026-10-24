`timescale 1ns/1ns
module tb_top();
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import Synchronizer_SBRX_pkg::*;

  bit clk_dst;

  // Clock generator
  initial begin
    clk_dst = 0;
    forever begin
      #1 clk_dst = ~clk_dst;
    end
  end

  // Interface instantiation
  Synchronizer_SBRX_if #()
      Synchronizer_SBRX_if_inst (.clk_dst(clk_dst));

  // DUT instantiation
  Synchronizer_SBRX #(
  ) dut (
    .clk_dst(clk_dst),
    .rst_n(Synchronizer_SBRX_if_inst.rst_n),
    .signal_src(Synchronizer_SBRX_if_inst.signal_src),
    .signal_dst(Synchronizer_SBRX_if_inst.signal_dst)
  );

  bind Synchronizer_SBRX Synchronizer_SBRX_assertions synchronizer_assertions_i (
    .clk_dst(clk_dst),
    .rst_n(rst_n),
    .signal_src(signal_src),
    .signal_dst(signal_dst)
  );

  // Config DB & test start
  initial begin
    uvm_config_db#(virtual Synchronizer_SBRX_if#())::set(
        null, "uvm_test_top", "SYNCHRONIZER_SBRX_VIF", Synchronizer_SBRX_if_inst);
    run_test("Synchronizer_SBRX_base_test");
  end
endmodule
