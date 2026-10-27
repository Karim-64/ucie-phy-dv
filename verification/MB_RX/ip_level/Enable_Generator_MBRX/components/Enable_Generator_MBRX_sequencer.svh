`ifndef ENABLE_GENERATOR_MBRX_SEQUENCER_SVH
`define ENABLE_GENERATOR_MBRX_SEQUENCER_SVH

class Enable_Generator_MBRX_sequencer extends uvm_sequencer #(Enable_Generator_MBRX_sequence_item);
  `uvm_component_utils(Enable_Generator_MBRX_sequencer)
  uvm_analysis_port#(Enable_Generator_MBRX_sequence_item) seqr_ap;

  function new(string name = "Enable_Generator_MBRX_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    seqr_ap = new("seqr_ap", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction
endclass

`endif // ENABLE_GENERATOR_MBRX_SEQUENCER_SVH
