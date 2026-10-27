interface Enable_Generator_MBRX_if #(
  parameter NUM_LANES = 16,
  parameter FRAME_LENGTH = 8
) (input logic CLK);

import Universal_pkg::*;

  wire logic RST_n;
  LTSM_states LTSM_State;
  wire logic [WIDTH_DEGRADE_LENGTH-1:0] Width_Degrade;
  wire logic Valid;
  wire logic Comparison_Done;
  wire logic Valid_Frame_Error;
  wire logic Detec_succ;
  wire logic Test_Resp;

  wire logic Vchk_EN;
  wire logic Descr_EN;
  wire logic Deserializer_EN1;
  wire logic Deserializer_EN2;
  wire logic Data_Comparator_EN;
  wire logic Valid_Detected;
  wire logic Comparison_Type;
  wire logic LFSR_SEL;

  clocking drv_cb @(posedge CLK);
    // signals driven by the driver
    output RST_n;
    output LTSM_State;
    output Width_Degrade;
    output Valid;
    output Comparison_Done;
    output Valid_Frame_Error;
    output Detec_succ;
    output Test_Resp;
  endclocking

  clocking mon_cb @(posedge CLK);
    input RST_n;
    input LTSM_State;
    input Width_Degrade;
    input Valid;
    input Comparison_Done;
    input Valid_Frame_Error;
    input Detec_succ;
    input Test_Resp;
    // signals sampled by the monitor
    input Vchk_EN;
    input Descr_EN;
    input Deserializer_EN1;
    input Deserializer_EN2;
    input Data_Comparator_EN;
    input Valid_Detected;
    input Comparison_Type;
    input LFSR_SEL;
  endclocking
endinterface
