`ifndef PE_SBTX_VSEQ_SVH
`define PE_SBTX_VSEQ_SVH

class pe_sbtx_vseq extends uvm_sequence#(uvm_sequence_item);
  `uvm_object_utils(pe_sbtx_vseq)
  `uvm_declare_p_sequencer(pe_sbtx_vseqr)
  
  pe_sbtx_PHY_rst_seq phy_rst_seq;
  
  // Scenario 1: Normal Sanity Sequence
  pe_sbtx_D2D_sanity_seq d2d_sanity_seq;
  pe_sbtx_PHY_sanity_seq phy_sanity_seq;
  
  // Scenario 2: Priority & Contention Check
  pe_sbtx_D2D_contention_seq d2d_contention_seq;
  pe_sbtx_PHY_contention_seq phy_contention_seq;
  
  // Scenario 3: Mid-Message Locking (Mid-of-Message Interruption)
  pe_sbtx_D2D_mid_lock_seq d2d_mid_lock_seq;
  pe_sbtx_PHY_mid_lock_seq phy_mid_lock_seq;
  
  // Scenario 4: Completion Marker (Comp_Marker_D2D) Filtering & Passthrough
  pe_sbtx_D2D_comp_marker_seq d2d_comp_marker_seq;
  pe_sbtx_PHY_comp_marker_seq phy_comp_marker_seq;
  
  // Scenario 5: Back-to-Back Traffic & The Post-Lock Bubble
  pe_sbtx_D2D_b2b_seq d2d_b2b_seq;
  pe_sbtx_PHY_b2b_seq phy_b2b_seq;
  
  // Scenario 6: Reactive Retry Loop (End-to-End Resend Completion)
  pe_sbtx_D2D_retry_seq d2d_retry_seq;
  pe_sbtx_PHY_retry_seq phy_retry_seq;
  
  // Scenario 7: Simultaneous Contention During a Lock (BOTH_ACTIVE Edge Case)
  pe_sbtx_D2D_lock_contention_seq d2d_lock_contention_seq;
  pe_sbtx_PHY_lock_contention_seq phy_lock_contention_seq;
  
  // Scenario 8: Mid-Transaction Asynchronous Reset (RST_n) Recovery
  pe_sbtx_D2D_reset_recovery_seq d2d_reset_recovery_seq;
  pe_sbtx_PHY_reset_recovery_seq phy_reset_recovery_seq;

  // Scenario 9: Coverage Closure Sequence
  pe_sbtx_D2D_cov_closure_seq d2d_cov_closure_seq;
  pe_sbtx_PHY_cov_closure_seq phy_cov_closure_seq;

  // Scenario 10: Randomized Stress Sequence (100 transactions each)
  pe_sbtx_D2D_rand_seq d2d_rand_seq;
  pe_sbtx_PHY_rand_seq phy_rand_seq;
  
  function new(string name = "pe_sbtx_vseq");
    super.new(name);
  endfunction
  
  task body();
    // Instantiate all scenario sequences
    d2d_sanity_seq = pe_sbtx_D2D_sanity_seq::type_id::create("d2d_sanity_seq");
    phy_sanity_seq = pe_sbtx_PHY_sanity_seq::type_id::create("phy_sanity_seq");
    
    phy_rst_seq = pe_sbtx_PHY_rst_seq::type_id::create("phy_rst_seq");
    
    d2d_contention_seq = pe_sbtx_D2D_contention_seq::type_id::create("d2d_contention_seq");
    phy_contention_seq = pe_sbtx_PHY_contention_seq::type_id::create("phy_contention_seq");
    
    d2d_mid_lock_seq = pe_sbtx_D2D_mid_lock_seq::type_id::create("d2d_mid_lock_seq");
    phy_mid_lock_seq = pe_sbtx_PHY_mid_lock_seq::type_id::create("phy_mid_lock_seq");
    
    d2d_comp_marker_seq = pe_sbtx_D2D_comp_marker_seq::type_id::create("d2d_comp_marker_seq");
    phy_comp_marker_seq = pe_sbtx_PHY_comp_marker_seq::type_id::create("phy_comp_marker_seq");
    
    d2d_b2b_seq = pe_sbtx_D2D_b2b_seq::type_id::create("d2d_b2b_seq");
    phy_b2b_seq = pe_sbtx_PHY_b2b_seq::type_id::create("phy_b2b_seq");
    
    d2d_retry_seq = pe_sbtx_D2D_retry_seq::type_id::create("d2d_retry_seq");
    phy_retry_seq = pe_sbtx_PHY_retry_seq::type_id::create("phy_retry_seq");
    
    d2d_lock_contention_seq = pe_sbtx_D2D_lock_contention_seq::type_id::create("d2d_lock_contention_seq");
    phy_lock_contention_seq = pe_sbtx_PHY_lock_contention_seq::type_id::create("phy_lock_contention_seq");
    
    d2d_reset_recovery_seq = pe_sbtx_D2D_reset_recovery_seq::type_id::create("d2d_reset_recovery_seq");
    phy_reset_recovery_seq = pe_sbtx_PHY_reset_recovery_seq::type_id::create("phy_reset_recovery_seq");

    d2d_cov_closure_seq = pe_sbtx_D2D_cov_closure_seq::type_id::create("d2d_cov_closure_seq");
    phy_cov_closure_seq = pe_sbtx_PHY_cov_closure_seq::type_id::create("phy_cov_closure_seq");

    d2d_rand_seq = pe_sbtx_D2D_rand_seq::type_id::create("d2d_rand_seq");
    phy_rand_seq = pe_sbtx_PHY_rand_seq::type_id::create("phy_rand_seq");
    
    // -------------------------------------------------------------------------
    // Scenario 1: Normal Sanity Sequence
    // -------------------------------------------------------------------------
    `uvm_info("PE_SBTX_VSEQ", "Starting Scenario 1: Normal Sanity Sequence", UVM_LOW)
    phy_rst_seq.start(p_sequencer.PHY_seqr);
    d2d_sanity_seq.start(p_sequencer.D2D_seqr);
    phy_sanity_seq.start(p_sequencer.PHY_seqr);
    
    // -------------------------------------------------------------------------
    // Scenario 2: Priority & Contention Check
    // -------------------------------------------------------------------------
    `uvm_info("PE_SBTX_VSEQ", "Starting Scenario 2: Priority & Contention Check", UVM_LOW)
    fork
      d2d_contention_seq.start(p_sequencer.D2D_seqr);
      phy_contention_seq.start(p_sequencer.PHY_seqr);
    join
    
    // -------------------------------------------------------------------------
    // Scenario 3: Mid-Message Locking (Mid-of-Message Interruption)
    // -------------------------------------------------------------------------
    `uvm_info("PE_SBTX_VSEQ", "Starting Scenario 3: Mid-Message Locking", UVM_LOW)
    fork
      d2d_mid_lock_seq.start(p_sequencer.D2D_seqr);
      phy_mid_lock_seq.start(p_sequencer.PHY_seqr);
    join
    
    // -------------------------------------------------------------------------
    // Scenario 4: Completion Marker (Comp_Marker_D2D) Filtering & Passthrough
    // -------------------------------------------------------------------------
    `uvm_info("PE_SBTX_VSEQ", "Starting Scenario 4: Completion Marker Filtering & Passthrough", UVM_LOW)
    fork
      d2d_comp_marker_seq.start(p_sequencer.D2D_seqr);
      phy_comp_marker_seq.start(p_sequencer.PHY_seqr);
    join
    
    // // -------------------------------------------------------------------------
    // // Scenario 5: Back-to-Back Traffic & The Post-Lock Bubble
    // // -------------------------------------------------------------------------
    `uvm_info("PE_SBTX_VSEQ", "Starting Scenario 5: Back-to-Back Traffic & Post-Lock Bubble", UVM_LOW)
    fork
      d2d_b2b_seq.start(p_sequencer.D2D_seqr);
      phy_b2b_seq.start(p_sequencer.PHY_seqr);
    join
    
    // -------------------------------------------------------------------------
    // Scenario 6: Reactive Retry Loop (End-to-End Resend Completion)
    // -------------------------------------------------------------------------
    `uvm_info("PE_SBTX_VSEQ", "Starting Scenario 6: Reactive Retry Loop", UVM_LOW)
    phy_rst_seq.start(p_sequencer.PHY_seqr);
    fork
      d2d_retry_seq.start(p_sequencer.D2D_seqr);
      phy_retry_seq.start(p_sequencer.PHY_seqr);
    join
    
    // -------------------------------------------------------------------------
    // Scenario 7: Simultaneous Contention During a Lock (BOTH_ACTIVE Edge Case)
    // -------------------------------------------------------------------------
    `uvm_info("PE_SBTX_VSEQ", "Starting Scenario 7: Simultaneous Contention During a Lock", UVM_LOW)
    fork
      d2d_lock_contention_seq.start(p_sequencer.D2D_seqr);
      phy_lock_contention_seq.start(p_sequencer.PHY_seqr);
    join
    
    // -------------------------------------------------------------------------
    // Scenario 8: Mid-Transaction Asynchronous Reset (RST_n) Recovery
    // -------------------------------------------------------------------------
    `uvm_info("PE_SBTX_VSEQ", "Starting Scenario 8: Mid-Transaction Asynchronous Reset Recovery", UVM_LOW)
    fork
      d2d_reset_recovery_seq.start(p_sequencer.D2D_seqr);
      phy_reset_recovery_seq.start(p_sequencer.PHY_seqr);
    join

    // -------------------------------------------------------------------------
    // Scenario 9: Coverage Closure Sequence
    // -------------------------------------------------------------------------
    `uvm_info("PE_SBTX_VSEQ", "Starting Scenario 9: Coverage Closure Sequence", UVM_LOW)
    fork
      d2d_cov_closure_seq.start(p_sequencer.D2D_seqr);
      phy_cov_closure_seq.start(p_sequencer.PHY_seqr);
    join

    // -------------------------------------------------------------------------
    // Scenario 10: Randomized Stress Sequence (100 transactions each)
    // -------------------------------------------------------------------------
    `uvm_info("PE_SBTX_VSEQ", "Starting Scenario 10: Randomized Stress Sequence (100 TXs each)", UVM_LOW)
    fork
      d2d_rand_seq.start(p_sequencer.D2D_seqr);
      phy_rand_seq.start(p_sequencer.PHY_seqr);
    join
    
    `uvm_info("PE_SBTX_VSEQ", "All Verification Scenarios Completed.", UVM_LOW)
  endtask
endclass

`endif // PE_SBTX_VSEQ_SVH