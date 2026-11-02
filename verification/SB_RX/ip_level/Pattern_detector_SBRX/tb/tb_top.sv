`timescale 1ns/1ns
module tb_top();
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import Pattern_detector_SBRX_pkg::*;

  bit sb_clk;

  // Clock generator
  initial begin
    sb_clk = 0;
    forever begin
      #1 sb_clk = ~sb_clk;
    end
  end

  // Interface instantiation
  Pattern_detector_SBRX_if #(.DATA_WIDTH(DATA_WIDTH))
      Pattern_detector_SBRX_if_inst (.sb_clk(sb_clk));

  // DUT instantiation
  Pattern_detector_SBRX #(
    .DATA_WIDTH(DATA_WIDTH)
  ) dut (
    .sb_clk(sb_clk),
    .sb_sys_rst(Pattern_detector_SBRX_if_inst.sb_sys_rst),
    .pattern_data_in(Pattern_detector_SBRX_if_inst.pattern_data_in),
    .data_valid(Pattern_detector_SBRX_if_inst.data_valid),
    .pattern_detected(Pattern_detector_SBRX_if_inst.pattern_detected),
    .sb_o_detected(Pattern_detector_SBRX_if_inst.sb_o_detected)
  );

  // Bind SVA module to DUT
  bind Pattern_detector_SBRX Pattern_detector_SBRX_sva #(
    .DATA_WIDTH(DATA_WIDTH)
  ) sva_inst (
    .sb_clk(sb_clk),
    .sb_sys_rst(sb_sys_rst),
    .pattern_data_in(pattern_data_in),
    .data_valid(data_valid),
    .pattern_detected(pattern_detected),
    .sb_o_detected(sb_o_detected)
  );

  // Config DB & test start
  initial begin
    uvm_config_db#(virtual Pattern_detector_SBRX_if#(DATA_WIDTH))::set(
        null, "uvm_test_top", "PATTERN_DETECTOR_SBRX_VIF", Pattern_detector_SBRX_if_inst);
    run_test("Pattern_detector_SBRX_base_test");
  end
endmodule
