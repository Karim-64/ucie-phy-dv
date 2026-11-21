`ifndef SERIALIZER_SEQUENCER_SVH
`define SERIALIZER_SEQUENCER_SVH

class Serializer_sequencer extends uvm_sequencer #(Serializer_sequence_item);
  `uvm_component_utils(Serializer_sequencer)

  uvm_analysis_port#(Serializer_sequence_item) seqr_aport;

  function new(string name = "Serializer_sequencer", uvm_component parent = null);
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

`endif // SERIALIZER_SEQUENCER_SVH
