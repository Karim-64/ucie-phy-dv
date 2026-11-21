`ifndef PE_SBTX_PHY_B2B_SEQ_SVH
`define PE_SBTX_PHY_B2B_SEQ_SVH

// =============================================================================
// Scenario 5 (PHY side): Back-to-Back Traffic & The Post-Lock Bubble
// - Cycles 1..5   : PHY idle while D2D streams 4 back-to-back 1-phase packets
// - Cycles 6..9   : 3 back-to-back 1-phase PHY packets (pipelined en=1 + data)
// - Cycles 10..15 : PHY idle while D2D tests post-lock cooldown re-arbitration
// Total: 15 cycles
// =============================================================================
class pe_sbtx_PHY_b2b_seq extends pe_sbtx_PHY_base_seq;
  `uvm_object_utils(pe_sbtx_PHY_b2b_seq)
  
  function new(string name = "pe_sbtx_PHY_b2b_seq");
    super.new(name);
  endfunction
  
  virtual task body();
    // Step 1a (Cycles 1..5): PHY idle while D2D streams back-to-back 1-phase packets
    drive_phy_idle(5);
    
    // Step 1b (Cycles 6..9): Stream 3 back-to-back 1-phase PHY packets
    drive_phy_item(.rst_n(1'b1), .en(1'b1), .data_marker(1'b0), .rand_data(1'b0)); // Cycle 6: Req #1
    drive_phy_item(.rst_n(1'b1), .en(1'b1), .data_marker(1'b0), .rand_data(1'b1)); // Cycle 7: Data #1 + Req #2
    drive_phy_item(.rst_n(1'b1), .en(1'b1), .data_marker(1'b0), .rand_data(1'b1)); // Cycle 8: Data #2 + Req #3
    drive_phy_item(.rst_n(1'b1), .en(1'b0), .data_marker(1'b0), .rand_data(1'b1)); // Cycle 9: Data #3
    
    // Step 2 (Cycles 10..15): PHY idle while D2D tests post-lock cooldown bubble
    drive_phy_idle(6);

    // Step 3 (Cycles 16..20): PHY 2-phase packet followed by BOTH_ACTIVE in the post-lock cooldown bubble
    drive_phy_item(.rst_n(1'b1), .en(1'b1), .data_marker(1'b1), .rand_data(1'b0)); // Cycle 16: PHY 2-phase Req
    drive_phy_item(.rst_n(1'b1), .en(1'b0), .data_marker(1'b1), .rand_data(1'b1)); // Cycle 17: Lock Cycle 1 (Header)
    drive_phy_item(.rst_n(1'b1), .en(1'b0), .data_marker(1'b1), .rand_data(1'b1)); // Cycle 18: Lock Cycle 2 (Data)
    drive_phy_item(.rst_n(1'b1), .en(1'b1), .data_marker(1'b0), .rand_data(1'b0)); // Cycle 19: Cooldown bubble + BOTH_ACTIVE (PHY_En=1 & D2D_En=1)
    drive_phy_item(.rst_n(1'b1), .en(1'b0), .data_marker(1'b0), .rand_data(1'b1)); // Cycle 20: PHY Header granted after bubble
  endtask
endclass

`endif // PE_SBTX_PHY_B2B_SEQ_SVH