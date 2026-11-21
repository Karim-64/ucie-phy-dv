`ifndef BIT_SYNC_SBTX_SEQUENCE_ITEM_SVH
`define BIT_SYNC_SBTX_SEQUENCE_ITEM_SVH

class BIT_SYNC_SBTX_sequence_item extends uvm_sequence_item;
  `uvm_object_utils(BIT_SYNC_SBTX_sequence_item)

  typedef enum bit [2:0] { 
    PAT_ZERO,
    PAT_ALL_ONE,
    PAT_ALT_01,
    PAT_ALT_10, 
    PAT_RANDOM
  } data_pattern_e;

  rand data_pattern_e pat_type;

  // -------------------------------------------------------------------------
  //  Stimulus fields (directly driven to the DUT) - declared rand
  // -------------------------------------------------------------------------
  rand logic rst_n;
  rand logic [BUS_WIDTH-1:0] async;
  // -------------------------------------------------------------------------
  //  Response fields (sampled from the DUT) - NOT rand
  // -------------------------------------------------------------------------
  logic [BUS_WIDTH-1:0] sync;
  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "BIT_SYNC_SBTX_sequence_item");
    super.new(name);
  endfunction
  // -------------------------------------------------------------------------
  //  Constraints
  // -------------------------------------------------------------------------
    constraint c_rst {
        rst_n dist {0:=2, 1:=8};
    }

    constraint c_solve_order {
      solve pat_type before async;
    }
    
    constraint c_pattern_dist {
      pat_type dist {
        PAT_ZERO    := 10,
        PAT_ALL_ONE := 10,
        PAT_ALT_01  := 10,
        PAT_ALT_10  := 10,
        PAT_RANDOM  := 60
      };
    }

    constraint c_async {
      foreach (async[i]) {
        if (pat_type == PAT_ZERO)    async[i] == 1'b0;
        if (pat_type == PAT_ALL_ONE) async[i] == 1'b1;
        if (pat_type == PAT_ALT_01)  async[i] == i%2;
        if (pat_type == PAT_ALT_10)  async[i] == !(i%2);
      }
    }
  
  // -------------------------------------------------------------------------
  //  convert2string - human-readable representation for logs / debug
  // -------------------------------------------------------------------------
  virtual function string convert2string();
    return $sformatf("BIT_SYNC_SBTX_seq_item: rst_n=%0b async=0x%0h sync=0x%0h",
      rst_n, async, sync);
  endfunction

endclass

`endif // BIT_SYNC_SBTX_SEQUENCE_ITEM_SVH
