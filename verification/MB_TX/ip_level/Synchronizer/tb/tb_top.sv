`timescale 1ns/1ns
module tb_top();
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import Synchronizer_pkg::*;

  bit clk_dst;

  // Clock generator
  initial begin
    clk_dst = 0;
    forever begin
      #1 clk_dst = ~clk_dst;
    end
  end

  // Interface instantiation
  Synchronizer_if #()
      Synchronizer_if_inst (.clk_dst(clk_dst));

  // DUT instantiation
  Synchronizer #(
  ) dut (
    .CLK(clk_dst),
    .RST(Synchronizer_if_inst.rst_n),
    .UnSynch_Input(Synchronizer_if_inst.signal_src),
    .Synch_Output(Synchronizer_if_inst.signal_dst)
  );

  // Config DB & test start
  initial begin
    uvm_config_db#(virtual Synchronizer_if#())::set(
        null, "uvm_test_top", "SYNCHRONIZER_VIF", Synchronizer_if_inst);
    run_test("Synchronizer_base_test");
  end
endmodule
