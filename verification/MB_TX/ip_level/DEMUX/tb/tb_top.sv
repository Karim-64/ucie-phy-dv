`timescale 1ns/1ns
module tb_top();
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import DEMUX_pkg::*;

  bit clk;

  // Clock generator
  initial begin
    clk = 0;
    forever begin
      #1 clk = ~clk;
    end
  end

  // Interface instantiation
  DEMUX_if #()
      DEMUX_if_inst (.clk(clk));

  // DUT instantiation
  DEMUX #(
  ) dut (
    // .clk(clk),
    .lp_data(DEMUX_if_inst.lp_data),
    .SEL_4(DEMUX_if_inst.SEL_4),
    .lp_data_0(DEMUX_if_inst.lp_data_0),
    .lp_data_1(DEMUX_if_inst.lp_data_1)
  );

  // Config DB & test start
  initial begin
    uvm_config_db#(virtual DEMUX_if#())::set(
        null, "uvm_test_top", "DEMUX_VIF", DEMUX_if_inst);
    run_test();
  end
endmodule
