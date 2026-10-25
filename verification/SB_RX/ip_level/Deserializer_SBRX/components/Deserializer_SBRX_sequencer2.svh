`ifndef DESERIALIZER_SBRX_SEQUENCER2_SVH
`define DESERIALIZER_SBRX_SEQUENCER2_SVH

class Deserializer_SBRX_sequencer2 extends Deserializer_SBRX_sequencer;
  `uvm_component_utils(Deserializer_SBRX_sequencer2)

  function new(string name = "Deserializer_SBRX_sequencer2", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction
endclass

`endif // DESERIALIZER_SBRX_SEQUENCER2_SVH
