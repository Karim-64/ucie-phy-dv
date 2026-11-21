`ifndef PACKET_BUFFER_SBRX_SEQUENCER_SVH
`define PACKET_BUFFER_SBRX_SEQUENCER_SVH

class Packet_buffer_SBRX_sequencer extends uvm_sequencer #(Packet_buffer_SBRX_sequence_item);
  `uvm_component_utils(Packet_buffer_SBRX_sequencer)

  uvm_analysis_port#(Packet_buffer_SBRX_sequence_item) seqr_aport;

  function new(string name = "Packet_buffer_SBRX_sequencer", uvm_component parent = null);
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

`endif // PACKET_BUFFER_SBRX_SEQUENCER_SVH
