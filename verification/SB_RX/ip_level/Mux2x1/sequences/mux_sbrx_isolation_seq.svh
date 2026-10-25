`ifndef MUX_ISOLATION_SEQ_SVH
`define MUX_ISOLATION_SEQ_SVH

class mux_sbrx_isolation_seq extends uvm_sequence;
  `uvm_object_utils(mux_sbrx_isolation_seq)
  `uvm_declare_p_sequencer(mux_sbrx_sequencer)

  function new(string name = "mux_sbrx_isolation_seq");
    super.new(name);
  endfunction

  task body();
    mux_sbrx_sequence_item req;
    for (int i = 0; i < 40; i++) begin
      req = mux_sbrx_sequence_item::type_id::create("req");
      start_item(req);
      // Force in1 to be exact bitwise inverse of in0 while alternating sel
      assert (req.randomize() with {
        in1    == ~in0;
        sel == (i % 2);
      }); 
      finish_item(req);
      p_sequencer.seqr_aport.write(req);
    end
  endtask
endclass
`endif // MUX_ISOLATION_SEQ_SVH