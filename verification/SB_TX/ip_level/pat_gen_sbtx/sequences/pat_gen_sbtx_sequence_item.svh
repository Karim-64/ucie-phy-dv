`ifndef PAT_GEN_SBTX_SEQUENCE_ITEM_SVH
`define PAT_GEN_SBTX_SEQUENCE_ITEM_SVH

class pat_gen_sbtx_sequence_item extends uvm_sequence_item;
  `uvm_object_utils(pat_gen_sbtx_sequence_item)

  // -------------------------------------------------------------------------
  //  Stimulus fields (directly driven to the DUT) - declared rand
  // -------------------------------------------------------------------------
  rand logic RST_n;
  rand logic Patt_Gen_En;
  // -------------------------------------------------------------------------
  //  Asynchronous reset fields
  // -------------------------------------------------------------------------
  bit async_reset;
  time async_reset_delay;
  time async_reset_duration;
  // -------------------------------------------------------------------------
  //  Response fields (sampled from the DUT) - NOT rand
  // -------------------------------------------------------------------------
  logic start_64;
  logic SBTX_DATA;
  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "pat_gen_sbtx_sequence_item");
    super.new(name);
  endfunction

  // -------------------------------------------------------------------------
  //  convert2string - human-readable representation for logs / debug
  // -------------------------------------------------------------------------
  virtual function string convert2string();
    return $sformatf("pat_gen_sbtx_seq_item: RST_n=%0b Patt_Gen_En=%0b start_64=%0b SBTX_DATA=%0b",
      RST_n, Patt_Gen_En, start_64, SBTX_DATA);
  endfunction

endclass

`endif // PAT_GEN_SBTX_SEQUENCE_ITEM_SVH
