`ifndef FIFO_RD_MBRX_BASE_SEQUENCE_SVH
`define FIFO_RD_MBRX_BASE_SEQUENCE_SVH

class fifo_rd_mbrx_base_sequence extends uvm_sequence #(fifo_rd_mbrx_sequence_item);
  `uvm_object_utils(fifo_rd_mbrx_base_sequence)
  `uvm_declare_p_sequencer(fifo_rd_mbrx_sequencer)

  function new(string name = "fifo_rd_mbrx_base_sequence");
    super.new(name);
  endfunction

  task body();
    // TODO: Implement sequence body
    // e.g. req = fifo_rd_mbrx_sequence_item::type_id::create("req");
    // start_item(req);
    // if (!req.randomize() with { ... }) `uvm_error("SEQ", "Randomization failed")
    // finish_item(req);
  endtask
endclass

`endif // FIFO_RD_MBRX_BASE_SEQUENCE_SVH
