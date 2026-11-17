`ifndef PE_SBTX_D2D_COMP_MARKER_SEQ_SVH
`define PE_SBTX_D2D_COMP_MARKER_SEQ_SVH

// =============================================================================
// Scenario 4 (D2D side): Completion Marker (Comp_Marker_D2D) Filtering & Passthrough
// - Cycles 1..3  : Uncontended 1-phase D2D packet with Comp_Marker_D2D = 1
// - Cycles 4..7  : Uncontended 2-phase D2D packet with Comp_Marker_D2D = 1
// - Cycles 8..10 : Contended D2D packet with Comp_Marker_D2D = 1 vs PHY (suppressed to 0)
// Total: 10 cycles
// =============================================================================
class pe_sbtx_D2D_comp_marker_seq extends pe_sbtx_D2D_base_seq;
  `uvm_object_utils(pe_sbtx_D2D_comp_marker_seq)
  
  function new(string name = "pe_sbtx_D2D_comp_marker_seq");
    super.new(name);
  endfunction
  
  virtual task body();
    // Step 1a (Cycles 1..3): Uncontended 1-phase D2D completion message
    drive_d2d_item(.en(1'b1), .data_marker(1'b0), .comp_marker(1'b1), .rand_data(1'b0)); // Cycle 1: Request
    drive_d2d_item(.en(1'b0), .data_marker(1'b0), .comp_marker(1'b1), .rand_data(1'b1)); // Cycle 2: Header (Comp_Marker = 1 at FIFO)
    drive_d2d_idle(1); // Cycle 3: Idle
    
    // Step 1b (Cycles 4..7): Uncontended 2-phase D2D completion message
    drive_d2d_item(.en(1'b1), .data_marker(1'b1), .comp_marker(1'b1), .rand_data(1'b0)); // Cycle 4: Request & Lock trigger
    drive_d2d_item(.en(1'b0), .data_marker(1'b1), .comp_marker(1'b1), .rand_data(1'b1)); // Cycle 5: Lock Cycle 1 Header (Comp_Marker = 1)
    drive_d2d_item(.en(1'b0), .data_marker(1'b1), .comp_marker(1'b1), .rand_data(1'b1)); // Cycle 6: Lock Cycle 2 Data (Comp_Marker = 1)
    drive_d2d_idle(1); // Cycle 7: Post-lock cooldown bubble
    
    // Step 2 (Cycles 8..10): Simultaneous contention with Comp_Marker_D2D = 1 (PHY wins, Comp_Marker forced to 0)
    drive_d2d_item(.en(1'b1), .data_marker(1'b0), .comp_marker(1'b1), .rand_data(1'b0)); // Cycle 8: Contended request
    drive_d2d_item(.en(1'b0), .data_marker(1'b0), .comp_marker(1'b1), .rand_data(1'b1)); // Cycle 9: D2D holds Comp_Marker_D2D = 1 while PHY owns channel
    drive_d2d_idle(1); // Cycle 10: Idle
  endtask
endclass

`endif // PE_SBTX_D2D_COMP_MARKER_SEQ_SVH