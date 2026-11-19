`ifndef CREDITS_HANDLER_SBTX_BACK_TO_BACK_SEQUENCE_SVH
`define CREDITS_HANDLER_SBTX_BACK_TO_BACK_SEQUENCE_SVH

class Credits_Handler_SBTX_back_to_back_sequence extends uvm_sequence #(Credits_Handler_SBTX_sequence_item);
  `uvm_object_utils(Credits_Handler_SBTX_back_to_back_sequence)
  `uvm_declare_p_sequencer(Credits_Handler_SBTX_sequencer)

  Credits_Handler_SBTX_sequence_item req;
  int num_txns = 20;

  function new(string name = "Credits_Handler_SBTX_back_to_back_sequence");
    super.new(name);
  endfunction

  task body();
    repeat(num_txns) begin
      req = Credits_Handler_SBTX_sequence_item::type_id::create("req");
      start_item(req);
      assert (req.randomize() with {D2D_phy_marker == 1; credit == 1; UIE == 1; data_marker == 0; comp_marker == 0;}) else `uvm_error("SEQ", "Randomization failed")
      finish_item(req);
      p_sequencer.seqr_aport.write(req);
    end
  endtask
endclass

`endif // CREDITS_HANDLER_SBTX_BACK_TO_BACK_SEQUENCE_SVH
