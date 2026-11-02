`ifndef SERIALIZER_SEQUENCE_ITEM_SVH
`define SERIALIZER_SEQUENCE_ITEM_SVH

class Serializer_sequence_item extends uvm_sequence_item;
  `uvm_object_utils(Serializer_sequence_item)

  // -------------------------------------------------------------------------
  //  Stimulus fields (directly driven to the DUT) - declared rand
  // -------------------------------------------------------------------------
  rand logic SER_EN;
  rand logic [7:0] DATA;
  // -------------------------------------------------------------------------
  //  Response fields (sampled from the DUT) - NOT rand
  // -------------------------------------------------------------------------
  logic SER_OUT;
  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "Serializer_sequence_item");
    super.new(name);
  endfunction

  // constraints
  int counter;
  rand bit [7:0] ranomized_data;

  // force ser_en to be high for 8 consecutive cycles
  constraint active_c {
    if (counter == 8)
        SER_EN == 0;
    else
        SER_EN == 1;
  }




  // -------------------------------------------------------------------------
  //  convert2string - human-readable representation for logs / debug
  // -------------------------------------------------------------------------
  virtual function string convert2string();
    return $sformatf("Serializer_seq_item: SER_EN=%0b DATA=0x%0h SER_OUT=%0b",
      SER_EN, DATA, SER_OUT);
  endfunction

endclass

`endif // SERIALIZER_SEQUENCE_ITEM_SVH
