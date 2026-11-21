`ifndef DEMUX1X2_SEQUENCE_ITEM_SVH
`define DEMUX1X2_SEQUENCE_ITEM_SVH

class Demux1x2_sequence_item extends uvm_sequence_item;
  `uvm_object_utils(Demux1x2_sequence_item)

  // -------------------------------------------------------------------------
  //  Stimulus fields (directly driven to the DUT) - declared rand
  // -------------------------------------------------------------------------
  rand logic [DATA_WIDTH-1:0] data_in;
  rand logic sel;
  // -------------------------------------------------------------------------
  //  Response fields (sampled from the DUT) - NOT rand
  // -------------------------------------------------------------------------
  logic [DATA_WIDTH-1:0] out0;
  logic [DATA_WIDTH-1:0] out1;
  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "Demux1x2_sequence_item");
    super.new(name);
  endfunction

  // constraint
  constraint sel_c{
    sel dist {0:=50,1:=50};
  }
constraint c_data {
    data_in inside {
        [0 : 64'h5555_5555_5555_5555],
        [64'h5555_5555_5555_5555 : 64'hAAAA_AAAA_AAAA_AAAA],
        [64'hAAAA_AAAA_AAAA_AAAA : {DATA_WIDTH{1'b1}}]
    };
}
  // -------------------------------------------------------------------------
  //  convert2string - human-readable representation for logs / debug
  // -------------------------------------------------------------------------
  virtual function string convert2string();
    return $sformatf("Demux1x2_seq_item: data_in=0x%0h sel=%0b out0=0x%0h out1=0x%0h",
      data_in, sel, out0, out1);
  endfunction

endclass

`endif // DEMUX1X2_SEQUENCE_ITEM_SVH
