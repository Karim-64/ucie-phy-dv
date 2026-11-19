`ifndef PE_SBTX_FIFO_SEQUENCE_ITEM_SVH
`define PE_SBTX_FIFO_SEQUENCE_ITEM_SVH

class pe_sbtx_FIFO_sequence_item extends uvm_sequence_item;
  `uvm_object_utils(pe_sbtx_FIFO_sequence_item)

  // Response fields (sampled from FIFO egress interface)
  logic                  fifo_wr;
  logic [DATA_WIDTH-1:0] fifo_data;
  logic                  data_marker;
  logic                  d2d_phy_marker;
  logic                  comp_marker;

  function new(string name = "pe_sbtx_FIFO_sequence_item");
    super.new(name);
  endfunction

  virtual function string convert2string();
    return $sformatf("pe_sbtx_FIFO_seq_item: fifo_wr=%0b fifo_data=0x%0h data_marker=%0b d2d_phy_marker=%0b comp_marker=%0b",
      fifo_wr, fifo_data, data_marker, d2d_phy_marker, comp_marker);
  endfunction
endclass

`endif // PE_SBTX_FIFO_SEQUENCE_ITEM_SVH
