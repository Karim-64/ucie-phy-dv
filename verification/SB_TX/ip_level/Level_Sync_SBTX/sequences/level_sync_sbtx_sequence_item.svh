`ifndef LEVEL_SYNC_SBTX_SEQUENCE_ITEM_SVH
`define LEVEL_SYNC_SBTX_SEQUENCE_ITEM_SVH

class level_sync_sbtx_sequence_item extends uvm_sequence_item;
  `uvm_object_utils(level_sync_sbtx_sequence_item)

  // -------------------------------------------------------------------------
  //  Stimulus fields (directly driven to the DUT) - declared rand
  // -------------------------------------------------------------------------
  rand logic RST_n;
  rand logic Async_Signal;
  // -------------------------------------------------------------------------
  //  Response fields (sampled from the DUT) - NOT rand
  // -------------------------------------------------------------------------
  logic Sync_Signal;
  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  static logic last_sig = 1'b0;

  function new(string name = "level_sync_sbtx_sequence_item");
    super.new(name);
  endfunction

  constraint c_rst {
    soft RST_n dist { 1'b1 := 95, 1'b0 := 5 };
  }

  constraint c_hold {
    soft Async_Signal dist { last_sig := 70, ~last_sig := 30 };
  }

  function void post_randomize();
    last_sig = Async_Signal;
  endfunction

  // -------------------------------------------------------------------------
  //  convert2string - human-readable representation for logs / debug
  // -------------------------------------------------------------------------
  virtual function string convert2string();
    return $sformatf("level_sync_sbtx_seq_item: RST_n=%0b Async_Signal=%0b Sync_Signal=%0b",
      RST_n, Async_Signal, Sync_Signal);
  endfunction

endclass

`endif // LEVEL_SYNC_SBTX_SEQUENCE_ITEM_SVH
