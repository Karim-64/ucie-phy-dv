`ifndef GRAY_SYNCHRONIZER_SBTX_SEQUENCE_ITEM_SVH
`define GRAY_SYNCHRONIZER_SBTX_SEQUENCE_ITEM_SVH

class gray_synchronizer_sbtx_sequence_item extends uvm_sequence_item;
  `uvm_object_utils(gray_synchronizer_sbtx_sequence_item)

  // -------------------------------------------------------------------------
  //  Stimulus fields (directly driven to the DUT) - declared rand
  // -------------------------------------------------------------------------
  rand logic RST_n;
  rand logic [1:0] Async_Data;
  // -------------------------------------------------------------------------
  //  Response fields (sampled from the DUT) - NOT rand
  // -------------------------------------------------------------------------
  logic [1:0] Sync_Data;
  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "gray_synchronizer_sbtx_sequence_item");
    super.new(name);
  endfunction

  virtual function void do_copy(uvm_object rhs);
  gray_synchronizer_sbtx_sequence_item rhs_item;

  super.do_copy(rhs);

  if (!$cast(rhs_item, rhs))
    `uvm_fatal("DO_COPY", "Type mismatch during sequence item copy")

  RST_n      = rhs_item.RST_n;
  Async_Data = rhs_item.Async_Data;
  Sync_Data  = rhs_item.Sync_Data;
endfunction


  constraint rst_n_c {
    RST_n dist {0:/10 , 1:/90};
  } 

  // -------------------------------------------------------------------------
  //  convert2string - human-readable representation for logs / debug
  // -------------------------------------------------------------------------
  virtual function string convert2string();
    return $sformatf("gray_synchronizer_sbtx_seq_item: RST_n=%0b Async_Data=0x%0h Sync_Data=0x%0h",
      RST_n, Async_Data, Sync_Data);
  endfunction

endclass

`endif // GRAY_SYNCHRONIZER_SBTX_SEQUENCE_ITEM_SVH
