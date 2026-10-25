`ifndef DESERIALIZER_SBRX_SEQUENCER_SVH
`define DESERIALIZER_SBRX_SEQUENCER_SVH

class Deserializer_SBRX_sequencer extends uvm_sequencer #(Deserializer_SBRX_sequence_item);
  `uvm_component_utils(Deserializer_SBRX_sequencer)

  uvm_analysis_port#(Deserializer_SBRX_sequence_item) seqr_aport;

  function new(string name = "Deserializer_SBRX_sequencer", uvm_component parent = null);
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

`endif // DESERIALIZER_SBRX_SEQUENCER_SVH
