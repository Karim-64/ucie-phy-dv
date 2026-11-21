`timescale 1ns/1ns
module tb_top();
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import Serializer_pkg::*;

  bit MB_CLK;

  // Clock generator
  initial begin
    MB_CLK = 0;
    forever begin
      #1 MB_CLK = ~MB_CLK;
    end
  end

  // Interface instantiation
  Serializer_if #()
      Serializer_if_inst (.MB_CLK(MB_CLK));

  // DUT instantiation
  Serializer #(
  ) dut (
    .MB_CLK(MB_CLK),
    .SER_EN(Serializer_if_inst.SER_EN),
    .DATA(Serializer_if_inst.DATA),
    .SER_OUT(Serializer_if_inst.SER_OUT)
  );

  bind Serializer Serializer_assertions Serializer_assertions_i (
    .MB_CLK(MB_CLK),
    .SER_EN(SER_EN),
    .DATA(DATA),
    .SER_OUT(SER_OUT)
  );

  // Config DB & test start
  initial begin
    uvm_config_db#(virtual Serializer_if#())::set(
        null, "uvm_test_top", "SERIALIZER_VIF", Serializer_if_inst);
    run_test("Serializer_base_test");
  end
endmodule
