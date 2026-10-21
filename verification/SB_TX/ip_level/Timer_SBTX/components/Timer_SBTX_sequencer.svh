`ifndef TIMER_SBTX_SEQUENCER_SVH
`define TIMER_SBTX_SEQUENCER_SVH

class Timer_SBTX_sequencer extends uvm_sequencer #(Timer_SBTX_sequence_item);
  `uvm_component_utils(Timer_SBTX_sequencer)

  uvm_analysis_port#(Timer_SBTX_sequence_item) seqr_aport;

  function new(string name = "Timer_SBTX_sequencer", uvm_component parent = null);
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

`endif // TIMER_SBTX_SEQUENCER_SVH
