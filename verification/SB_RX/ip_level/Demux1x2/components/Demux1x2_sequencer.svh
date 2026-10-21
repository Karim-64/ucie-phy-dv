`ifndef DEMUX1X2_SEQUENCER_SVH
`define DEMUX1X2_SEQUENCER_SVH

class Demux1x2_sequencer extends uvm_sequencer #(Demux1x2_sequence_item);
  `uvm_component_utils(Demux1x2_sequencer)

  uvm_analysis_port#(Demux1x2_sequence_item) seqr_aport;

  function new(string name = "Demux1x2_sequencer", uvm_component parent = null);
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

`endif // DEMUX1X2_SEQUENCER_SVH
