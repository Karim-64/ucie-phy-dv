`ifndef FIFO_RD_MBRX_SEQUENCE_ITEM_SVH
`define FIFO_RD_MBRX_SEQUENCE_ITEM_SVH

class fifo_rd_mbrx_sequence_item extends uvm_sequence_item;
  `uvm_object_utils(fifo_rd_mbrx_sequence_item)

  // -------------------------------------------------------------------------
  //  Stimulus fields (directly driven to the DUT) - declared rand
  // -------------------------------------------------------------------------
  rand logic r_rstn;
  rand logic r_inc;
  rand logic [P_SIZE-1:0] sync_wr_ptr;
  // -------------------------------------------------------------------------
  //  Response fields (sampled from the DUT) - NOT rand
  // -------------------------------------------------------------------------
  logic [2:0] rd_addr;
  logic empty;
  logic [P_SIZE-1:0] gray_rd_ptr;
  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "fifo_rd_mbrx_sequence_item");
    super.new(name);
  endfunction

  // -------------------------------------------------------------------------
  //  convert2string - human-readable representation for logs / debug
  // -------------------------------------------------------------------------
  virtual function string convert2string();
    return $sformatf("fifo_rd_mbrx_seq_item: r_rstn=%0b r_inc=%0b sync_wr_ptr=0x%0h rd_addr=0x%0h empty=%0b gray_rd_ptr=0x%0h",
      r_rstn, r_inc, sync_wr_ptr, rd_addr, empty, gray_rd_ptr);
  endfunction

endclass

`endif // FIFO_RD_MBRX_SEQUENCE_ITEM_SVH
