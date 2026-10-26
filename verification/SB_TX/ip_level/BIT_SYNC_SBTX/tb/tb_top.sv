`timescale 1ns/1ns
module tb_top();
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import BIT_SYNC_SBTX_pkg::*;

  bit clk;

  // Clock generator
  initial begin
    clk = 0;
    forever begin
      #1 clk = ~clk;
    end
  end

  // Interface instantiation
  BIT_SYNC_SBTX_if #(.NUM_STAGES(NUM_STAGES), .BUS_WIDTH(BUS_WIDTH))
      BIT_SYNC_SBTX_if_inst (.clk(clk));

  // DUT instantiation
  BIT_SYNC_SBTX #(
    .NUM_STAGES(NUM_STAGES),
    .BUS_WIDTH(BUS_WIDTH)
  ) dut (
    .CLK(clk),
    .RST(BIT_SYNC_SBTX_if_inst.rst_n),
    .ASYNC(BIT_SYNC_SBTX_if_inst.async),
    .SYNC(BIT_SYNC_SBTX_if_inst.sync)
  );

  // Config DB & test start
  initial begin
    uvm_config_db#(virtual BIT_SYNC_SBTX_if#(NUM_STAGES, BUS_WIDTH))::set(
        null, "uvm_test_top", "BIT_SYNC_SBTX_VIF", BIT_SYNC_SBTX_if_inst);
    run_test();
  end
endmodule
