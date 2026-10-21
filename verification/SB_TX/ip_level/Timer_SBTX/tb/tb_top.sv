`timescale 1ns/1ns
module tb_top();
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import Timer_SBTX_pkg::*;

  bit clk;

  // Clock generator
  initial begin
    clk = 0;
    forever begin
      #1 clk = ~clk;
    end
  end

  // Interface instantiation
  Timer_SBTX_if #(.NO_OF_CYCLES(NO_OF_CYCLES))
      Timer_SBTX_if_inst (.clk(clk));

  // DUT instantiation
  Timer_SBTX #(
    .NO_OF_CYCLES(NO_OF_CYCLES)
  ) dut (
    .clk(clk),
    .rst_n(Timer_SBTX_if_inst.rst_n),
    .start(Timer_SBTX_if_inst.start),
    .alarm(Timer_SBTX_if_inst.alarm)
  );

  // Config DB & test start
  initial begin
    uvm_config_db#(virtual Timer_SBTX_if#(NO_OF_CYCLES))::set(
        null, "uvm_test_top", "TIMER_SBTX_VIF", Timer_SBTX_if_inst);
    run_test("Timer_SBTX_base_test");
  end
endmodule
