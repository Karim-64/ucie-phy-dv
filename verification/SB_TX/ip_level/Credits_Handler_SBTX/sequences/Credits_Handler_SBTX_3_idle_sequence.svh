`ifndef CREDITS_HANDLER_SBTX_3_IDLE_SEQUENCE_SVH
`define CREDITS_HANDLER_SBTX_3_IDLE_SEQUENCE_SVH

class Credits_Handler_SBTX_3_idle_sequence extends uvm_sequence #(Credits_Handler_SBTX_sequence_item);
  `uvm_object_utils(Credits_Handler_SBTX_3_idle_sequence)
  `uvm_declare_p_sequencer(Credits_Handler_SBTX_sequencer)

  Credits_Handler_SBTX_sequence_item req;
  int num_txns = 10;

  function new(string name = "Credits_Handler_SBTX_3_idle_sequence");
    super.new(name);
  endfunction

  task body();
    repeat(num_txns) begin
      req = Credits_Handler_SBTX_sequence_item::type_id::create("req");
      start_item(req);
      assert (req.randomize()) else `uvm_error("SEQ", "Randomization failed")
      finish_item(req);
      p_sequencer.seqr_aport.write(req);
      repeat(3) begin
      req = Credits_Handler_SBTX_sequence_item::type_id::create("req");
      start_item(req);
      assert (req.randomize() with {rst_n == 1; comp_sent == 0; credit == 0; D2D_phy_marker == 0; UIE == 0;}) else `uvm_error("SEQ", "Randomization failed")
      finish_item(req);
      p_sequencer.seqr_aport.write(req);
      end
    end
  endtask
endclass

`endif // CREDITS_HANDLER_SBTX_3_IDLE_SEQUENCE_SVH
