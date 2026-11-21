`ifndef TIMER_MS_SBTX_RANDOM_SEQUENCE_SVH
`define TIMER_MS_SBTX_RANDOM_SEQUENCE_SVH

class Timer_ms_SBTX_random_sequence extends uvm_sequence #(Timer_ms_SBTX_sequence_item);
  `uvm_object_utils(Timer_ms_SBTX_random_sequence)
  `uvm_declare_p_sequencer(Timer_ms_SBTX_sequencer)

  Timer_ms_SBTX_sequence_item req;

  int num_txns = COUNT_MAX+1;
  
  function new(string name = "Timer_ms_SBTX_random_sequence");
    super.new(name);
  endfunction

  task body();
    repeat(num_txns) begin
      req = Timer_ms_SBTX_sequence_item::type_id::create("req");
      start_item(req);
      assert (req.randomize()) else `uvm_error("SEQ", "Randomization failed")
      finish_item(req);
      p_sequencer.seqr_aport.write(req);
    end
    for(int i=0; i<=num_txns; i++) begin
      req = Timer_ms_SBTX_sequence_item::type_id::create("req");
      start_item(req);
      if(i == 0) 
        assert (req.randomize() with {rst_n == 1; start == 1;}) else `uvm_error("SEQ", "Randomization failed")
      else 
        assert (req.randomize() with {rst_n == 1; start == 0;}) else `uvm_error("SEQ", "Randomization failed")
      finish_item(req);
      p_sequencer.seqr_aport.write(req);
    end
  endtask
endclass

`endif // TIMER_MS_SBTX_RANDOM_SEQUENCE_SVH
