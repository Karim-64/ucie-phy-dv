`ifndef DEMUX_SBTX_SEQUENCE_ITEM_SVH
`define DEMUX_SBTX_SEQUENCE_ITEM_SVH

class demux_SBTX_sequence_item extends uvm_sequence_item;
  `uvm_object_utils(demux_SBTX_sequence_item)

  // -------------------------------------------------------------------------
  //  Stimulus fields (directly driven to the DUT) - declared rand
  // -------------------------------------------------------------------------
  rand logic [DATA_WIDTH-1:0] din;
  rand logic [2-1:0] sel;
  // -------------------------------------------------------------------------
  //  Response fields (sampled from the DUT) - NOT rand
  // -------------------------------------------------------------------------
  logic [DATA_WIDTH-1:0] dout0;
  logic [DATA_WIDTH-1:0] dout1;
  logic [DATA_WIDTH-1:0] dout2;
  logic [DATA_WIDTH-1:0] dout3;
  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  typedef enum {DATA_RANDOM, DATA_CORNER, DATA_WALKING_ONE, DATA_NONZERO} data_mode_e;
  rand data_mode_e data_mode;

  function new(string name = "demux_SBTX_sequence_item");
    super.new(name);
  endfunction

  constraint c_sel_dist {
    sel dist {2'b00 := 25, 2'b01 := 25, 2'b10 := 25, 2'b11 := 25};
  }

  constraint c_mode_dist {
    data_mode dist {DATA_RANDOM := 70,
                    DATA_CORNER := 20};
  }

  constraint c_corner {
    (data_mode == DATA_CORNER) -> din inside {
      {DATA_WIDTH{1'b0}},
      {DATA_WIDTH{1'b1}},
      {(DATA_WIDTH/2){2'b01}},   // 0101...01
      {(DATA_WIDTH/2){2'b10}}    // 1010...10
    };
  }

  // -------------------------------------------------------------------------
  //  convert2string - human-readable representation for logs / debug
  // -------------------------------------------------------------------------
  virtual function string convert2string();
    return $sformatf("demux_SBTX_seq_item: din=0x%0h sel=0x%0h dout0=0x%0h dout1=0x%0h dout2=0x%0h dout3=0x%0h",
      din, sel, dout0, dout1, dout2, dout3);
  endfunction

endclass

`endif // DEMUX_SBTX_SEQUENCE_ITEM_SVH
