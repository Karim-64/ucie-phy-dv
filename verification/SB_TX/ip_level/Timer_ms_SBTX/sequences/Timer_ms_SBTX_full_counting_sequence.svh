`ifndef TIMER_MS_SBTX_FULL_COUNTING_SEQUENCE_SVH
`define TIMER_MS_SBTX_FULL_COUNTING_SEQUENCE_SVH

class Timer_ms_SBTX_full_counting_sequence extends uvm_sequence #(Timer_ms_SBTX_sequence_item);
  `uvm_object_utils(Timer_ms_SBTX_full_counting_sequence)
  `uvm_declare_p_sequencer(Timer_ms_SBTX_sequencer)

  Timer_ms_SBTX_sequence_item req;

  int num_txns = COUNT_MAX+1;
  
  function new(string name = "Timer_ms_SBTX_full_counting_sequence");
    super.new(name);
  endfunction

  task body();
    req = Timer_ms_SBTX_sequence_item::type_id::create("req");
    start_item(req);
    assert (req.randomize() with {rst_n == 0; start == 1;}) else `uvm_error("SEQ", "Randomization failed")
    finish_item(req);
    p_sequencer.seqr_aport.write(req);
    
    repeat(num_txns-1) begin
      req = Timer_ms_SBTX_sequence_item::type_id::create("req");
      start_item(req);
      assert (req.randomize() with {rst_n == 1;}) else `uvm_error("SEQ", "Randomization failed")
      finish_item(req);
      p_sequencer.seqr_aport.write(req);
    end
  endtask
endclass

`endif // TIMER_MS_SBTX_FULL_COUNTING_SEQUENCE_SVH
