`ifndef PE_SBTX_PHY_CONTENTION_SEQ_SVH
`define PE_SBTX_PHY_CONTENTION_SEQ_SVH

// =============================================================================
// Scenario 2 (PHY side): Priority & Contention Check
// - Cycles 1..3 : Simultaneous 1-phase contention (PHY_En = 1, D2D_En = 1)
// - Cycles 4..7 : Simultaneous 2-phase contention (PHY_En = 1, D2D_En = 1)
// Total: 7 cycles
// =============================================================================
class pe_sbtx_PHY_contention_seq extends pe_sbtx_PHY_base_seq;
  `uvm_object_utils(pe_sbtx_PHY_contention_seq)
  
  function new(string name = "pe_sbtx_PHY_contention_seq");
    super.new(name);
  endfunction
  
  virtual task body();
    // Sub-test 1 (Cycles 1..3): Simultaneous 1-phase request (PHY wins arbitration)
    drive_phy_item(.rst_n(1'b1), .en(1'b1), .data_marker(1'b0), .rand_data(1'b0)); // Cycle 1: Contended request
    drive_phy_item(.rst_n(1'b1), .en(1'b0), .data_marker(1'b0), .rand_data(1'b1)); // Cycle 2: PHY Header routed to FIFO
    drive_phy_idle(1); // Cycle 3: Idle
    
    // Sub-test 2 (Cycles 4..7): Simultaneous 2-phase request (PHY wins and locks for 2 cycles)
    drive_phy_item(.rst_n(1'b1), .en(1'b1), .data_marker(1'b1), .rand_data(1'b0)); // Cycle 4: Contended 2-phase request
    drive_phy_item(.rst_n(1'b1), .en(1'b0), .data_marker(1'b1), .rand_data(1'b1)); // Cycle 5: Lock Cycle 1 (PHY Header)
    drive_phy_item(.rst_n(1'b1), .en(1'b0), .data_marker(1'b1), .rand_data(1'b1)); // Cycle 6: Lock Cycle 2 (PHY Data)
    drive_phy_idle(1); // Cycle 7: Post-lock cooldown bubble
  endtask
endclass

`endif // PE_SBTX_PHY_CONTENTION_SEQ_SVH