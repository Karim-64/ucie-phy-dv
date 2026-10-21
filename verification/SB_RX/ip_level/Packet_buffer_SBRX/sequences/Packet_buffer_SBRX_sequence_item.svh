`ifndef PACKET_BUFFER_SBRX_SEQUENCE_ITEM_SVH
`define PACKET_BUFFER_SBRX_SEQUENCE_ITEM_SVH

class Packet_buffer_SBRX_sequence_item extends uvm_sequence_item;
  `uvm_object_utils(Packet_buffer_SBRX_sequence_item)

  // -------------------------------------------------------------------------
  //  Stimulus fields (directly driven to the DUT) - declared rand
  // -------------------------------------------------------------------------
  rand logic sys_rst;
  rand logic wr_en;
  rand logic rd_en;
  rand logic [DATA_WIDTH+1-1:0] wr_data;
  // -------------------------------------------------------------------------
  //  Response fields (sampled from the DUT) - NOT rand
  // -------------------------------------------------------------------------
  logic [DATA_WIDTH+1-1:0] rd_data;
  logic full;
  logic empty;
  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "Packet_buffer_SBRX_sequence_item");
    super.new(name);
  endfunction

  constraint c_rst { sys_rst dist {1 := 90, 0 := 10};}

  constraint c_balanced { 
    wr_en dist {0 := 50, 1 := 50};
    rd_en dist {0 := 50, 1 := 50};
  }
  
  constraint c_rd_heavy { 
    wr_en dist {0 := 75, 1 := 25};
    rd_en dist {0 := 25, 1 := 75};
  }

  constraint c_wr_heavy { 
    wr_en dist {0 := 25, 1 := 75};
    rd_en dist {0 := 75, 1 := 25};
  }

  constraint c_wr_data {
    wr_data[63:0] dist {
      {DATA_WIDTH{1'b1}}         := 5,
      {(DATA_WIDTH/2){2'b01}}    := 5,
      {(DATA_WIDTH/2){2'b10}}    := 5,
      [1 : {DATA_WIDTH{1'b1}}-1] :/ 85
    };
  }

  constraint c_wr_data_tag_bit {
    wr_data[64] dist {0 := 50, 1 := 50};
  }

  // -------------------------------------------------------------------------
  //  convert2string - human-readable representation for logs / debug
  // -------------------------------------------------------------------------
  virtual function string convert2string();
    return $sformatf("Packet_buffer_SBRX_seq_item: sys_rst=%0b wr_en=%0b rd_en=%0b wr_data=0x%0h rd_data=0x%0h full=%0b empty=%0b",
      sys_rst, wr_en, rd_en, wr_data, rd_data, full, empty);
  endfunction

endclass

`endif // PACKET_BUFFER_SBRX_SEQUENCE_ITEM_SVH
