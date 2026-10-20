`ifndef VLD_MUX_SEQUENCE_ITEM_SVH
`define VLD_MUX_SEQUENCE_ITEM_SVH

class VLD_MUX_sequence_item extends uvm_sequence_item;
  `uvm_object_utils(VLD_MUX_sequence_item)

  // -------------------------------------------------------------------------
  //  Stimulus fields (directly driven to the DUT) - declared rand
  // -------------------------------------------------------------------------
  rand logic [7:0] IN_0;
  rand logic [7:0] IN_1;
  rand logic [7:0] IN_2;
  rand logic [7:0] IN_3;
  rand logic [1:0] SEL_1;
  // -------------------------------------------------------------------------
  //  Response fields (sampled from the DUT) - NOT rand
  // -------------------------------------------------------------------------
  logic [7:0] OUT;
  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------

  typedef enum {DATA_RANDOM, DATA_CORNER, DATA_DISTINCT} data_mode_e;
  rand data_mode_e data_mode;

  constraint c_sel_dist {
    SEL_1 dist {2'b00 := 25, 2'b01 := 25, 2'b10 := 25, 2'b11 := 25};
  }

  constraint c_mode_dist {
    data_mode dist {DATA_RANDOM := 60, DATA_CORNER := 20, DATA_DISTINCT := 20};
  }

  constraint c_corner {
    (data_mode == DATA_CORNER) -> {
      IN_0 inside {8'h00, 8'hFF, 8'h55, 8'hAA};
      IN_1 inside {8'h00, 8'hFF, 8'h55, 8'hAA};
      IN_2 inside {8'h00, 8'hFF, 8'h55, 8'hAA};
      IN_3 inside {8'h00, 8'hFF, 8'h55, 8'hAA};
    }
  }

  constraint c_distinct {
    (data_mode == DATA_DISTINCT) -> {
      IN_0 != IN_1; IN_0 != IN_2; IN_0 != IN_3;
      IN_1 != IN_2; IN_1 != IN_3; IN_2 != IN_3;
    }
  }

  function new(string name = "VLD_MUX_sequence_item");
    super.new(name);
  endfunction

  // -------------------------------------------------------------------------
  //  convert2string - human-readable representation for logs / debug
  // -------------------------------------------------------------------------
  virtual function string convert2string();
    return $sformatf("VLD_MUX_seq_item: IN_0=0x%0h IN_1=0x%0h IN_2=0x%0h IN_3=0x%0h SEL_1=0x%0h OUT=0x%0h",
      IN_0, IN_1, IN_2, IN_3, SEL_1, OUT);
  endfunction

endclass

`endif // VLD_MUX_SEQUENCE_ITEM_SVH
