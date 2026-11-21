`ifndef SYNC_FIFO_SBRX_SEQUENCE_ITEM_SVH
`define SYNC_FIFO_SBRX_SEQUENCE_ITEM_SVH

class Sync_fifo_SBRX_sequence_item extends uvm_sequence_item;
  `uvm_object_utils(Sync_fifo_SBRX_sequence_item)

  // -------------------------------------------------------------------------
  //  Stimulus fields (directly driven to the DUT) - declared rand
  // -------------------------------------------------------------------------
  rand logic sys_rst;
  rand logic wr_en;
  rand logic rd_en;
  rand logic [DATA_WIDTH:0] wr_data;
  // -------------------------------------------------------------------------
  //  Response fields (sampled from the DUT) - NOT rand
  // -------------------------------------------------------------------------
  logic [DATA_WIDTH:0] rd_data;
  logic full;
  logic empty;
  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "Sync_fifo_SBRX_sequence_item");
    super.new(name);
  endfunction

  // -------------------------------------------------------------------------
  //  convert2string - human-readable representation for logs / debug
  // -------------------------------------------------------------------------
  virtual function string convert2string();
    return $sformatf("Sync_fifo_SBRX_seq_item: sys_rst=%0b wr_en=%0b rd_en=%0b wr_data=0x%0h rd_data=0x%0h full=%0b empty=%0b",
      sys_rst, wr_en, rd_en, wr_data, rd_data, full, empty);
  endfunction

endclass

`endif // SYNC_FIFO_SBRX_SEQUENCE_ITEM_SVH
