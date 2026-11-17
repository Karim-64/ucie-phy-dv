`ifndef PE_SBTX_PHY_COV_CLOSURE_SEQ_SVH
`define PE_SBTX_PHY_COV_CLOSURE_SEQ_SVH

// =============================================================================
// Coverage Closure Sequence (PHY side)
// Targets the remaining uncovered bins in coverage_detailed_report.txt:
// 1. RTL Expression Line 55: (Last_Priority != PHY_ONLY & Priority_Lock) == 0
//    via PHY_ONLY (phy_en=1, d2d_en=0) while PHY already holds Priority_Lock.
// 2. Functional Cross cx_contention bin <phy_en=0, d2d_en=1, phy_dm=1, d2d_dm=1>
//    during PHY Lock Cycle 2.
// Total: 8 cycles
// =============================================================================
class pe_sbtx_PHY_cov_closure_seq extends pe_sbtx_PHY_base_seq;
  `uvm_object_utils(pe_sbtx_PHY_cov_closure_seq)
  
  function new(string name = "pe_sbtx_PHY_cov_closure_seq");
    super.new(name);
  endfunction
  
  virtual task body();
    // Part 1 (Cycles 1..4): PHY idle while D2D hits Line 57
    drive_phy_idle(4);
    
    // Part 2 (Cycles 5..8): PHY holds 2-phase lock and keeps phy_en=1 in Lock Cycle 1
    drive_phy_item(.rst_n(1'b1), .en(1'b1), .data_marker(1'b1), .rand_data(1'b0)); // Cycle 5: PHY Request & Lock trigger
    drive_phy_item(.rst_n(1'b1), .en(1'b1), .data_marker(1'b1), .rand_data(1'b1)); // Cycle 6: Lock Cycle 1 (PHY_ONLY with Last_Priority==PHY_ONLY)
    drive_phy_item(.rst_n(1'b1), .en(1'b0), .data_marker(1'b1), .rand_data(1'b1)); // Cycle 7: Lock Cycle 2 (phy_en=0, phy_dm=1 while d2d_en=1, d2d_dm=1)
    drive_phy_item(.rst_n(1'b1), .en(1'b0), .data_marker(1'b1), .rand_data(1'b0)); // Cycle 8: Post-lock cooldown (keeps phy_dm=1 for cg_arbitration sampling)
  endtask
endclass

`endif // PE_SBTX_PHY_COV_CLOSURE_SEQ_SVH