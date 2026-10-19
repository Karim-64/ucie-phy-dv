`ifndef DMUX_1X4_SEQUENCER_SVH
`define DMUX_1X4_SEQUENCER_SVH

class DMUX_1x4_sequencer extends uvm_sequencer #(DMUX_1x4_sequence_item);
  `uvm_component_utils(DMUX_1x4_sequencer)

  uvm_analysis_port#(DMUX_1x4_sequence_item) seqr_aport;

  function new(string name = "DMUX_1x4_sequencer", uvm_component parent = null);
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

`endif // DMUX_1X4_SEQUENCER_SVH
