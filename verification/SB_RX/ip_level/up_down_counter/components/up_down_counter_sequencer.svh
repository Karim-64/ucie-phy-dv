`ifndef UP_DOWN_COUNTER_SEQUENCER_SVH
`define UP_DOWN_COUNTER_SEQUENCER_SVH

class up_down_counter_sequencer extends uvm_sequencer #(up_down_counter_sequence_item);
  `uvm_component_utils(up_down_counter_sequencer)

  uvm_analysis_port#(up_down_counter_sequence_item) seqr_aport;

  function new(string name = "up_down_counter_sequencer", uvm_component parent = null);
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

`endif // UP_DOWN_COUNTER_SEQUENCER_SVH
