`ifndef BIT_SYNC_SBTX_BASE_SEQUENCE_SVH
`define BIT_SYNC_SBTX_BASE_SEQUENCE_SVH

class BIT_SYNC_SBTX_base_sequence extends uvm_sequence #(BIT_SYNC_SBTX_sequence_item);
  `uvm_object_utils(BIT_SYNC_SBTX_base_sequence)
  `uvm_declare_p_sequencer(BIT_SYNC_SBTX_sequencer)

  BIT_SYNC_SBTX_sequence_item req;

  int num_txns = 50;

  function new(string name = "BIT_SYNC_SBTX_base_sequence");
    super.new(name);
  endfunction

  task body();
    req = BIT_SYNC_SBTX_sequence_item::type_id::create("req");
    start_item(req);
    assert(req.randomize() with {rst_n == 1'b0;}) else `uvm_error("SEQ", "Randomization failed")
    finish_item(req);
    p_sequencer.seqr_aport.write(req);
    
    repeat(num_txns) begin
      req = BIT_SYNC_SBTX_sequence_item::type_id::create("req");
      start_item(req);
      assert(req.randomize() with {rst_n == 1'b1;}) else `uvm_error("SEQ", "Randomization failed")
      finish_item(req);
      p_sequencer.seqr_aport.write(req);
    end

    repeat(5) begin
      req = BIT_SYNC_SBTX_sequence_item::type_id::create("req");
      start_item(req);
      assert(req.randomize()) else `uvm_error("SEQ", "Randomization failed")
      finish_item(req);
      p_sequencer.seqr_aport.write(req);
    end
  endtask
endclass

`endif // BIT_SYNC_SBTX_BASE_SEQUENCE_SVH
