`ifndef LANES_MUX_SEQUENCE_ITEM_SVH
`define LANES_MUX_SEQUENCE_ITEM_SVH

class Lanes_MUX_sequence_item extends uvm_sequence_item;
  `uvm_object_utils(Lanes_MUX_sequence_item)

  // -------------------------------------------------------------------------
  //  Stimulus fields (directly driven to the DUT) - declared rand
  // -------------------------------------------------------------------------
  rand logic [7:0] IN_0 [15:0];
  rand logic [7:0] IN_1 [15:0];
  rand logic SEL_2;
  // -------------------------------------------------------------------------
  //  Response fields (sampled from the DUT) - NOT rand
  // -------------------------------------------------------------------------
  logic [7:0] OUT [15:0];
  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "Lanes_MUX_sequence_item");
    super.new(name);
  endfunction

  constraint c_sel {
    SEL_2 dist {0:=1, 1:=1};
  }


  constraint c_data_corners_max_min {
    foreach (IN_0[i]) {
     IN_0[i] dist { 8'h00:=10,
                    8'hFF:=10,
                    8'h01:=5,
                    8'hFE:=5,
                    8'h80:=5,
                    8'h7F:=5,
                    8'h55:=15,
                    8'hAA:=15,
                    [8'h00:8'hFF]:/1
                  };

     IN_1[i] dist { 8'h00:=10,
                    8'hFF:=10,
                    8'h01:=5,
                    8'hFE:=5,
                    8'h80:=5,
                    8'h7F:=5,
                    8'h55:=15,
                    8'hAA:=15,
                    [8'h00:8'hFF]:/1
                  };
    }
  }

  // -------------------------------------------------------------------------
  //  convert2string - human-readable representation for logs / debug
  // -------------------------------------------------------------------------
  virtual function string convert2string();
    return $sformatf("Lanes_MUX_seq_item: IN_0=0x%p IN_1=0x%p SEL_2=%0b OUT=0x%p",
      IN_0, IN_1, SEL_2, OUT);
  endfunction

endclass

`endif // LANES_MUX_SEQUENCE_ITEM_SVH
