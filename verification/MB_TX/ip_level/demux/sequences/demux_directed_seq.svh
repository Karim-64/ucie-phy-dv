`ifndef DEMUX_DIRECTED_SEQ_SVH
`define DEMUX_DIRECTED_SEQ_SVH

class demux_directed_seq extends uvm_sequence #(demux_sequence_item);
  `uvm_object_utils(demux_directed_seq)
  `uvm_declare_p_sequencer(demux_sequencer)

  function new(string name = "demux_directed_seq");
    super.new(name);
  endfunction

  task body();
    demux_sequence_item req;

    req = demux_sequence_item::type_id::create("req");
    start_item(req);
    assert(req.randomize() with { SEL_4 == 1'b0; });
    finish_item(req);
    p_sequencer.seqr_aport.write(req);

    req = demux_sequence_item::type_id::create("req");
    start_item(req);
    assert(req.randomize() with { SEL_4 == 1'b1; });
    finish_item(req);
    p_sequencer.seqr_aport.write(req);
  endtask
endclass

`endif // DEMUX_DIRECTED_SEQ_SVH
