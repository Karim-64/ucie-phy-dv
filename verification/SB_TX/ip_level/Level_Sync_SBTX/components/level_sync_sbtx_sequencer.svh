`ifndef LEVEL_SYNC_SBTX_SEQUENCER_SVH
`define LEVEL_SYNC_SBTX_SEQUENCER_SVH

class level_sync_sbtx_sequencer extends uvm_sequencer #(level_sync_sbtx_sequence_item);
  `uvm_component_utils(level_sync_sbtx_sequencer)

  uvm_analysis_port#(level_sync_sbtx_sequence_item) seqr_aport;

  function new(string name = "level_sync_sbtx_sequencer", uvm_component parent = null);
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

`endif // LEVEL_SYNC_SBTX_SEQUENCER_SVH
