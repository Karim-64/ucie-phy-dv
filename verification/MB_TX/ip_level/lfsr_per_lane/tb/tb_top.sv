`timescale 1ns/1ns
module tb_top();
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import lfsr_per_lane_pkg::*;

  bit MB_CLK;

  // Clock generator
  initial begin
    MB_CLK = 0;
    forever begin
      #1 MB_CLK = ~MB_CLK;
    end
  end

  // Interface instantiation
  lfsr_per_lane_if #(.WIDTH(WIDTH), .Seed(Seed))
      lfsr_per_lane_if_inst (.MB_CLK(MB_CLK));

  // DUT instantiation
  LFSR_PerLane #(
    .WIDTH(WIDTH),
    .Seed(Seed)
  ) dut (
    .MB_CLK(MB_CLK),
    .RST_n(lfsr_per_lane_if_inst.RST_n),
    .Opcode_Synch(lfsr_per_lane_if_inst.Opcode_Synch),
    .EN(lfsr_per_lane_if_inst.EN),
    .PN_EN(lfsr_per_lane_if_inst.PN_EN),
    .Data_In(lfsr_per_lane_if_inst.Data_In),
    .Data_Out(lfsr_per_lane_if_inst.Data_Out),
    .Valid(lfsr_per_lane_if_inst.Valid),
    .VLD_SER_EN(lfsr_per_lane_if_inst.VLD_SER_EN)
  );

  // Config DB & test start
  initial begin
    uvm_config_db#(virtual lfsr_per_lane_if#(WIDTH, Seed))::set(
        null, "uvm_test_top", "LFSR_PER_LANE_VIF", lfsr_per_lane_if_inst);
    run_test();
  end
endmodule
