`timescale 1ns/1ns
module tb_top();
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import Data_MUX_pkg::*;

  bit clk;

  // Clock generator
  initial begin
    clk = 0;
    forever begin
      #1 clk = ~clk;
    end
  end

  // Interface instantiation
  Data_MUX_if #()
      Data_MUX_if_inst (.clk(clk));

  // DUT instantiation
  Data_MUX #(
  ) dut (
    .IN_0(Data_MUX_if_inst.IN_0),
    .IN_1(Data_MUX_if_inst.IN_1),
    .SEL_5(Data_MUX_if_inst.SEL_5),
    .OUT(Data_MUX_if_inst.OUT)
  );

  // Config DB & test start
  initial begin
    uvm_config_db#(virtual Data_MUX_if#())::set(
        null, "uvm_test_top", "DATA_MUX_VIF", Data_MUX_if_inst);
    run_test();
  end
endmodule
