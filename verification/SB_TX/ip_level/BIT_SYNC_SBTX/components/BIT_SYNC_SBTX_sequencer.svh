`ifndef BIT_SYNC_SBTX_SEQUENCER_SVH
`define BIT_SYNC_SBTX_SEQUENCER_SVH

class BIT_SYNC_SBTX_sequencer extends uvm_sequencer #(BIT_SYNC_SBTX_sequence_item);
  `uvm_component_utils(BIT_SYNC_SBTX_sequencer)

  uvm_analysis_port#(BIT_SYNC_SBTX_sequence_item) seqr_aport;

  function new(string name = "BIT_SYNC_SBTX_sequencer", uvm_component parent = null);
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

`endif // BIT_SYNC_SBTX_SEQUENCER_SVH
