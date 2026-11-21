`timescale 1ns/1ns
module tb_top();
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import pat_gen_sbtx_pkg::*;

  bit CLK;

  // Clock generator
  initial begin
    CLK = 0;
    forever begin
      #1 CLK = ~CLK;
    end
  end

  // Interface instantiation
  pat_gen_sbtx_if #()
      pat_gen_sbtx_if_inst (.CLK(CLK));

  // DUT instantiation
  Pattern_Generator_SBTX #(
  ) dut (
    .CLK(CLK),
    .RST_n(pat_gen_sbtx_if_inst.RST_n),
    .Patt_Gen_En(pat_gen_sbtx_if_inst.Patt_Gen_En),
    .start_64(pat_gen_sbtx_if_inst.start_64),
    .SBTX_DATA(pat_gen_sbtx_if_inst.SBTX_DATA)
  );

  // Config DB & test start
  initial begin
    uvm_config_db#(virtual pat_gen_sbtx_if#())::set(
        null, "uvm_test_top", "PAT_GEN_SBTX_VIF", pat_gen_sbtx_if_inst);
    run_test();
  end
endmodule
