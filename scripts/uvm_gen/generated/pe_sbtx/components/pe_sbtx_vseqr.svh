`ifndef PE_SBTX_VSEQR_SVH
`define PE_SBTX_VSEQR_SVH

class pe_sbtx_vseqr extends uvm_sequencer;
  `uvm_component_utils(pe_sbtx_vseqr)

  pe_sbtx_D2D_sequencer D2D_seqr;
  pe_sbtx_PHY_sequencer PHY_seqr;

  function new(string name = "pe_sbtx_vseqr", uvm_component parent = null);
    super.new(name, parent);
  endfunction
endclass

`endif // PE_SBTX_VSEQR_SVH
