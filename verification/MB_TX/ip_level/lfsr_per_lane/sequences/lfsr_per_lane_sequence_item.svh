`ifndef LFSR_PER_LANE_SEQUENCE_ITEM_SVH
`define LFSR_PER_LANE_SEQUENCE_ITEM_SVH

class lfsr_per_lane_sequence_item extends uvm_sequence_item;
  `uvm_object_utils(lfsr_per_lane_sequence_item)

  // -------------------------------------------------------------------------
  //  Stimulus fields (directly driven to the DUT) - declared rand
  // -------------------------------------------------------------------------
  rand logic RST_n;
  rand logic [4:0] Opcode_Synch;
  rand logic EN;
  rand logic PN_EN;
  rand logic Data_In;
  // -------------------------------------------------------------------------
  //  Response fields (sampled from the DUT) - NOT rand
  // -------------------------------------------------------------------------
  logic Data_Out;
  logic [7:0] Valid;
  logic VLD_SER_EN;
  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "lfsr_per_lane_sequence_item");
    super.new(name);
  endfunction

  constraint RST_n_c {
    RST_n dist {0:=1, 1:=99};
  }

  constraint EN_c {
    EN dist {0:=35, 1:=65};
  }

  constraint PN_c {
    PN_EN dist {0:=65, 1:=35};
  }

  constraint Data_In_c {
    Data_In dist {0:=45, 1:=55};
  }

  constraint Opcode_Synch_c {
    soft Opcode_Synch == 5'b10101;
  }


  // -------------------------------------------------------------------------
  //  convert2string - human-readable representation for logs / debug
  // -------------------------------------------------------------------------
  virtual function string convert2string();
    return $sformatf("lfsr_per_lane_seq_item: RST_n=%0b Opcode_Synch=0x%0h EN=%0b PN_EN=%0b Data_In=%0b Data_Out=%0b Valid=0x%0h VLD_SER_EN=%0b",
      RST_n, Opcode_Synch, EN, PN_EN, Data_In, Data_Out, Valid, VLD_SER_EN);
  endfunction



virtual function void do_copy(uvm_object rhs);
  lfsr_per_lane_sequence_item rhs_item;

  super.do_copy(rhs);

  if (!$cast(rhs_item, rhs))
    `uvm_fatal("DO_COPY", "Type mismatch during sequence item copy")

  RST_n           = rhs_item.RST_n;
  Opcode_Synch    = rhs_item.Opcode_Synch;
  EN              = rhs_item.EN;
  PN_EN           = rhs_item.PN_EN;
  Data_In         = rhs_item.Data_In;
  Data_Out        = rhs_item.Data_Out;
  Valid           = rhs_item.Valid;
  VLD_SER_EN      = rhs_item.VLD_SER_EN;
  
endfunction

endclass

`endif // LFSR_PER_LANE_SEQUENCE_ITEM_SVH
