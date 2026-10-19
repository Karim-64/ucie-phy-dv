`ifndef DEMUX_SEQUENCE_ITEM_SVH
`define DEMUX_SEQUENCE_ITEM_SVH

class demux_sequence_item extends uvm_sequence_item;
  `uvm_object_utils(demux_sequence_item)

  typedef enum bit [2:0] {
  PAT_ZERO,
  PAT_ONES,
  PAT_ALT_AA,
  PAT_ALT_55,
  PAT_BYTE_ID,
  PAT_RANDOM
  } data_pattern_e;

  // -------------------------------------------------------------------------
  //  Stimulus fields (directly driven to the DUT) - declared rand
  // -------------------------------------------------------------------------
  rand logic [63:0][7:0] lp_data;
  rand logic SEL_4;
  // -------------------------------------------------------------------------
  //  Response fields (sampled from the DUT) - NOT rand
  // -------------------------------------------------------------------------
  logic [63:0][7:0] lp_data_0;
  logic [63:0][7:0] lp_data_1;

  // Helper knob for constraints and coverage
  rand data_pattern_e    pat_type;

  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "demux_sequence_item");
    super.new(name);
  endfunction

  // -------------------------------------------------------------------------
  //  Constraints
  // -------------------------------------------------------------------------

  // Solve order ensures pattern type dictates data generation
  constraint c_solve_order {
    solve pat_type before lp_data;
  }

  // Weight distribution for data patterns
  constraint c_pattern_dist {
    pat_type dist {
      PAT_ZERO    := 10,
      PAT_ONES    := 10,
      PAT_ALT_AA  := 10,
      PAT_ALT_55  := 10,
      PAT_BYTE_ID := 10,
      PAT_RANDOM  := 50
    };
  }

  // Data payload constraint across the 64 bytes
  constraint c_data_payload {
    foreach (lp_data[i]) {
      if (pat_type == PAT_ZERO)    lp_data[i] == 8'h00;
      if (pat_type == PAT_ONES)    lp_data[i] == 8'hFF;
      if (pat_type == PAT_ALT_AA)  lp_data[i] == 8'hAA;
      if (pat_type == PAT_ALT_55)  lp_data[i] == 8'h55;
      if (pat_type == PAT_BYTE_ID) lp_data[i] == i[7:0];
    }
  }

  // -------------------------------------------------------------------------
  //  convert2string - human-readable representation for logs / debug
  // -------------------------------------------------------------------------
  virtual function string convert2string();
    return $sformatf("demux_seq_item: lp_data=0x%0h SEL_4=%0b lp_data_0=0x%0h lp_data_1=0x%0h",
      lp_data, SEL_4, lp_data_0, lp_data_1);
  endfunction

endclass

`endif // DEMUX_SEQUENCE_ITEM_SVH
