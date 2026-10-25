`ifndef MUX_SBRX_SEQUENCE_ITEM_SVH
`define MUX_SBRX_SEQUENCE_ITEM_SVH

class mux_sbrx_sequence_item extends uvm_sequence_item;
  `uvm_object_utils(mux_sbrx_sequence_item)

  // -------------------------------------------------------------------------
  //  Stimulus fields (directly driven to the DUT) - declared rand
  // -------------------------------------------------------------------------
  rand logic [INPUT_WIDTH-1:0] in0;
  rand logic [INPUT_WIDTH-1:0] in1;
  rand logic sel;
  // -------------------------------------------------------------------------
  //  Response fields (sampled from the DUT) - NOT rand
  // -------------------------------------------------------------------------
  logic [INPUT_WIDTH-1:0] out;
  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "mux_sbrx_sequence_item");
    super.new(name);
  endfunction

  // -------------------------------------------------------------------------
  //  Constraints
  // -------------------------------------------------------------------------
  constraint c_sel_dist {
    sel dist {0 := 50, 1 := 50};
  }

  // Constraint 2: Weight corner cases (All 0s, All 1s, Alternating) higher than mid-range
  constraint c_data_corners {
    in0 dist {
      5'h00          := 15, // All zeros
      5'h1F          := 15, // All ones (5'b11111)
      5'h15, 5'h0A   := 15, // Alternating patterns (10101, 01010)
      [5'h01:5'h1E]  :/ 55  // Remaining values distributed evenly
    };

    in1 dist {
      5'h00          := 15,
      5'h1F          := 15,
      5'h15, 5'h0A   := 15,
      [5'h01:5'h1E]  :/ 55
    };
  }

  // Constraint 3: Soft constraint to keep in0 and in1 distinct by default
  constraint c_distinct_inputs {
    soft in0 != in1;
  }

  // -------------------------------------------------------------------------
  //  convert2string - human-readable representation for logs / debug
  // -------------------------------------------------------------------------
  virtual function string convert2string();
    return $sformatf("mux_sbrx_seq_item: in0=0x%0h in1=0x%0h sel=%0b out=0x%0h",
      in0, in1, sel, out);
  endfunction

endclass

`endif // MUX_SBRX_SEQUENCE_ITEM_SVH
