`ifndef DEMUX_RANDOM_SEQ_SVH
`define DEMUX_RANDOM_SEQ_SVH

class demux_random_seq extends uvm_sequence #(demux_sequence_item);
  `uvm_object_utils(demux_random_seq)
  `uvm_declare_p_sequencer(demux_sequencer)

  function new(string name = "demux_random_seq");
    super.new(name);
  endfunction

  task body();
    demux_sequence_item req;

    repeat (500) begin 
      req = demux_sequence_item::type_id::create("req");
      start_item(req);
      assert(req.randomize());
      finish_item(req);
      p_sequencer.seqr_aport.write(req);
    end
  endtask
endclass

`endif // DEMUX_RANDOM_SEQ_SVH
