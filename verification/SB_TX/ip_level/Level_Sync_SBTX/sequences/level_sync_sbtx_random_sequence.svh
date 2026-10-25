`ifndef LEVEL_SYNC_SBTX_RANDOM_SEQUENCE_SVH
`define LEVEL_SYNC_SBTX_RANDOM_SEQUENCE_SVH

class level_sync_sbtx_random_sequence extends uvm_sequence #(level_sync_sbtx_sequence_item);
  `uvm_object_utils(level_sync_sbtx_random_sequence)
  `uvm_declare_p_sequencer(level_sync_sbtx_sequencer)

  function new(string name = "level_sync_sbtx_random_sequence");
    super.new(name);
  endfunction

  task body();
    level_sync_sbtx_sequence_item req;
    repeat(500) begin
      req = level_sync_sbtx_sequence_item::type_id::create("req");
      start_item(req);
      assert(req.randomize());
      finish_item(req);
      p_sequencer.seqr_aport.write(req);
    end
  endtask
endclass

`endif // LEVEL_SYNC_SBTX_RANDOM_SEQUENCE_SVH
