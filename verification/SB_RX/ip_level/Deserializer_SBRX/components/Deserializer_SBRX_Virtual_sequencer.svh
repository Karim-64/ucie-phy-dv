`ifndef DESERIALIZER_SBRX_VIRTUAL_SEQUENCER_SVH
`define DESERIALIZER_SBRX_VIRTUAL_SEQUENCER_SVH

class Deserializer_SBRX_Virtual_sequencer extends uvm_sequencer;
    `uvm_component_utils(Deserializer_SBRX_Virtual_sequencer)
    Deserializer_SBRX_sequencer seqr;
    Deserializer_SBRX_sequencer2 seqr2;

    function new(string name = "Deserializer_SBRX_Virtual_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction
endclass

`endif 