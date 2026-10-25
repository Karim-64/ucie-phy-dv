`ifndef MUX_SBRX_SEQUENCER_SVH
`define MUX_SBRX_SEQUENCER_SVH

class mux_sbrx_sequencer extends uvm_sequencer #(mux_sbrx_sequence_item);
  `uvm_component_utils(mux_sbrx_sequencer)

  uvm_analysis_port#(mux_sbrx_sequence_item) seqr_aport;

  function new(string name = "mux_sbrx_sequencer", uvm_component parent = null);
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

`endif // MUX_SBRX_SEQUENCER_SVH
