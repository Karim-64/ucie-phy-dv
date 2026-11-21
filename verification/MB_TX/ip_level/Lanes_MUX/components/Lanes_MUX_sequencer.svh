`ifndef LANES_MUX_SEQUENCER_SVH
`define LANES_MUX_SEQUENCER_SVH

class Lanes_MUX_sequencer extends uvm_sequencer #(Lanes_MUX_sequence_item);
  `uvm_component_utils(Lanes_MUX_sequencer)

  uvm_analysis_port#(Lanes_MUX_sequence_item) seqr_aport;

  function new(string name = "Lanes_MUX_sequencer", uvm_component parent = null);
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

`endif // LANES_MUX_SEQUENCER_SVH
