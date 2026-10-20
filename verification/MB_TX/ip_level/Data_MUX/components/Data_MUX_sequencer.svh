`ifndef DATA_MUX_SEQUENCER_SVH
`define DATA_MUX_SEQUENCER_SVH

class Data_MUX_sequencer extends uvm_sequencer #(Data_MUX_sequence_item);
  `uvm_component_utils(Data_MUX_sequencer)

  uvm_analysis_port#(Data_MUX_sequence_item) seqr_aport;

  function new(string name = "Data_MUX_sequencer", uvm_component parent = null);
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

`endif // DATA_MUX_SEQUENCER_SVH
