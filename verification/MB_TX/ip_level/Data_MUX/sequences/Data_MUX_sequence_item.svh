`ifndef DATA_MUX_SEQUENCE_ITEM_SVH
`define DATA_MUX_SEQUENCE_ITEM_SVH

class Data_MUX_sequence_item extends uvm_sequence_item;
  `uvm_object_utils(Data_MUX_sequence_item)

  // -------------------------------------------------------------------------
  //  Stimulus fields (directly driven to the DUT) - declared rand
  // -------------------------------------------------------------------------
  rand logic [63:0][7:0] IN_0;
  rand logic [63:0][7:0] IN_1;
  rand logic SEL_5;
  // -------------------------------------------------------------------------
  //  Response fields (sampled from the DUT) - NOT rand
  // -------------------------------------------------------------------------
  logic [63:0][7:0] OUT;


  typedef enum bit [2:0] {
  PAT_ZERO,
  PAT_ONES,
  PAT_ALT_AA,
  PAT_ALT_55,
  PAT_BYTE_ID,
  PAT_RANDOM
  } data_pattern_e;
  // Helper knob for constraints and coverage
  rand data_pattern_e    pat_type;

  // -------------------------------------------------------------------------
  //  Constraints
  // -------------------------------------------------------------------------
  constraint c_sel_dist {
    SEL_5 dist {0 := 50, 1 := 50};
  }
  constraint c_solve_order {
    solve pat_type before IN_0, IN_1;
  }

  // Weight distribution for data patterns
  constraint c_pattern_dist {
    pat_type dist {
      PAT_ZERO    := 10,
      PAT_ONES    := 10,
      PAT_ALT_AA  := 10,
      PAT_ALT_55  := 10,
      PAT_BYTE_ID := 10,
      PAT_RANDOM  := 30
    };
  }

  // Data payload constraint across the 64 bytes
  constraint c_data_payload {
    foreach (IN_0[i]) {
      if (pat_type == PAT_ZERO)    IN_0[i] == 8'h00;
      if (pat_type == PAT_ONES)    IN_0[i] == 8'hFF;
      if (pat_type == PAT_ALT_AA)  IN_0[i] == 8'hAA;
      if (pat_type == PAT_ALT_55)  IN_0[i] == 8'h55;
      if (pat_type == PAT_BYTE_ID) IN_0[i] == i[7:0];
    }
    foreach (IN_1[i]) {
      if (pat_type == PAT_ZERO)    IN_1[i] == 8'h00;
      if (pat_type == PAT_ONES)    IN_1[i] == 8'hFF;
      if (pat_type == PAT_ALT_AA)  IN_1[i] == 8'hAA;
      if (pat_type == PAT_ALT_55)  IN_1[i] == 8'h55;
      if (pat_type == PAT_BYTE_ID) IN_1[i] == i[7:0];
    }
  }

  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "Data_MUX_sequence_item");
    super.new(name);
  endfunction

  // -------------------------------------------------------------------------
  //  convert2string - human-readable representation for logs / debug
  // -------------------------------------------------------------------------
  virtual function string convert2string();
    return $sformatf("Data_MUX_seq_item: IN_0=0x%0h IN_1=0x%0h SEL_5=%0b OUT=0x%0h",
      IN_0, IN_1, SEL_5, OUT);
  endfunction

endclass

`endif // DATA_MUX_SEQUENCE_ITEM_SVH
