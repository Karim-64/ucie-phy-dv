`timescale 1ns/1ns
module tb_top();
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import gray_synchronizer_sbtx_pkg::*;

  bit CLK;

  // Clock generator
  initial begin
    CLK = 0;
    forever begin
      #1 CLK = ~CLK;
    end
  end

  // Interface instantiation
  gray_synchronizer_sbtx_if #(.DATA_SIZE(DATA_SIZE))
      gray_synchronizer_sbtx_if_inst (.CLK(CLK));

  // DUT instantiation
  Gray_Synchronizer_SBTX #(
    .DATA_SIZE(DATA_SIZE)
  ) dut (
    .CLK(CLK),
    .RST_n(gray_synchronizer_sbtx_if_inst.RST_n),
    .Async_Data(gray_synchronizer_sbtx_if_inst.Async_Data),
    .Sync_Data(gray_synchronizer_sbtx_if_inst.Sync_Data)
  );

  // Config DB & test start
  initial begin
    uvm_config_db#(virtual gray_synchronizer_sbtx_if#(DATA_SIZE))::set(
        null, "uvm_test_top", "GRAY_SYNCHRONIZER_SBTX_VIF", gray_synchronizer_sbtx_if_inst);
    run_test();
  end
endmodule
