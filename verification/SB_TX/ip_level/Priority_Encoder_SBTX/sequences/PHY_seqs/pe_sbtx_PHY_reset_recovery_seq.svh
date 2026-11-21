`ifndef PE_SBTX_PHY_RESET_RECOVERY_SEQ_SVH
`define PE_SBTX_PHY_RESET_RECOVERY_SEQ_SVH

// =============================================================================
// Scenario 8 (PHY side): Mid-Transaction Asynchronous Reset (RST_n) Recovery
// - Cycles 1..4  : D2D starts a 2-phase locked transaction; PHY asserts RST_n=0
//                  on Cycle 3 (right between Header Phase and Data Phase) and
//                  de-asserts RST_n=1 on Cycle 4.
// - Cycles 5..10 : Post-reset recovery sanity packets (D2D 1-phase, then PHY 1-phase).
// Total: 10 cycles
// =============================================================================
class pe_sbtx_PHY_reset_recovery_seq extends pe_sbtx_PHY_base_seq;
  `uvm_object_utils(pe_sbtx_PHY_reset_recovery_seq)
  
  function new(string name = "pe_sbtx_PHY_reset_recovery_seq");
    super.new(name);
  endfunction
  
  virtual task body();
    // Step 1 (Cycles 1..4): Assert RST_n = 0 on Cycle 3 between D2D Header and Data phases
    drive_phy_idle(2); // Cycles 1..2: RST_n = 1 during D2D Request & Header Phase
    drive_phy_item(.rst_n(1'b0), .en(1'b0), .data_marker(1'b0), .rand_data(1'b0)); // Cycle 3: Assert RST_n = 0 mid-transaction!
    drive_phy_idle(1); // Cycle 4: De-assert RST_n = 1
    
    // Step 2 (Cycles 5..10): Post-reset recovery check (D2D 1-phase on Cycles 5..7, PHY 1-phase on Cycles 8..10)
    drive_phy_idle(3); // Cycles 5..7: Idle while D2D sends 1-phase recovery packet
    drive_phy_item(.rst_n(1'b1), .en(1'b1), .data_marker(1'b0), .rand_data(1'b0)); // Cycle 8: PHY 1-phase Request
    drive_phy_item(.rst_n(1'b1), .en(1'b0), .data_marker(1'b0), .rand_data(1'b1)); // Cycle 9: PHY 1-phase Header
    drive_phy_idle(1); // Cycle 10: Drain cycle

    // Step 3 (Cycles 11..17): PHY 2-phase transaction aborted mid-lock by RST_n = 0 on Cycle 13 & recovers
    drive_phy_item(.rst_n(1'b1), .en(1'b1), .data_marker(1'b1), .rand_data(1'b0)); // Cycle 11: PHY 2-phase Request
    drive_phy_item(.rst_n(1'b1), .en(1'b0), .data_marker(1'b1), .rand_data(1'b1)); // Cycle 12: Lock Cycle 1 (Header Phase)
    drive_phy_item(.rst_n(1'b0), .en(1'b0), .data_marker(1'b1), .rand_data(1'b1)); // Cycle 13: Assert RST_n = 0 mid-PHY-lock!
    drive_phy_idle(1); // Cycle 14: De-assert RST_n = 1
    drive_phy_item(.rst_n(1'b1), .en(1'b1), .data_marker(1'b0), .rand_data(1'b0)); // Cycle 15: Post-reset PHY 1-phase Request
    drive_phy_item(.rst_n(1'b1), .en(1'b0), .data_marker(1'b0), .rand_data(1'b1)); // Cycle 16: Post-reset PHY 1-phase Header
    drive_phy_idle(1); // Cycle 17: Final drain cycle
  endtask
endclass

`endif // PE_SBTX_PHY_RESET_RECOVERY_SEQ_SVH