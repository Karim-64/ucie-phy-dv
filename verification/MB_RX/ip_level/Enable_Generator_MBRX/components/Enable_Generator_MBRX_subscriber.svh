`ifndef ENABLE_GENERATOR_MBRX_SUBSCRIBER_SVH
`define ENABLE_GENERATOR_MBRX_SUBSCRIBER_SVH

class Enable_Generator_MBRX_subscriber extends uvm_subscriber #(Enable_Generator_MBRX_sequence_item);
  `uvm_component_utils(Enable_Generator_MBRX_subscriber)

  // Handle to the transaction currently being sampled.
  Enable_Generator_MBRX_sequence_item cov_tr;

  // Functional coverage of state-dependent enables, width modes, and events.
  covergroup Enable_Generator_MBRX_cg;


    cp_RST_n: coverpoint cov_tr.RST_n;
    cp_LTSM_State: coverpoint cov_tr.LTSM_State {
      bins reset = {_RESET};
      bins sbinit = {_SBINIT};
      bins mbinit_param = {_MBINIT_PARAM};
      bins mbinit_cal = {_MBINIT_CAL};
      bins mbinit_repairclk = {_MBINIT_REPAIRCLK};
      bins mbinit_repairval = {_MBINIT_REPAIRVAL};
      bins mbinit_reversalmb = {_MBINIT_REVERSALMB};
      bins mbinit_repairmb = {_MBINIT_REPAIRMB};
      bins mbtrain_valvref = {_MBTRAIN_VALVREF};
      bins mbtrain_datavref = {_MBTRAIN_DATAVREF};
      bins mbtrain_speedidle = {_MBTRAIN_SPEEDIDLE};
      bins mbtrain_txselfcal = {_MBTRAIN_TXSELFCAL};
      bins mbtrain_rxclkcal = {_MBTRAIN_RXCLKCAL};
      bins mbtrain_valtraincenter = {_MBTRAIN_VALTRAINCENTER};
      bins mbtrain_datatraincenter1 = {_MBTRAIN_DATATRAINCENTER1};
      bins mbtrain_datatrainvref = {_MBTRAIN_DATATRAINVREF};
      bins mbtrain_rxdeskew = {_MBTRAIN_RXDESKEW};
      bins mbtrain_datatraincenter2 = {_MBTRAIN_DATATRAINCENTER2};
      bins mbtrain_linkspeed = {_MBTRAIN_LINKSPEED};
      bins active = {_ACTIVE};
      ignore_bins unused_states = {
        _MBTRAIN_VALTRAINVREF,
        _MBTRAIN_REPAIR,
        _LINKINIT,
        _PHYRETRAIN,
        _TRAINERROR
      };
    }
    cp_Width_Degrade: coverpoint cov_tr.Width_Degrade {
      bins lower_half = {3'b001};
      bins upper_half = {3'b010};
      bins both_halves = {3'b011};
      bins illegal_widths = {3'b000, [3'b100:3'b111]};
    }
    cp_Valid: coverpoint cov_tr.Valid;
    cp_Comparison_Done: coverpoint cov_tr.Comparison_Done;
    cp_Valid_Frame_Error: coverpoint cov_tr.Valid_Frame_Error;
    cp_Detec_succ: coverpoint cov_tr.Detec_succ;
    cp_Test_Resp: coverpoint cov_tr.Test_Resp;
    cp_Vchk_EN: coverpoint cov_tr.Vchk_EN;
    cp_Descr_EN: coverpoint cov_tr.Descr_EN;
    cp_Deserializer_EN1: coverpoint cov_tr.Deserializer_EN1;
    cp_Deserializer_EN2: coverpoint cov_tr.Deserializer_EN2;
    cp_Data_Comparator_EN: coverpoint cov_tr.Data_Comparator_EN;
    cp_Valid_Detected: coverpoint cov_tr.Valid_Detected;
    cp_Comparison_Type: coverpoint cov_tr.Comparison_Type;
    cp_LFSR_SEL: coverpoint cov_tr.LFSR_SEL;


  endgroup : Enable_Generator_MBRX_cg

  function new(string name = "Enable_Generator_MBRX_subscriber", uvm_component parent = null);
    super.new(name, parent);
    Enable_Generator_MBRX_cg = new();
  endfunction : new

  function void write(Enable_Generator_MBRX_sequence_item t);
    if (t == null) begin
      `uvm_error("ENABLE_GENERATOR_MBRX_COV", "Received a null transaction")
      return;
    end
    cov_tr = t;
    Enable_Generator_MBRX_cg.sample();
  endfunction : write

endclass : Enable_Generator_MBRX_subscriber

`endif // ENABLE_GENERATOR_MBRX_SUBSCRIBER_SVH
