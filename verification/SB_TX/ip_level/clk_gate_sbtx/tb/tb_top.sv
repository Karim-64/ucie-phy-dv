`timescale 1ns/1ns
module tb_top();
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import clk_gate_sbtx_pkg::*;

  bit CLK;
  // Clock generator
  initial begin
    CLK = 0;
    forever begin
      #clk_gate_sbtx_pkg::PULSE_WIDTH CLK = ~CLK;
    end
  end

  // Interface instantiation
  clk_gate_sbtx_if #(PULSE_WIDTH)
      clk_gate_sbtx_if_inst (.CLK(CLK));

  // DUT instantiation
  Clk_Gate_SBTX #(
  ) dut (
    .CLK(CLK),
    .Enable(clk_gate_sbtx_if_inst.Enable),
    .Load(clk_gate_sbtx_if_inst.Load),
    .SBTX_CLK(clk_gate_sbtx_if_inst.SBTX_CLK)
  );

  bind dut clk_gate_sva#(clk_gate_sbtx_pkg::PULSE_WIDTH) clk_gate_sbtx_sva_inst (tb_top.clk_gate_sbtx_if_inst);

  // Config DB & test start
  initial begin
    uvm_config_db#(virtual clk_gate_sbtx_if#(PULSE_WIDTH))::set(
        null, "uvm_test_top", "CLK_GATE_SBTX_VIF", clk_gate_sbtx_if_inst);
    run_test();
  end
endmodule
