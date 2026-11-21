`ifndef GRAY_SYNCHRONIZER_SBTX_EXHASTIVE_SEQ_SVH
`define GRAY_SYNCHRONIZER_SBTX_EXHASTIVE_SEQ_SVH

class gray_synchronizer_sbtx_exhaustive_seq extends uvm_sequence #(gray_synchronizer_sbtx_sequence_item);
  `uvm_object_utils(gray_synchronizer_sbtx_exhaustive_seq)
  `uvm_declare_p_sequencer(gray_synchronizer_sbtx_sequencer)

  function new(string name = "gray_synchronizer_sbtx_exhaustive_seq");
    super.new(name);
  endfunction

    virtual task body();
        for (int j = 0 ; j < 50 ; j ++) begin
          for (int i = 0; i < 4; i++) begin
              req = gray_synchronizer_sbtx_sequence_item::type_id::create("req");
              start_item(req);
              assert(req.randomize() with { Async_Data == local::i; });
              finish_item(req);
              p_sequencer.seqr_aport.write(req);
          end
        end
    endtask
endclass

`endif // GRAY_SYNCHRONIZER_SBTX_EXHASTIVE_SEQUENCE_SVH
