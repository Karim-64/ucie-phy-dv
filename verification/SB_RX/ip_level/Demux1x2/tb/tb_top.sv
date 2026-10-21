`timescale 1ns/1ns
module tb_top();
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import Demux1x2_pkg::*;

  bit CLK;

  // Clock generator
  initial begin
    CLK = 0;
    forever begin
      #1 CLK = ~CLK;
    end
  end

  // Interface instantiation
  Demux1x2_if #(.DATA_WIDTH(DATA_WIDTH))
      Demux1x2_if_inst (.CLK(CLK));

  // DUT instantiation
  Demux1x2 #(
    .DATA_WIDTH(DATA_WIDTH)
  ) dut (
    .data_in(Demux1x2_if_inst.data_in),
    .sel(Demux1x2_if_inst.sel),
    .out0(Demux1x2_if_inst.out0),
    .out1(Demux1x2_if_inst.out1)
  );

  bind Demux1x2 Demux1x2_assertions #(
    .DATA_WIDTH(DATA_WIDTH)
  ) demux1x2_assertions_i (
    .clk(tb_top.CLK),
    .data_in(data_in),
    .sel(sel),
    .out0(out0),
    .out1(out1)
  );

  // Config DB & test start
  initial begin
    uvm_config_db#(virtual Demux1x2_if#(DATA_WIDTH))::set(
        null, "uvm_test_top", "DEMUX1X2_VIF", Demux1x2_if_inst);
    run_test("Demux1x2_base_test");
  end
endmodule
