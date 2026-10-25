`timescale 1ns/1ns
module tb_top();
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import level_sync_sbtx_pkg::*;

  bit CLK;

  // Clock generator
  initial begin
    CLK = 0;
    forever begin
      #1 CLK = ~CLK;
    end
  end

  // Interface instantiation
  level_sync_sbtx_if #()
      level_sync_sbtx_if_inst (.CLK(CLK));

  // DUT instantiation
  Level_Sync_SBTX #(
  ) dut (
    .CLK(CLK),
    .RST_n(level_sync_sbtx_if_inst.RST_n),
    .Async_Signal(level_sync_sbtx_if_inst.Async_Signal),
    .Sync_Signal(level_sync_sbtx_if_inst.Sync_Signal)
  );

  // Config DB & test start
  initial begin
    uvm_config_db#(virtual level_sync_sbtx_if#())::set(
        null, "uvm_test_top", "LEVEL_SYNC_SBTX_VIF", level_sync_sbtx_if_inst);
    run_test();
  end
endmodule
