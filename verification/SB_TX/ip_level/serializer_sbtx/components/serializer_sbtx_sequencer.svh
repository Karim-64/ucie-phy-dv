`ifndef SERIALIZER_SBTX_SEQUENCER_SVH
`define SERIALIZER_SBTX_SEQUENCER_SVH

class serializer_sbtx_sequencer extends uvm_sequencer #(serializer_sbtx_sequence_item);
  `uvm_component_utils(serializer_sbtx_sequencer)

  uvm_analysis_port#(serializer_sbtx_sequence_item) seqr_aport;

  function new(string name = "serializer_sbtx_sequencer", uvm_component parent = null);
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

`endif // SERIALIZER_SBTX_SEQUENCER_SVH
