`ifndef PE_SBTX_VSEQ_SVH
`define PE_SBTX_VSEQ_SVH

class pe_sbtx_vseq extends uvm_sequence#(uvm_sequence_item);
  `uvm_object_utils(pe_sbtx_vseq)
  `uvm_declare_p_sequencer(pe_sbtx_vseqr)

  pe_sbtx_D2D_base_seq d2d_base_seq;
  pe_sbtx_PHY_base_seq phy_base_seq;
  // TODO: declare your scenario sequences here (one per agent per scenario)

  function new(string name = "pe_sbtx_vseq");
    super.new(name);
  endfunction

  task body();
    d2d_base_seq = pe_sbtx_D2D_base_seq::type_id::create("d2d_base_seq");
    phy_base_seq = pe_sbtx_PHY_base_seq::type_id::create("phy_base_seq");

    // -------------------------------------------------------------------------
    // Scenario 0: base sequences on every active agent in parallel
    // -------------------------------------------------------------------------
    `uvm_info("PE_SBTX_VSEQ", "Starting base sequences", UVM_LOW)
    fork
      if (p_sequencer.D2D_seqr != null) d2d_base_seq.start(p_sequencer.D2D_seqr);
      if (p_sequencer.PHY_seqr != null) phy_base_seq.start(p_sequencer.PHY_seqr);
    join

    // TODO: add scenarios, e.g.
    //   fork
    //     <agt>_scenario_seq.start(p_sequencer.<AGT>_seqr);
    //     ...
    //   join

    `uvm_info("PE_SBTX_VSEQ", "All Verification Scenarios Completed.", UVM_LOW)
  endtask
endclass

`endif // PE_SBTX_VSEQ_SVH
