`timescale 1ns/1ns
module tb_top();
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import Deserializer_SBRX_pkg::*;

  bit sb_clk;
  bit RXCKSB;

  // Clock1 generator
  initial begin
    sb_clk = 0;
    forever begin
      #1 sb_clk = ~sb_clk;
    end
  end

  // Clock1 generator
  initial begin
    RXCKSB = 0;
    forever begin
      #1 RXCKSB = ~RXCKSB;
    end
  end

  // Interface instantiation
  Deserializer_SBRX_if #(.DATA_WIDTH(DATA_WIDTH))
      Deserializer_SBRX_if_inst (.sb_clk(sb_clk), .RXCKSB(RXCKSB));

  // DUT instantiation
  Deserializer_SBRX #(
    .DATA_WIDTH(DATA_WIDTH)
  ) dut (
    .sb_clk(sb_clk),
    .RXCKSB(RXCKSB),
    .sb_sys_rst(Deserializer_SBRX_if_inst.sb_sys_rst),
    .RXDATASB(Deserializer_SBRX_if_inst.RXDATASB),
    .deser_data_out(Deserializer_SBRX_if_inst.deser_data_out),
    .data_valid(Deserializer_SBRX_if_inst.data_valid)
  );

  // Config DB & test start
  initial begin
    uvm_config_db#(virtual Deserializer_SBRX_if#(DATA_WIDTH))::set(
        null, "uvm_test_top", "DESERIALIZER_SBRX_VIF", Deserializer_SBRX_if_inst);
    run_test("Deserializer_SBRX_base_test");
  end
endmodule
