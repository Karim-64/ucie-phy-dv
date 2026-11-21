`timescale 1ns/1ns
module tb_top();
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import Enable_Generator_MBRX_pkg::*;

  bit CLK;

  // Clock generator
  initial begin
    CLK = 0;
    forever begin
      #1 CLK = ~CLK;
    end
  end

  // Interface instantiation
  Enable_Generator_MBRX_if #(.NUM_LANES(NUM_LANES), .FRAME_LENGTH(FRAME_LENGTH))
      Enable_Generator_MBRX_if_inst (.CLK(CLK));

  // DUT instantiation
  Enable_Generator_MBRX #(
    .NUM_LANES(NUM_LANES),
    .FRAME_LENGTH(FRAME_LENGTH)
  ) dut (
    .CLK(CLK),
    .RST_n(Enable_Generator_MBRX_if_inst.RST_n),
    .LTSM_State(Enable_Generator_MBRX_if_inst.LTSM_State),
    .Width_Degrade(Enable_Generator_MBRX_if_inst.Width_Degrade),
    .Valid(Enable_Generator_MBRX_if_inst.Valid),
    .Comparison_Done(Enable_Generator_MBRX_if_inst.Comparison_Done),
    .Valid_Frame_Error(Enable_Generator_MBRX_if_inst.Valid_Frame_Error),
    .Detec_succ(Enable_Generator_MBRX_if_inst.Detec_succ),
    .Test_Resp(Enable_Generator_MBRX_if_inst.Test_Resp),
    .Vchk_EN(Enable_Generator_MBRX_if_inst.Vchk_EN),
    .Descr_EN(Enable_Generator_MBRX_if_inst.Descr_EN),
    .Deserializer_EN1(Enable_Generator_MBRX_if_inst.Deserializer_EN1),
    .Deserializer_EN2(Enable_Generator_MBRX_if_inst.Deserializer_EN2),
    .Data_Comparator_EN(Enable_Generator_MBRX_if_inst.Data_Comparator_EN),
    .Valid_Detected(Enable_Generator_MBRX_if_inst.Valid_Detected),
    .Comparison_Type(Enable_Generator_MBRX_if_inst.Comparison_Type),
    .LFSR_SEL(Enable_Generator_MBRX_if_inst.LFSR_SEL)
  );

  // Config DB & test start
  initial begin
    uvm_config_db#(virtual Enable_Generator_MBRX_if#(NUM_LANES, FRAME_LENGTH))::set(
        null, "uvm_test_top", "ENABLE_GENERATOR_MBRX_VIF", Enable_Generator_MBRX_if_inst);
    run_test("Enable_Generator_MBRX_base_test");
  end
endmodule
