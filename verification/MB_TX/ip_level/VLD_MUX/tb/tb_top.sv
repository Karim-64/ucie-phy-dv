`timescale 1ns/1ns
module tb_top();
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import VLD_MUX_pkg::*;

  bit clk;

  // Clock generator
  initial begin
    clk = 0;
    forever begin
      #1 clk = ~clk;
    end
  end

  // Interface instantiation
  VLD_MUX_if VLD_MUX_if_inst (.clk(clk));

  // DUT instantiation
  VLD_MUX dut (
    .IN_0(VLD_MUX_if_inst.IN_0),
    .IN_1(VLD_MUX_if_inst.IN_1),
    .IN_2(VLD_MUX_if_inst.IN_2),
    .IN_3(VLD_MUX_if_inst.IN_3),
    .SEL_1(VLD_MUX_if_inst.SEL_1),
    .OUT(VLD_MUX_if_inst.OUT)
  );

  // Config DB & test start
  initial begin
    uvm_config_db#(virtual VLD_MUX_if#())::set(
        null, "uvm_test_top", "VLD_MUX_VIF", VLD_MUX_if_inst);
    run_test();
  end
endmodule
