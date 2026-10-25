`ifndef PAT_GEN_ERROR_INJEC_SEQ_SVH
`define PAT_GEN_ERROR_INJEC_SEQ_SVH

class pat_gen_error_injec_seq extends uvm_sequence #(pat_gen_sbtx_sequence_item);
  `uvm_object_utils(pat_gen_error_injec_seq)
  `uvm_declare_p_sequencer(pat_gen_sbtx_sequencer)

  rand int unsigned pulse_width;
  rand int unsigned idle_width;

  function new(string name = "pat_gen_error_injec_seq");
    super.new(name);
  endfunction

  task drive_cycle(logic reset_n, logic enable);
    pat_gen_sbtx_sequence_item req;
    req = pat_gen_sbtx_sequence_item::type_id::create("req");
    start_item(req);
    req.RST_n = reset_n;
    req.Patt_Gen_En = enable;
    finish_item(req);
    p_sequencer.seqr_aport.write(req);
  endtask

  task drive_async_reset(time delay_before_reset, time reset_duration);
    pat_gen_sbtx_sequence_item req;
    req = pat_gen_sbtx_sequence_item::type_id::create("async_reset_req");
    start_item(req);
    req.RST_n = 1'b1;
    req.Patt_Gen_En = 1'b1;
    req.async_reset = 1'b1;
    req.async_reset_delay = delay_before_reset;
    req.async_reset_duration = reset_duration;
    finish_item(req);
    p_sequencer.seqr_aport.write(req);
  endtask

  task drive_burst(int unsigned cycles);
    repeat (cycles) drive_cycle(1'b1, 1'b1);
    drive_cycle(1'b1, 1'b0);
  endtask

  task drive_idle(int unsigned cycles);
    repeat (cycles) drive_cycle(1'b1, 1'b0);
  endtask

  task body();
    int unsigned burst_index;

    // Fixed gaps exercise the restart requirement before randomized stress.
    drive_idle(1);
    drive_burst(8);
    drive_idle(32);
    drive_burst(64);
    drive_idle(1);
    drive_burst(3);

    // Randomized bursts, idle gaps, and asynchronous reset pulses.
    for (burst_index = 0; burst_index < 12; burst_index++) begin
      assert (randomize() with {
        pulse_width inside {[1:100]};
        idle_width inside {[1:32]};
      }) else `uvm_fatal("PAT_GEN_ERR_SEQ", "Could not randomize burst stimulus")

      drive_idle(idle_width);
      drive_burst(pulse_width);

    end
    drive_idle(1);
  endtask
endclass

`endif // PAT_GEN_ERROR_INJEC_SEQ_SVH