`ifndef MUX_RAND_SEQ_SVH
`define MUX_RAND_SEQ_SVH

class mux_sbrx_rand_seq extends uvm_sequence;
  `uvm_object_utils(mux_sbrx_rand_seq)
  `uvm_declare_p_sequencer(mux_sbrx_sequencer)

  mux_sbrx_sequence_item req;
  int num_txns = 200;

  function new(string name = "mux_sbrx_rand_seq");
    super.new(name);
  endfunction

  task body();
    repeat (num_txns) begin
      req = mux_sbrx_sequence_item::type_id::create("req");
      start_item(req);
      assert(req.randomize());
      finish_item(req);
      p_sequencer.seqr_aport.write(req);
    end
  endtask
endclass

`endif // MUX_RAND_SEQ_SVH