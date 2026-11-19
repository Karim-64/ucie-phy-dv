`ifndef CREDITS_HANDLER_SBTX_SEQUENCER_SVH
`define CREDITS_HANDLER_SBTX_SEQUENCER_SVH

class Credits_Handler_SBTX_sequencer extends uvm_sequencer #(Credits_Handler_SBTX_sequence_item);
  `uvm_component_utils(Credits_Handler_SBTX_sequencer)

  uvm_analysis_port#(Credits_Handler_SBTX_sequence_item) seqr_aport;

  function new(string name = "Credits_Handler_SBTX_sequencer", uvm_component parent = null);
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

`endif // CREDITS_HANDLER_SBTX_SEQUENCER_SVH
