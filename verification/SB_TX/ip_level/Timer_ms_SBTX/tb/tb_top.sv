`timescale 1ns/1ns
module tb_top();
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import Timer_ms_SBTX_pkg::*;

  bit clk;

  // Clock generator
  initial begin
    clk = 0;
    forever begin
      #1 clk = ~clk;
    end
  end

  // Interface instantiation
  Timer_ms_SBTX_if #(.CLK_FREQ_HZ(CLK_FREQ_HZ), .FACTOR(FACTOR))
      Timer_ms_SBTX_if_inst (.clk(clk));

  // DUT instantiation
  Timer_ms_SBTX #(
    .CLK_FREQ_HZ(CLK_FREQ_HZ),
    .FACTOR(FACTOR)
  ) dut (
    .clk(clk),
    .rst_n(Timer_ms_SBTX_if_inst.rst_n),
    .start(Timer_ms_SBTX_if_inst.start),
    .alarm(Timer_ms_SBTX_if_inst.alarm),
    .patt_alarm(Timer_ms_SBTX_if_inst.patt_alarm)
  );

  // Config DB & test start
  initial begin
    uvm_config_db#(virtual Timer_ms_SBTX_if#(CLK_FREQ_HZ, FACTOR))::set(
        null, "uvm_test_top", "TIMER_MS_SBTX_VIF", Timer_ms_SBTX_if_inst);
    run_test();
  end
endmodule
