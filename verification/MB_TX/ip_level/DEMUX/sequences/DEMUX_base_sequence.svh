`ifndef DEMUX_BASE_SEQUENCE_SVH
`define DEMUX_BASE_SEQUENCE_SVH

class DEMUX_base_sequence extends uvm_sequence #(DEMUX_sequence_item);
  `uvm_object_utils(DEMUX_base_sequence)
  `uvm_declare_p_sequencer(DEMUX_sequencer)

  int unsigned num_txns = 50;

  function new(string name = "DEMUX_base_sequence");
    super.new(name);
  endfunction

  task body();
    DEMUX_sequence_item req;
    for (int i = 0; i < num_txns; i++)
    begin
        req = DEMUX_sequence_item::type_id::create("req");
        start_item(req);
        assert (req.randomize()) else `uvm_fatal("SEQ", "Randomization failed")
        finish_item(req);
        p_sequencer.seqr_aport.write(req);
    end
  endtask
endclass

`endif // DEMUX_BASE_SEQUENCE_SVH
