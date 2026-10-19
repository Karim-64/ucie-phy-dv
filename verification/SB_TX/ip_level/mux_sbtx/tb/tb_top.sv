`timescale 1ns/1ns
module tb_top();
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import mux_sbtx_pkg::*;

  bit clk;

  // Clock generator
  initial begin
    clk = 0;
    forever begin
      #1 clk = ~clk;
    end
  end

  // Interface instantiation
  mux_sbtx_if #(.INPUT_WIDTH(INPUT_WIDTH))
      mux_sbtx_if_inst (.clk(clk));

  // DUT instantiation
  MUX_SBTX #(
    .INPUT_WIDTH(INPUT_WIDTH)
  ) dut (
    .IN_0(mux_sbtx_if_inst.IN_0),
    .IN_1(mux_sbtx_if_inst.IN_1),
    .Mux_Sel(mux_sbtx_if_inst.Mux_Sel),
    .OUT(mux_sbtx_if_inst.OUT)
  );

  // Config DB & test start
  initial begin
    uvm_config_db#(virtual mux_sbtx_if#(INPUT_WIDTH))::set(
        null, "uvm_test_top", "MUX_SBTX_VIF", mux_sbtx_if_inst);
    run_test();
  end
endmodule
