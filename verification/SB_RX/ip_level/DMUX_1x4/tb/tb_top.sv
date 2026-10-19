`timescale 1ns/1ns
module tb_top();
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import DMUX_1x4_pkg::*;

  bit clk;

  // Clock generator
  initial begin
    clk = 0;
    forever begin
      #1 clk = ~clk;
    end
  end

  // Interface instantiation
  DMUX_1x4_if #(.DATA_WIDTH(DATA_WIDTH), .DESTINATION_SEL(DESTINATION_SEL))
      DMUX_1x4_if_inst (.clk(clk));

  // DUT instantiation
  Demux_1x4 #(
    .DATA_WIDTH(DATA_WIDTH),
    .DESTINATION_SEL(DESTINATION_SEL)
  ) dut (
    .din(DMUX_1x4_if_inst.din),
    .sel(DMUX_1x4_if_inst.sel),
    .d0(DMUX_1x4_if_inst.d0),
    .d1(DMUX_1x4_if_inst.d1),
    .d2(DMUX_1x4_if_inst.d2),
    .d3(DMUX_1x4_if_inst.d3)
  );

  // Config DB & test start
  initial begin
    uvm_config_db#(virtual DMUX_1x4_if#(DATA_WIDTH, DESTINATION_SEL))::set(
        null, "uvm_test_top", "DMUX_1X4_VIF", DMUX_1x4_if_inst);
    run_test("DMUX_1x4_base_test");
  end
endmodule
