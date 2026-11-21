`ifndef SERIALIZER_SBTX_SEQUENCE_ITEM_SVH
`define SERIALIZER_SBTX_SEQUENCE_ITEM_SVH

class serializer_sbtx_sequence_item extends uvm_sequence_item;
  `uvm_object_utils(serializer_sbtx_sequence_item)

  // -------------------------------------------------------------------------
  //  Stimulus fields (directly driven to the DUT) - declared rand
  // -------------------------------------------------------------------------
  rand logic rst_n;
  rand logic load;
  rand logic Enable;
  rand logic [DATA_WIDTH-1:0] data_in;
  // -------------------------------------------------------------------------
  //  Response fields (sampled from the DUT) - NOT rand
  // -------------------------------------------------------------------------
  logic data_out;
  logic start_64;
  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "serializer_sbtx_sequence_item");
    super.new(name);
  endfunction

  // -------------------------------------------------------------------------
  //  convert2string - human-readable representation for logs / debug
  // -------------------------------------------------------------------------
  virtual function string convert2string();
    return $sformatf("serializer_sbtx_seq_item: rst_n=%0b load=%0b Enable=%0b data_in=0x%0h data_out=%0b start_64=%0b",
      rst_n, load, Enable, data_in, data_out, start_64);
  endfunction

endclass

`endif // SERIALIZER_SBTX_SEQUENCE_ITEM_SVH
