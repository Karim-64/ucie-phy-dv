`ifndef CREDITS_HANDLER_SBTX_RANDOM_SEQUENCE_SVH
`define CREDITS_HANDLER_SBTX_RANDOM_SEQUENCE_SVH

class Credits_Handler_SBTX_random_sequence extends uvm_sequence #(Credits_Handler_SBTX_sequence_item);
  `uvm_object_utils(Credits_Handler_SBTX_random_sequence)
  `uvm_declare_p_sequencer(Credits_Handler_SBTX_sequencer)

  Credits_Handler_SBTX_sequence_item req;
  int num_txns = 20;

  function new(string name = "Credits_Handler_SBTX_random_sequence");
    super.new(name);
  endfunction

  task body();
    repeat(num_txns) begin
      req = Credits_Handler_SBTX_sequence_item::type_id::create("req");
      start_item(req);
      assert (req.randomize()) else `uvm_error("SEQ", "Randomization failed")
      finish_item(req);
      p_sequencer.seqr_aport.write(req);
    end
  endtask
endclass

`endif // CREDITS_HANDLER_SBTX_RANDOM_SEQUENCE_SVH
