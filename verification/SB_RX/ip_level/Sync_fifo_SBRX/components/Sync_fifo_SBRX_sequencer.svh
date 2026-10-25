`ifndef SYNC_FIFO_SBRX_SEQUENCER_SVH
`define SYNC_FIFO_SBRX_SEQUENCER_SVH

class Sync_fifo_SBRX_sequencer extends uvm_sequencer #(Sync_fifo_SBRX_sequence_item);
  `uvm_component_utils(Sync_fifo_SBRX_sequencer)

  uvm_analysis_port#(Sync_fifo_SBRX_sequence_item) seqr_aport;

  function new(string name = "Sync_fifo_SBRX_sequencer", uvm_component parent = null);
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

`endif // SYNC_FIFO_SBRX_SEQUENCER_SVH
