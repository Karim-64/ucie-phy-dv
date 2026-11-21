`ifndef PE_SBTX_D2D_MID_LOCK_SEQ_SVH
`define PE_SBTX_D2D_MID_LOCK_SEQ_SVH

// =============================================================================
// Scenario 3 (D2D side): Mid-Message Locking (Mid-of-Message Interruption)
// - Cycles 1..4  : D2D holds 2-phase lock; PHY interrupts in Lock Cycle 1
// - Cycles 5..8  : D2D holds 2-phase lock; PHY interrupts in Lock Cycle 2
// - Cycles 9..12 : PHY holds 2-phase lock; D2D interrupts in Lock Cycle 1 & 2
// Total: 12 cycles
// =============================================================================
class pe_sbtx_D2D_mid_lock_seq extends pe_sbtx_D2D_base_seq;
  `uvm_object_utils(pe_sbtx_D2D_mid_lock_seq)
  
  function new(string name = "pe_sbtx_D2D_mid_lock_seq");
    super.new(name);
  endfunction
  
  virtual task body();
    // Sub-test 3a (Cycles 1..4): D2D 2-phase packet interrupted by PHY in Lock Cycle 1
    drive_d2d_item(.en(1'b1), .data_marker(1'b1), .comp_marker(1'b0), .rand_data(1'b0)); // Cycle 1: D2D Request & Lock trigger
    drive_d2d_item(.en(1'b0), .data_marker(1'b1), .comp_marker(1'b0), .rand_data(1'b1)); // Cycle 2: Lock Cycle 1 (D2D Header; PHY interrupts)
    drive_d2d_item(.en(1'b0), .data_marker(1'b1), .comp_marker(1'b0), .rand_data(1'b1)); // Cycle 3: Lock Cycle 2 (D2D Data completes uninterrupted)
    drive_d2d_idle(1); // Cycle 4: Post-lock cooldown bubble
    
    // Sub-test 3b (Cycles 5..8): D2D 2-phase packet interrupted by PHY in Lock Cycle 2
    drive_d2d_item(.en(1'b1), .data_marker(1'b1), .comp_marker(1'b0), .rand_data(1'b0)); // Cycle 5: D2D Request & Lock trigger
    drive_d2d_item(.en(1'b0), .data_marker(1'b1), .comp_marker(1'b0), .rand_data(1'b1)); // Cycle 6: Lock Cycle 1 (D2D Header)
    drive_d2d_item(.en(1'b0), .data_marker(1'b1), .comp_marker(1'b0), .rand_data(1'b1)); // Cycle 7: Lock Cycle 2 (D2D Data; PHY interrupts)
    drive_d2d_idle(1); // Cycle 8: Post-lock cooldown bubble
    
    // Sub-test 3c (Cycles 9..12): PHY 2-phase packet interrupted by D2D in Lock Cycle 1 & 2
    drive_d2d_idle(1); // Cycle 9: Idle while PHY requests 2-phase lock
    drive_d2d_item(.en(1'b1), .data_marker(1'b0), .comp_marker(1'b0), .rand_data(1'b1)); // Cycle 10: D2D interrupts during PHY Lock Cycle 1
    drive_d2d_item(.en(1'b1), .data_marker(1'b0), .comp_marker(1'b0), .rand_data(1'b1)); // Cycle 11: D2D interrupts during PHY Lock Cycle 2
    drive_d2d_idle(1); // Cycle 12: Cooldown bubble
  endtask
endclass

`endif // PE_SBTX_D2D_MID_LOCK_SEQ_SVH