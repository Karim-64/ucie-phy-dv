`ifndef PE_SBTX_PHY_MID_LOCK_SEQ_SVH
`define PE_SBTX_PHY_MID_LOCK_SEQ_SVH

// =============================================================================
// Scenario 3 (PHY side): Mid-Message Locking (Mid-of-Message Interruption)
// - Cycles 1..4  : D2D holds 2-phase lock; PHY interrupts in Lock Cycle 1
// - Cycles 5..8  : D2D holds 2-phase lock; PHY interrupts in Lock Cycle 2
// - Cycles 9..12 : PHY holds 2-phase lock; D2D interrupts in Lock Cycle 1 & 2
// Total: 12 cycles
// =============================================================================
class pe_sbtx_PHY_mid_lock_seq extends pe_sbtx_PHY_base_seq;
  `uvm_object_utils(pe_sbtx_PHY_mid_lock_seq)
  
  function new(string name = "pe_sbtx_PHY_mid_lock_seq");
    super.new(name);
  endfunction
  
  virtual task body();
    // Sub-test 3a (Cycles 1..4): PHY interrupts D2D in Lock Cycle 1 (Header Phase)
    drive_phy_idle(1); // Cycle 1: Idle while D2D acquires lock
    drive_phy_item(.rst_n(1'b1), .en(1'b1), .data_marker(1'b0), .rand_data(1'b1)); // Cycle 2: PHY interrupts in Lock Cycle 1
    drive_phy_item(.rst_n(1'b1), .en(1'b0), .data_marker(1'b0), .rand_data(1'b1)); // Cycle 3: PHY blocked, PHY_Resend_Req = 1
    drive_phy_idle(1); // Cycle 4: Cooldown bubble
    
    // Sub-test 3b (Cycles 5..8): PHY interrupts D2D in Lock Cycle 2 (Data Phase)
    drive_phy_idle(2); // Cycles 5..6: Idle during D2D Req & Lock Cycle 1
    drive_phy_item(.rst_n(1'b1), .en(1'b1), .data_marker(1'b0), .rand_data(1'b1)); // Cycle 7: PHY interrupts in Lock Cycle 2
    drive_phy_item(.rst_n(1'b1), .en(1'b0), .data_marker(1'b0), .rand_data(1'b1)); // Cycle 8: PHY blocked in cooldown, PHY_Resend_Req = 1
    
    // Sub-test 3c (Cycles 9..12): PHY holds 2-phase lock while D2D interrupts in Lock Cycle 1 & 2
    drive_phy_item(.rst_n(1'b1), .en(1'b1), .data_marker(1'b1), .rand_data(1'b0)); // Cycle 9: PHY Request & Lock trigger
    drive_phy_item(.rst_n(1'b1), .en(1'b0), .data_marker(1'b1), .rand_data(1'b1)); // Cycle 10: Lock Cycle 1 (PHY Header)
    drive_phy_item(.rst_n(1'b1), .en(1'b0), .data_marker(1'b1), .rand_data(1'b1)); // Cycle 11: Lock Cycle 2 (PHY Data)
    drive_phy_idle(1); // Cycle 12: Cooldown bubble
  endtask
endclass

`endif // PE_SBTX_PHY_MID_LOCK_SEQ_SVH