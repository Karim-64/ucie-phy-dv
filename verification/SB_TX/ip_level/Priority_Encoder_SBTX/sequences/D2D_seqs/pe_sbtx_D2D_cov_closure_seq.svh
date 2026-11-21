`ifndef PE_SBTX_D2D_COV_CLOSURE_SEQ_SVH
`define PE_SBTX_D2D_COV_CLOSURE_SEQ_SVH

// =============================================================================
// Coverage Closure Sequence (D2D side)
// Targets the remaining uncovered bins in coverage_detailed_report.txt:
// 1. RTL Expression Line 57: (Last_Priority != D2D_ONLY & Priority_Lock) == 0
//    via D2D_ONLY (d2d_en=1, phy_en=0) while D2D already holds Priority_Lock.
// 2. Functional Cross cx_contention bin <phy_en=0, d2d_en=1, phy_dm=1, d2d_dm=1>
//    during PHY Lock Cycle 2.
// Total: 8 cycles
// =============================================================================
class pe_sbtx_D2D_cov_closure_seq extends pe_sbtx_D2D_base_seq;
  `uvm_object_utils(pe_sbtx_D2D_cov_closure_seq)
  
  function new(string name = "pe_sbtx_D2D_cov_closure_seq");
    super.new(name);
  endfunction
  
  virtual task body();
    // Part 1 (Cycles 1..4): D2D holds 2-phase lock and keeps d2d_en=1 in Lock Cycle 1
    drive_d2d_item(.en(1'b1), .data_marker(1'b1), .comp_marker(1'b0), .rand_data(1'b0)); // Cycle 1: D2D Request & Lock trigger
    drive_d2d_item(.en(1'b1), .data_marker(1'b1), .comp_marker(1'b0), .rand_data(1'b1)); // Cycle 2: Lock Cycle 1 (D2D_ONLY with Last_Priority==D2D_ONLY)
    drive_d2d_item(.en(1'b0), .data_marker(1'b1), .comp_marker(1'b0), .rand_data(1'b1)); // Cycle 3: Lock Cycle 2 (D2D Data)
    drive_d2d_idle(1); // Cycle 4: Post-lock cooldown bubble
    
    // Part 2 (Cycles 5..8): Idle during PHY Lock trigger & Cycle 1; assert d2d_en=1, d2d_dm=1 in PHY Lock Cycle 2
    drive_d2d_idle(2); // Cycles 5..6: Idle during PHY Req & Lock Cycle 1
    drive_d2d_item(.en(1'b1), .data_marker(1'b1), .comp_marker(1'b0), .rand_data(1'b1)); // Cycle 7: Hits cx_contention <0,1,1,1>
    drive_d2d_idle(1); // Cycle 8: Post-lock cooldown bubble
  endtask
endclass

`endif // PE_SBTX_D2D_COV_CLOSURE_SEQ_SVH