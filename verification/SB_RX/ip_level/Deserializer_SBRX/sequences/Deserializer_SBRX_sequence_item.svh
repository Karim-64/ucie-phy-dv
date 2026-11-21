`ifndef DESERIALIZER_SBRX_SEQUENCE_ITEM_SVH
`define DESERIALIZER_SBRX_SEQUENCE_ITEM_SVH

class Deserializer_SBRX_sequence_item extends uvm_sequence_item;
  `uvm_object_utils(Deserializer_SBRX_sequence_item)

  // -------------------------------------------------------------------------
  //  Stimulus fields (directly driven to the DUT) - declared rand
  // -------------------------------------------------------------------------
  rand logic sb_sys_rst;
  rand logic RXDATASB;
  // -------------------------------------------------------------------------
  //  Response fields (sampled from the DUT) - NOT rand
  // -------------------------------------------------------------------------
  logic [DATA_WIDTH-1:0] deser_data_out;
  logic data_valid;
  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "Deserializer_SBRX_sequence_item");
    super.new(name);
  endfunction

  constraint burst_reset{
    sb_sys_rst dist {1'b0 := 70 , 1'b1 := 30};
  }

  // -------------------------------------------------------------------------
  //  convert2string - human-readable representation for logs / debug
  // -------------------------------------------------------------------------
  virtual function string convert2string();
    return $sformatf("Deserializer_SBRX_seq_item: sb_sys_rst=%0b RXDATASB=%0b deser_data_out=0x%0h data_valid=%0b",
      sb_sys_rst, RXDATASB, deser_data_out, data_valid);
  endfunction

endclass

`endif // DESERIALIZER_SBRX_SEQUENCE_ITEM_SVH
