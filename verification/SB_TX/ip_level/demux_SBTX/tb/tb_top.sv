`timescale 1ns/1ns
module tb_top();
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import demux_SBTX_pkg::*;

  bit clk;

  // Clock generator
  initial begin
    clk = 0;
    forever begin
      #1 clk = ~clk;
    end
  end

  // Interface instantiation
  demux_SBTX_if #(.DATA_WIDTH(DATA_WIDTH))
      demux_SBTX_if_inst (.clk(clk));

  // DUT instantiation
  demux_SBTX #(
    .DATA_WIDTH(DATA_WIDTH)
  ) dut (
    .din(demux_SBTX_if_inst.din),
    .sel(demux_SBTX_if_inst.sel),
    .dout0(demux_SBTX_if_inst.dout0),
    .dout1(demux_SBTX_if_inst.dout1),
    .dout2(demux_SBTX_if_inst.dout2),
    .dout3(demux_SBTX_if_inst.dout3)
  );

  // Config DB & test start
  initial begin
    uvm_config_db#(virtual demux_SBTX_if#(DATA_WIDTH))::set(
        null, "uvm_test_top", "DEMUX_SBTX_VIF", demux_SBTX_if_inst);
    run_test();
  end
endmodule
