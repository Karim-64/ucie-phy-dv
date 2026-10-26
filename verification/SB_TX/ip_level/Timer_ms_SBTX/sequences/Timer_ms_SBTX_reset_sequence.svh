`ifndef TIMER_MS_SBTX_RESET_SEQUENCE_SVH
`define TIMER_MS_SBTX_RESET_SEQUENCE_SVH

class Timer_ms_SBTX_reset_sequence extends uvm_sequence #(Timer_ms_SBTX_sequence_item);
  `uvm_object_utils(Timer_ms_SBTX_reset_sequence)
  `uvm_declare_p_sequencer(Timer_ms_SBTX_sequencer)

  Timer_ms_SBTX_sequence_item req;

  function new(string name = "Timer_ms_SBTX_reset_sequence");
    super.new(name);
  endfunction

  task body();
    req = Timer_ms_SBTX_sequence_item::type_id::create("req");
    start_item(req);
    assert (req.randomize() with {rst_n == 0;}) else `uvm_error("SEQ", "Randomization failed")
    finish_item(req);
    p_sequencer.seqr_aport.write(req);
  endtask
endclass

`endif // TIMER_MS_SBTX_RESET_SEQUENCE_SVH
