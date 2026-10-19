`ifndef DEMUX_SEQUENCER_SVH
`define DEMUX_SEQUENCER_SVH

class demux_sequencer extends uvm_sequencer #(demux_sequence_item);
  `uvm_component_utils(demux_sequencer)

  uvm_analysis_port#(demux_sequence_item) seqr_aport;

  function new(string name = "demux_sequencer", uvm_component parent = null);
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

`endif // DEMUX_SEQUENCER_SVH
