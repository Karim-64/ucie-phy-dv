`ifndef LFSR_PER_LANE_SEQUENCER_SVH
`define LFSR_PER_LANE_SEQUENCER_SVH

class lfsr_per_lane_sequencer extends uvm_sequencer #(lfsr_per_lane_sequence_item);
  `uvm_component_utils(lfsr_per_lane_sequencer)

  uvm_analysis_port#(lfsr_per_lane_sequence_item) seqr_aport;

  function new(string name = "lfsr_per_lane_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    seqr_aport = new("seqr_aport", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction
endclass

`endif // LFSR_PER_LANE_SEQUENCER_SVH
