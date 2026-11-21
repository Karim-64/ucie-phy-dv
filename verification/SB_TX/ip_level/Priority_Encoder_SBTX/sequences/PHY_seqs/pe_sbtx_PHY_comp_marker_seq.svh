`ifndef PE_SBTX_PHY_COMP_MARKER_SEQ_SVH
`define PE_SBTX_PHY_COMP_MARKER_SEQ_SVH

// =============================================================================
// Scenario 4 (PHY side): Completion Marker (Comp_Marker_D2D) Filtering & Passthrough
// - Cycles 1..7  : PHY idle while D2D sends uncontended completion packets
// - Cycles 8..10 : PHY contends with D2D completion packet and wins (Comp_Marker = 0)
// Total: 10 cycles
// =============================================================================
class pe_sbtx_PHY_comp_marker_seq extends pe_sbtx_PHY_base_seq;
  `uvm_object_utils(pe_sbtx_PHY_comp_marker_seq)
  
  function new(string name = "pe_sbtx_PHY_comp_marker_seq");
    super.new(name);
  endfunction
  
  virtual task body();
    // Step 1 (Cycles 1..7): PHY idle while D2D sends uncontended completion packets
    drive_phy_idle(7);
    
    // Step 2 (Cycles 8..10): PHY contends with D2D completion message and wins
    drive_phy_item(.rst_n(1'b1), .en(1'b1), .data_marker(1'b0), .rand_data(1'b0)); // Cycle 8: Contended request
    drive_phy_item(.rst_n(1'b1), .en(1'b0), .data_marker(1'b0), .rand_data(1'b1)); // Cycle 9: PHY Header (Comp_Marker forced to 0)
    drive_phy_idle(1); // Cycle 10: Idle
  endtask
endclass

`endif // PE_SBTX_PHY_COMP_MARKER_SEQ_SVH