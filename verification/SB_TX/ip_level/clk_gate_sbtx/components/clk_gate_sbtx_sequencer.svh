`ifndef CLK_GATE_SBTX_SEQUENCER_SVH
`define CLK_GATE_SBTX_SEQUENCER_SVH

class clk_gate_sbtx_sequencer extends uvm_sequencer #(clk_gate_sbtx_sequence_item);
  `uvm_component_utils(clk_gate_sbtx_sequencer)

  uvm_analysis_port#(clk_gate_sbtx_sequence_item) seqr_aport;

  function new(string name = "clk_gate_sbtx_sequencer", uvm_component parent = null);
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

`endif // CLK_GATE_SBTX_SEQUENCER_SVH
