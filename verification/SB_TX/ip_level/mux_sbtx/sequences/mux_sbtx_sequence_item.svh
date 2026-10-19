`ifndef MUX_SBTX_SEQUENCE_ITEM_SVH
`define MUX_SBTX_SEQUENCE_ITEM_SVH

class mux_sbtx_sequence_item extends uvm_sequence_item;
  `uvm_object_utils(mux_sbtx_sequence_item)

  // -------------------------------------------------------------------------
  //  Stimulus fields (directly driven to the DUT) - declared rand
  // -------------------------------------------------------------------------
  rand logic [INPUT_WIDTH-1:0] IN_0;
  rand logic [INPUT_WIDTH-1:0] IN_1;
  rand logic Mux_Sel;
  // -------------------------------------------------------------------------
  //  Response fields (sampled from the DUT) - NOT rand
  // -------------------------------------------------------------------------
  logic [INPUT_WIDTH-1:0] OUT;
  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "mux_sbtx_sequence_item");
    super.new(name);
  endfunction

  // -------------------------------------------------------------------------
  //  Constraints
  // -------------------------------------------------------------------------
  constraint c_sel_dist {
    Mux_Sel dist {0 := 50, 1 := 50};
  }

  // Constraint 2: Weight corner cases (All 0s, All 1s, Alternating) higher than mid-range
  constraint c_data_corners {
    IN_0 dist {
      5'h00          := 15, // All zeros
      5'h1F          := 15, // All ones (5'b11111)
      5'h15, 5'h0A   := 15, // Alternating patterns (10101, 01010)
      [5'h01:5'h1E]  :/ 55  // Remaining values distributed evenly
    };

    IN_1 dist {
      5'h00          := 15,
      5'h1F          := 15,
      5'h15, 5'h0A   := 15,
      [5'h01:5'h1E]  :/ 55
    };
  }

  // Constraint 3: Soft constraint to keep IN_0 and IN_1 distinct by default
  constraint c_distinct_inputs {
    soft IN_0 != IN_1;
  }

  // -------------------------------------------------------------------------
  //  convert2string - human-readable representation for logs / debug
  // -------------------------------------------------------------------------
  virtual function string convert2string();
    return $sformatf("mux_sbtx_seq_item: IN_0=0x%0h IN_1=0x%0h Mux_Sel=%0b OUT=0x%0h",
      IN_0, IN_1, Mux_Sel, OUT);
  endfunction

endclass

`endif // MUX_SBTX_SEQUENCE_ITEM_SVH
