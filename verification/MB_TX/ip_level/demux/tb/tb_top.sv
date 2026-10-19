`timescale 1ns/1ns
module tb_top();
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import demux_pkg::*;

  bit clk;

  // Clock generator
  initial begin
    clk = 0;
    forever begin
      #1 clk = ~clk;
    end
  end

  // Interface instantiation
  demux_if #()
      demux_if_inst (.clk(clk));

  // DUT instantiation
  DEMUX #(
  ) dut (
    .lp_data(demux_if_inst.lp_data),
    .SEL_4(demux_if_inst.SEL_4),
    .lp_data_0(demux_if_inst.lp_data_0),
    .lp_data_1(demux_if_inst.lp_data_1)
  );

  // Config DB & test start
  initial begin
    uvm_config_db#(virtual demux_if#())::set(
        null, "uvm_test_top", "DEMUX_VIF", demux_if_inst);
    run_test();
  end
endmodule
