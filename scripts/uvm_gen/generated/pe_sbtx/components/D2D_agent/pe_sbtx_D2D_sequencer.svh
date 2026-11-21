`ifndef PE_SBTX_D2D_SEQUENCER_SVH
`define PE_SBTX_D2D_SEQUENCER_SVH

class pe_sbtx_D2D_sequencer extends uvm_sequencer #(pe_sbtx_D2D_sequence_item);
  `uvm_component_utils(pe_sbtx_D2D_sequencer)

  // seqr_aport  : sequences publish the item they are driving to the monitor (mon_aimp)
  // seqr_aexport: monitor feedback (sampled responses) for reactive sequences
  uvm_analysis_port#(pe_sbtx_D2D_sequence_item) seqr_aport;
  uvm_analysis_export#(pe_sbtx_D2D_sequence_item) seqr_aexport;
  uvm_tlm_analysis_fifo#(pe_sbtx_D2D_sequence_item) seqr_fifo;

  function new(string name = "pe_sbtx_D2D_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    seqr_aport = new("seqr_aport", this);
    seqr_aexport = new("seqr_aexport", this);
    seqr_fifo = new("seqr_fifo", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    seqr_aexport.connect(seqr_fifo.analysis_export);
  endfunction
endclass

`endif // PE_SBTX_D2D_SEQUENCER_SVH
