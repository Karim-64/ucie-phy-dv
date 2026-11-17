`ifndef PE_SBTX_D2D_RESET_RECOVERY_SEQ_SVH
`define PE_SBTX_D2D_RESET_RECOVERY_SEQ_SVH

// =============================================================================
// Scenario 8 (D2D side): Mid-Transaction Asynchronous Reset (RST_n) Recovery
// - Cycles 1..4  : D2D starts a 2-phase locked transaction; RST_n=0 is asserted
//                  between the Header Phase (Cycle 2) and Data Phase (Cycle 3),
//                  immediately flushing the lock and FIFO outputs.
// - Cycles 5..10 : Post-reset recovery sanity packets (D2D 1-phase, then PHY 1-phase).
// Total: 10 cycles
// =============================================================================
class pe_sbtx_D2D_reset_recovery_seq extends pe_sbtx_D2D_base_seq;
  `uvm_object_utils(pe_sbtx_D2D_reset_recovery_seq)
  
  function new(string name = "pe_sbtx_D2D_reset_recovery_seq");
    super.new(name);
  endfunction
  
  virtual task body();
    // Step 1 (Cycles 1..4): D2D 2-phase transaction aborted mid-packet by RST_n = 0 on Cycle 3
    drive_d2d_item(.en(1'b1), .data_marker(1'b1), .comp_marker(1'b0), .rand_data(1'b0)); // Cycle 1: D2D 2-phase Request
    drive_d2d_item(.en(1'b0), .data_marker(1'b1), .comp_marker(1'b0), .rand_data(1'b1)); // Cycle 2: Lock Cycle 1 (Header Phase)
    drive_d2d_item(.en(1'b0), .data_marker(1'b1), .comp_marker(1'b0), .rand_data(1'b1)); // Cycle 3: Data Phase flushed by RST_n = 0
    drive_d2d_idle(1); // Cycle 4: Idle as RST_n de-asserts to 1
    
    // Step 2 (Cycles 5..10): Post-reset recovery check (D2D 1-phase packet, then PHY 1-phase packet)
    drive_d2d_item(.en(1'b1), .data_marker(1'b0), .comp_marker(1'b1), .rand_data(1'b0)); // Cycle 5: D2D 1-phase Request
    drive_d2d_item(.en(1'b0), .data_marker(1'b0), .comp_marker(1'b1), .rand_data(1'b1)); // Cycle 6: D2D 1-phase Header
    drive_d2d_idle(4); // Cycles 7..10: Idle while PHY sends 1-phase sanity packet

    // Step 3 (Cycles 11..17): Idle while PHY 2-phase packet is aborted mid-lock by RST_n = 0 & recovers
    drive_d2d_idle(7);
  endtask
endclass

`endif // PE_SBTX_D2D_RESET_RECOVERY_SEQ_SVH