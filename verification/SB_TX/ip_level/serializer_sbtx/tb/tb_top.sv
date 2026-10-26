`timescale 1ns/1ns
module tb_top();
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import serializer_sbtx_pkg::*;

  bit clk;

  // Clock generator
  initial begin
    clk = 0;
    forever begin
      #1 clk = ~clk;
    end
  end

  // Interface instantiation
  serializer_sbtx_if #(.DATA_WIDTH(DATA_WIDTH))
      serializer_sbtx_if_inst (.clk(clk));

  // DUT instantiation
  Serializer_64_SBTX #(
    .DATA_WIDTH(DATA_WIDTH)
  ) dut (
    .clk(clk),
    .rst_n(serializer_sbtx_if_inst.rst_n),
    .load(serializer_sbtx_if_inst.load),
    .Enable(serializer_sbtx_if_inst.Enable),
    .data_in(serializer_sbtx_if_inst.data_in),
    .data_out(serializer_sbtx_if_inst.data_out),
    .start_64(serializer_sbtx_if_inst.start_64)
  );

  // Config DB & test start
  initial begin
    uvm_config_db#(virtual serializer_sbtx_if#(DATA_WIDTH))::set(
        null, "uvm_test_top", "SERIALIZER_SBTX_VIF", serializer_sbtx_if_inst);
    run_test();
  end
endmodule
