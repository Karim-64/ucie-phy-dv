`ifndef SYNCHRONIZER_BASE_SEQUENCE_SVH
`define SYNCHRONIZER_BASE_SEQUENCE_SVH

class Synchronizer_base_sequence extends uvm_sequence #(Synchronizer_sequence_item);
  `uvm_object_utils(Synchronizer_base_sequence)
  `uvm_declare_p_sequencer(Synchronizer_sequencer)

  function new(string name = "Synchronizer_base_sequence");
    super.new(name);
  endfunction

  task body();
      req = Synchronizer_sequence_item::type_id::create("req");
      for(int i = 0 ; i < 10 ; i++) begin
        start_item(req);
        req.constraint_mode(0);
        req.c_reset_active.constraint_mode(1);
        if (!req.randomize() with { scenario_mode == Synchronizer_sequence_item::SCENARIO_RESET_ASSERT; })
          `uvm_error("SEQ", "Randomization failed");
        finish_item(req);
        p_sequencer.seqr_aport.write(req);
      end

      for(int i = 0 ; i < 10 ; i++) begin
        start_item(req);
        req.constraint_mode(0);
        req.c_reset_deasserted.constraint_mode(1);
        if (!req.randomize() with { scenario_mode == Synchronizer_sequence_item::SCENARIO_NORMAL; })
          `uvm_error("SEQ", "Randomization failed");
        finish_item(req);
        p_sequencer.seqr_aport.write(req);
      end

      for(int i = 0 ; i < 10 ; i++) begin
        start_item(req);
        req.constraint_mode(0);
        req.c_default_op.constraint_mode(1);
        if (!req.randomize() with { scenario_mode == Synchronizer_sequence_item::SCENARIO_NORMAL; })
          `uvm_error("SEQ", "Randomization failed");
        finish_item(req);
        p_sequencer.seqr_aport.write(req);
      end

      for(int i = 0 ; i < 100 ; i++) begin
        start_item(req);
        req.constraint_mode(0);
        req.c_steady_low.constraint_mode(1);
        if (!req.randomize() with { scenario_mode == Synchronizer_sequence_item::SCENARIO_STEADY_LOW; })
          `uvm_error("SEQ", "Randomization failed");
        finish_item(req);
        p_sequencer.seqr_aport.write(req);
      end

      for(int i = 0 ; i < 100 ; i++) begin
        start_item(req);
        req.constraint_mode(0);
        req.c_steady_high.constraint_mode(1);
        if (!req.randomize() with { scenario_mode == Synchronizer_sequence_item::SCENARIO_STEADY_HIGH; })
          `uvm_error("SEQ", "Randomization failed");
        finish_item(req);
        p_sequencer.seqr_aport.write(req);
      end

      for(int i = 0 ; i < 100 ; i++) begin
        start_item(req);
        req.constraint_mode(0);
        req.c_toggle_pattern.constraint_mode(1);
        if (!req.randomize() with { scenario_mode == Synchronizer_sequence_item::SCENARIO_TOGGLE; })
          `uvm_error("SEQ", "Randomization failed");
        finish_item(req);
        p_sequencer.seqr_aport.write(req);
      end

      for(int i = 0 ; i < 500 ; i++) begin
        start_item(req);
        req.constraint_mode(0);
        req.c_stress_dist.constraint_mode(1);
        if (!req.randomize() with { scenario_mode == Synchronizer_sequence_item::SCENARIO_STRESS_RAND; })
          `uvm_error("SEQ", "Randomization failed");
        finish_item(req);
        p_sequencer.seqr_aport.write(req);
      end
  endtask
endclass

`endif // SYNCHRONIZER_BASE_SEQUENCE_SVH
