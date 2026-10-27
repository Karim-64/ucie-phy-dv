`ifndef ENABLE_GENERATOR_MBRX_SEQUENCE_ITEM_SVH
`define ENABLE_GENERATOR_MBRX_SEQUENCE_ITEM_SVH
import Universal_pkg::*;

class Enable_Generator_MBRX_sequence_item extends uvm_sequence_item;
  `uvm_object_utils(Enable_Generator_MBRX_sequence_item)
   
  // -------------------------------------------------------------------------
  //  Stimulus fields (directly driven to the DUT) - declared rand
  // -------------------------------------------------------------------------
  rand bit RST_n;
  rand LTSM_states LTSM_State;
  rand bit [WIDTH_DEGRADE_LENGTH-1:0] Width_Degrade;
  rand bit Valid;
  rand bit Comparison_Done;
  rand bit Valid_Frame_Error;
  rand bit Detec_succ;
  rand bit Test_Resp;
  // -------------------------------------------------------------------------
  //  Response fields (sampled from the DUT) - NOT rand
  // -------------------------------------------------------------------------
  bit Vchk_EN;
  bit Descr_EN;
  bit Deserializer_EN1;
  bit Deserializer_EN2;
  bit Data_Comparator_EN;
  bit Valid_Detected;
  bit Comparison_Type;
  bit LFSR_SEL;
  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "Enable_Generator_MBRX_sequence_item");
    super.new(name);
  endfunction

// constrints 
constraint reset_c 
{
    RST_n == 1;
    LTSM_State == _RESET;
    Valid == 0;
    Width_Degrade == 3'b000;
    Test_Resp == 0;
    Valid_Frame_Error == 0;
    Detec_succ == 0;
    Comparison_Done == 0;
}


constraint random_stress_c 
{
    RST_n dist {0:=5, 1:=95};

    LTSM_State inside {
        _RESET,
        _SBINIT,
        _MBINIT_PARAM,
        _MBINIT_CAL,
        _MBINIT_REPAIRCLK,
        _MBINIT_REPAIRVAL,
        _MBINIT_REVERSALMB,
        _MBINIT_REPAIRMB,
        _MBTRAIN_VALVREF,
        _MBTRAIN_DATAVREF,
        _MBTRAIN_SPEEDIDLE,
        _MBTRAIN_TXSELFCAL,
        _MBTRAIN_RXCLKCAL,
        _MBTRAIN_VALTRAINCENTER,
        _MBTRAIN_DATATRAINCENTER1,
        _MBTRAIN_DATATRAINVREF,
        _MBTRAIN_RXDESKEW,
        _MBTRAIN_DATATRAINCENTER2,
        _MBTRAIN_LINKSPEED,
        _ACTIVE
    };
    if(RST_n == 0) LTSM_State == _RESET;

    Width_Degrade inside {1, 2, 3};
}
  // -------------------------------------------------------------------------
  //  convert2string - human-readable representation for logs / debug
  // -------------------------------------------------------------------------
  virtual function string convert2string();
    return $sformatf("Enable_Generator_MBRX_seq_item: RST_n=%0b LTSM_State=0x%0h Width_Degrade=0x%0h Valid=%0b Comparison_Done=%0b Valid_Frame_Error=%0b Detec_succ=%0b Test_Resp=%0b Vchk_EN=%0b Descr_EN=%0b Deserializer_EN1=%0b Deserializer_EN2=%0b Data_Comparator_EN=%0b Valid_Detected=%0b Comparison_Type=%0b LFSR_SEL=%0b",
      RST_n, LTSM_State, Width_Degrade, Valid, Comparison_Done, Valid_Frame_Error, Detec_succ, Test_Resp, Vchk_EN, Descr_EN, Deserializer_EN1, Deserializer_EN2, Data_Comparator_EN, Valid_Detected, Comparison_Type, LFSR_SEL);
  endfunction

endclass

`endif // ENABLE_GENERATOR_MBRX_SEQUENCE_ITEM_SVH


