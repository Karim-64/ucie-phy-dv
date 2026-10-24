`ifndef SYNCHRONIZER_SBRX_SEQUENCER_SVH
`define SYNCHRONIZER_SBRX_SEQUENCER_SVH

class Synchronizer_SBRX_sequencer extends uvm_sequencer #(Synchronizer_SBRX_sequence_item);
  `uvm_component_utils(Synchronizer_SBRX_sequencer)

  uvm_analysis_port#(Synchronizer_SBRX_sequence_item) seqr_aport;

  function new(string name = "Synchronizer_SBRX_sequencer", uvm_component parent = null);
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

`endif // SYNCHRONIZER_SBRX_SEQUENCER_SVH
