`ifndef WR_CONTROL_SBTX_SEQUENCER_SVH
`define WR_CONTROL_SBTX_SEQUENCER_SVH

class wr_control_sbtx_sequencer extends uvm_sequencer #(wr_control_sbtx_sequence_item);
  `uvm_component_utils(wr_control_sbtx_sequencer)

  uvm_analysis_port#(wr_control_sbtx_sequence_item) seqr_aport;

  function new(string name = "wr_control_sbtx_sequencer", uvm_component parent = null);
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

`endif // WR_CONTROL_SBTX_SEQUENCER_SVH
