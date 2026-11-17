`ifndef PE_SBTX_D2D_CONTENTION_SEQ_SVH
`define PE_SBTX_D2D_CONTENTION_SEQ_SVH

// =============================================================================
// Scenario 2 (D2D side): Priority & Contention Check
// - Cycles 1..3 : Simultaneous 1-phase contention (PHY_En = 1, D2D_En = 1)
// - Cycles 4..7 : Simultaneous 2-phase contention (PHY_En = 1, D2D_En = 1)
// Total: 7 cycles
// =============================================================================
class pe_sbtx_D2D_contention_seq extends pe_sbtx_D2D_base_seq;
  `uvm_object_utils(pe_sbtx_D2D_contention_seq)
  
  function new(string name = "pe_sbtx_D2D_contention_seq");
    super.new(name);
  endfunction
  
  virtual task body();
    // Sub-test 1 (Cycles 1..3): Simultaneous 1-phase request (D2D loses to PHY, gets D2D_Resend_Req = 1)
    drive_d2d_item(.en(1'b1), .data_marker(1'b0), .comp_marker(1'b0), .rand_data(1'b0)); // Cycle 1: Contended request
    drive_d2d_item(.en(1'b0), .data_marker(1'b0), .comp_marker(1'b0), .rand_data(1'b1)); // Cycle 2: D2D drives data (blocked; D2D_Resend_Req = 1)
    drive_d2d_idle(1); // Cycle 3: Idle
    
    // Sub-test 2 (Cycles 4..7): Simultaneous 2-phase request (D2D loses to PHY, gets D2D_Resend_Req = 1)
    drive_d2d_item(.en(1'b1), .data_marker(1'b1), .comp_marker(1'b0), .rand_data(1'b0)); // Cycle 4: Contended 2-phase request
    drive_d2d_item(.en(1'b0), .data_marker(1'b1), .comp_marker(1'b0), .rand_data(1'b1)); // Cycle 5: D2D Header (blocked; D2D_Resend_Req = 1)
    drive_d2d_idle(2); // Cycles 6..7: Idle during PHY Phase 2 & cooldown
  endtask
endclass

`endif // PE_SBTX_D2D_CONTENTION_SEQ_SVH