`ifndef MEM_SEQUENCER_SVH
`define MEM_SEQUENCER_SVH

class mem_sequencer extends uvm_sequencer #(mem_sequence_item);
  `uvm_component_utils(mem_sequencer)

  uvm_analysis_port#(mem_sequence_item) seqr_aport;

  function new(string name = "mem_sequencer", uvm_component parent = null);
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

`endif // MEM_SEQUENCER_SVH
