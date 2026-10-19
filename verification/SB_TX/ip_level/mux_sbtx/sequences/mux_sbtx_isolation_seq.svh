`ifndef MUX_ISOLATION_SEQ_SVH
`define MUX_ISOLATION_SEQ_SVH

class mux_sbtx_isolation_seq extends uvm_sequence;
  `uvm_object_utils(mux_sbtx_isolation_seq)
  `uvm_declare_p_sequencer(mux_sbtx_sequencer)

  function new(string name = "mux_sbtx_isolation_seq");
    super.new(name);
  endfunction

  task body();
    mux_sbtx_sequence_item req;
    for (int i = 0; i < 40; i++) begin
      req = mux_sbtx_sequence_item::type_id::create("req");
      start_item(req);
      // Force IN_1 to be exact bitwise inverse of IN_0 while alternating Mux_Sel
      assert (req.randomize() with {
        IN_1    == ~IN_0;
        Mux_Sel == (i % 2);
      }); 
      finish_item(req);
      p_sequencer.seqr_aport.write(req);
    end
  endtask
endclass
`endif // MUX_ISOLATION_SEQ_SVH