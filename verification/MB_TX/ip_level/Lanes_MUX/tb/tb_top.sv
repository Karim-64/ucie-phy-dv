`timescale 1ns/1ns
module tb_top();
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import Lanes_MUX_pkg::*;

  bit CLK;

  // Clock generator
  initial begin
    CLK = 0;
    forever begin
      #1 CLK = ~CLK;
    end
  end

  // Interface instantiation
  Lanes_MUX_if #()
      Lanes_MUX_if_inst (.CLK(CLK));

  // DUT instantiation
  Lanes_MUX #(
  ) dut (
    .IN_0(Lanes_MUX_if_inst.IN_0),
    .IN_1(Lanes_MUX_if_inst.IN_1),
    .SEL_2(Lanes_MUX_if_inst.SEL_2),
    .OUT(Lanes_MUX_if_inst.OUT)
  );

  // Config DB & test start
  initial begin
    uvm_config_db#(virtual Lanes_MUX_if#())::set(
        null, "uvm_test_top", "LANES_MUX_VIF", Lanes_MUX_if_inst);
    run_test();
  end
endmodule
