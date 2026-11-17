`ifndef LFSR_PER_LANE_BASE_SEQUENCE_SVH
`define LFSR_PER_LANE_BASE_SEQUENCE_SVH

class lfsr_per_lane_base_sequence extends uvm_sequence #(lfsr_per_lane_sequence_item);
  `uvm_object_utils(lfsr_per_lane_base_sequence)
  `uvm_declare_p_sequencer(lfsr_per_lane_sequencer)

  lfsr_per_lane_normal_sequence normal_seq;
  lfsr_per_lane_random_sequence random_seq;
  lfsr_per_lane_training_sequence training_seq;
  lfsr_per_lane_bypass_sequence bypass_seq;
  lfsr_per_lane_pn_enable_sequence pn_enable_seq;
  lfsr_per_lane_opcode_change_sequence opcode_change_seq;
  lfsr_per_lane_error_injection_sequence error_injection_seq;
  lfsr_per_lane_reset_sequence reset_seq;

  function new(string name = "lfsr_per_lane_base_sequence");
    super.new(name);
  endfunction

  task pre_body();
    super.pre_body();
    normal_seq = lfsr_per_lane_normal_sequence::type_id::create("normal_seq");
    random_seq = lfsr_per_lane_random_sequence::type_id::create("random_seq");
    training_seq = lfsr_per_lane_training_sequence::type_id::create("training_seq");
    bypass_seq = lfsr_per_lane_bypass_sequence::type_id::create("bypass_seq");
    pn_enable_seq = lfsr_per_lane_pn_enable_sequence::type_id::create("pn_enable_seq");
    opcode_change_seq =
        lfsr_per_lane_opcode_change_sequence::type_id::create("opcode_change_seq");
    error_injection_seq =
        lfsr_per_lane_error_injection_sequence::type_id::create("error_injection_seq");
    reset_seq = lfsr_per_lane_reset_sequence::type_id::create("reset_seq");
  endtask

  task body();
    reset_seq.start(p_sequencer);
    normal_seq.start(p_sequencer);
    training_seq.start(p_sequencer);
    bypass_seq.start(p_sequencer);
    pn_enable_seq.start(p_sequencer);
    opcode_change_seq.start(p_sequencer);
    error_injection_seq.start(p_sequencer);
    random_seq.start(p_sequencer);
    reset_seq.start(p_sequencer);
  endtask
endclass

`endif // LFSR_PER_LANE_BASE_SEQUENCE_SVH
