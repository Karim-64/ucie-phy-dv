`ifndef WR_CONTROL_SEQUENCE_ITEM_SVH
`define WR_CONTROL_SEQUENCE_ITEM_SVH

class wr_control_sequence_item extends uvm_sequence_item;
  `uvm_object_utils(wr_control_sequence_item)

  typedef enum bit [2:0] {
  ALL_ZERO,
  ALL_ONE,
  ALT_10,
  ALT_01,
  RANDOM_DATA
  } data_pattern_e;

  rand data_pattern_e pattern;

  // -------------------------------------------------------------------------
  //  Stimulus fields (directly driven to the DUT) - declared rand
  // -------------------------------------------------------------------------
  rand bit R_RST_n;
  rand bit [W_D_SIZE-1:0] Ip_Bytes;
  rand bit EN;
  rand bit Deser_Done;
  rand bit [WIDTH_DEGRADE_LENGTH-1:0] Width_Degrade;
  // -------------------------------------------------------------------------
  //  Response fields (sampled from the DUT) - NOT rand
  // -------------------------------------------------------------------------
  logic WR_EN;
  logic [W_D_SIZE-1:0] WR_DATA;
  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "wr_control_sequence_item");
    super.new(name);
  endfunction

  constraint pattern_dist_c {
    pattern dist {
      ALL_ZERO   := 15,
      ALL_ONE    := 15,
      ALT_10     := 15,
      ALT_01     := 15,
      RANDOM_DATA := 40
    };
  }

  constraint data_corners_c {
    if (pattern == ALL_ZERO)
      Ip_Bytes == '0;

    if (pattern == ALL_ONE)
      Ip_Bytes == '1;

    if (pattern == ALT_10)
      Ip_Bytes == {64{2'b10}};

    if (pattern == ALT_01)
      Ip_Bytes == {64{2'b01}};
  }

  constraint normal_flow_c {
    soft R_RST_n dist {1'b1 :/ 90, 1'b0 :/ 10};
    soft EN dist {1'b1 :/ 90, 1'b0 :/ 10};
    soft Deser_Done dist {1'b1 :/ 90, 1'b0 :/ 10};
    soft Width_Degrade inside {3'b001, 3'b010, 3'b011};
  }

  // -------------------------------------------------------------------------
  //  convert2string - human-readable representation for logs / debug
  // -------------------------------------------------------------------------
  virtual function string convert2string();
    return $sformatf("wr_control_seq_item: R_RST_n=%0b Ip_Bytes=0x%0h EN=%0b Deser_Done=%0b Width_Degrade=0x%0h WR_EN=%0b WR_DATA=0x%0h",
      R_RST_n, Ip_Bytes, EN, Deser_Done, Width_Degrade, WR_EN, WR_DATA);
  endfunction

endclass

`endif // WR_CONTROL_SEQUENCE_ITEM_SVH
