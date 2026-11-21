`ifndef SYNCHRONIZER_SBRX_SEQUENCE_ITEM_SVH
`define SYNCHRONIZER_SBRX_SEQUENCE_ITEM_SVH

class Synchronizer_SBRX_sequence_item extends uvm_sequence_item;
  `uvm_object_utils(Synchronizer_SBRX_sequence_item)

  // -------------------------------------------------------------------------
  //  Stimulus fields (directly driven to the DUT) - declared rand
  // -------------------------------------------------------------------------
  rand logic rst_n;
  rand logic signal_src;
  // -------------------------------------------------------------------------
  //  Response fields (sampled from the DUT) - NOT rand
  // -------------------------------------------------------------------------
  logic signal_dst;
  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "Synchronizer_SBRX_sequence_item");
    super.new(name);
  endfunction

  // constraints
  bit fliped_bit;
  constraint rst_n_c
  {
    rst_n == 0;
    signal_src == 0;
  }

  constraint stream_0_c
  {
    rst_n == 1;
    signal_src == 0;
  }

  constraint stream_1_c
  {
    rst_n == 1;
    signal_src == 1;
  }

  constraint toggle_c
  {
    rst_n == 1;
    signal_src == fliped_bit;
  }

  constraint random_c
  {
    rst_n dist {0:=10,1:=90};
  }

  function void post_randomize();
      fliped_bit =  ~ signal_src;
  endfunction

  // -------------------------------------------------------------------------
  //  convert2string - human-readable representation for logs / debug
  // -------------------------------------------------------------------------
  virtual function string convert2string();
    return $sformatf("Synchronizer_SBRX_seq_item: rst_n=%0b signal_src=%0b signal_dst=%0b",
      rst_n, signal_src, signal_dst);
  endfunction

endclass

`endif // SYNCHRONIZER_SBRX_SEQUENCE_ITEM_SVH
