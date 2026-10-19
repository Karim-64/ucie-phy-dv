`ifndef MUX_CORNER_SEQ_SVH
`define MUX_CORNER_SEQ_SVH

class mux_sbtx_corner_seq extends uvm_sequence;
  `uvm_object_utils(mux_sbtx_corner_seq)
  `uvm_declare_p_sequencer(mux_sbtx_sequencer)

  logic [INPUT_WIDTH-1:0] corners[] = '{5'h00, 5'h1F, 5'h15, 5'h0A};

  function new(string name = "mux_sbtx_corner_seq");
    super.new(name);
  endfunction

  task body();
    mux_sbtx_sequence_item req;
    foreach (corners[i]) begin
      foreach (corners[j]) begin
        for (int sel = 0; sel <= 1; sel++) begin
          req = mux_sbtx_sequence_item::type_id::create("req");
          start_item(req);
          assert(req.randomize() with {
            IN_0    == corners[i];
            IN_1    == corners[j];
            Mux_Sel == sel[0];
          });
          finish_item(req);
          p_sequencer.seqr_aport.write(req);
        end
      end
    end
  endtask
endclass

`endif // MUX_CORNER_SEQ_SVH