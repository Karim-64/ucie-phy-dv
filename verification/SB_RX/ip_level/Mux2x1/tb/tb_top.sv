`timescale 1ns/1ns
module tb_top();
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import mux_sbrx_pkg::*;

  bit clk;

  // Clock generator
  initial begin
    clk = 0;
    forever begin
      #1 clk = ~clk;
    end
  end

  // Interface instantiation
  mux_sbrx_if #(.INPUT_WIDTH(INPUT_WIDTH))
      mux_sbrx_if_inst (.clk(clk));

  // DUT instantiation
  MUX_SBRX #(
    .INPUT_WIDTH(INPUT_WIDTH)
  ) dut (
    .in0(mux_sbrx_if_inst.in0),
    .in1(mux_sbrx_if_inst.in1),
    .sel(mux_sbrx_if_inst.sel),
    .out(mux_sbrx_if_inst.out)
  );

  // Config DB & test start
  initial begin
    uvm_config_db#(virtual mux_sbrx_if#(INPUT_WIDTH))::set(
        null, "uvm_test_top", "MUX_SBRX_VIF", mux_sbrx_if_inst);
    run_test();
  end
endmodule
