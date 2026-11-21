`ifndef LEVEL_SYNC_SBTX_RST_SEQUENCE_SVH
`define LEVEL_SYNC_SBTX_RST_SEQUENCE_SVH

class level_sync_sbtx_rst_sequence extends uvm_sequence #(level_sync_sbtx_sequence_item);
  `uvm_object_utils(level_sync_sbtx_rst_sequence)
  `uvm_declare_p_sequencer(level_sync_sbtx_sequencer)

  function new(string name = "level_sync_sbtx_rst_sequence");
    super.new(name);
  endfunction

  task body();
    level_sync_sbtx_sequence_item req;
    req = level_sync_sbtx_sequence_item::type_id::create("req");
    start_item(req);
    req.RST_n = 1'b0;
    req.Async_Signal = 1'b0;
    finish_item(req);
    p_sequencer.seqr_aport.write(req);
  endtask
endclass

`endif // LEVEL_SYNC_SBTX_RST_SEQUENCE_SVH
