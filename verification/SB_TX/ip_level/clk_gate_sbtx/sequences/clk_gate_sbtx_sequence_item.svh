`ifndef CLK_GATE_SBTX_SEQUENCE_ITEM_SVH
`define CLK_GATE_SBTX_SEQUENCE_ITEM_SVH

class clk_gate_sbtx_sequence_item extends uvm_sequence_item;
  `uvm_object_utils(clk_gate_sbtx_sequence_item)

  // -------------------------------------------------------------------------
  //  Stimulus fields (directly driven to the DUT) - declared rand
  // -------------------------------------------------------------------------
  logic CLK;
  rand logic Load;
  rand logic Enable;
  // -------------------------------------------------------------------------
  //  Response fields (sampled from the DUT) - NOT rand
  // -------------------------------------------------------------------------
  logic SBTX_CLK;
  rand time delay;
  constraint delay_c{
    delay< 2*PULSE_WIDTH;
  }

  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "clk_gate_sbtx_sequence_item");
    super.new(name);
  endfunction

  // -------------------------------------------------------------------------
  //  convert2string - human-readable representation for logs / debug
  // -------------------------------------------------------------------------
  virtual function string convert2string();
    return $sformatf("clk_gate_sbtx_seq_item: Load=%0b Enable=%0b SBTX_CLK=%0b",
      Load, Enable, SBTX_CLK);
  endfunction

endclass

`endif // CLK_GATE_SBTX_SEQUENCE_ITEM_SVH
