`ifndef DMUX_1X4_SEQUENCE_ITEM_SVH
`define DMUX_1X4_SEQUENCE_ITEM_SVH

class DMUX_1x4_sequence_item extends uvm_sequence_item;
  `uvm_object_utils(DMUX_1x4_sequence_item)

  // -------------------------------------------------------------------------
  //  Stimulus fields (directly driven to the DUT) - declared rand
  // -------------------------------------------------------------------------
  rand logic [DATA_WIDTH-1:0] din;
  rand logic [DESTINATION_SEL-1:0] sel;
  // -------------------------------------------------------------------------
  //  Response fields (sampled from the DUT) - NOT rand
  // -------------------------------------------------------------------------
  logic [DATA_WIDTH-1:0] d0;
  logic [DATA_WIDTH-1:0] d1;
  logic [DATA_WIDTH-1:0] d2;
  logic [DATA_WIDTH-1:0] d3;
  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "DMUX_1x4_sequence_item");
    super.new(name);
  endfunction

  // Constraints
  constraint normal {
    sel inside {[0:(1 << DESTINATION_SEL)-1]};
    din inside {[0:(1 << DATA_WIDTH)-1]};
  }

  constraint consecutive_zeros {
    sel inside {[0:(1 << DESTINATION_SEL)-1]};
    din == {(DATA_WIDTH-1){1'b0}};
  }

  constraint consecutive_ones {
    sel inside {[0:(1 << DESTINATION_SEL)-1]};
    din == {(DATA_WIDTH-1){1'b1}};
  }

  constraint toogles {
    sel inside {2'b01, 2'b10};
    din inside {
        {((DATA_WIDTH+1)/2){2'b10}},
        {((DATA_WIDTH+1)/2){2'b01}}
    };
  }

  constraint walking_one {
    $countones(din) == 1;
  }

  constraint walking_zeros {
    $countones(din) == 0;
  }

  // -------------------------------------------------------------------------
  //  convert2string - human-readable representation for logs / debug
  // -------------------------------------------------------------------------
  virtual function string convert2string();
    return $sformatf("DMUX_1x4_seq_item: din=0x%0h sel=0x%0h d0=0x%0h d1=0x%0h d2=0x%0h d3=0x%0h",
      din, sel, d0, d1, d2, d3);
  endfunction

endclass

`endif // DMUX_1X4_SEQUENCE_ITEM_SVH
