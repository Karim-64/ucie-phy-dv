`ifndef PE_SBTX_D2D_B2B_SEQ_SVH
`define PE_SBTX_D2D_B2B_SEQ_SVH

// =============================================================================
// Scenario 5 (D2D side): Back-to-Back Traffic & The Post-Lock Bubble
// - Cycles 1..5   : 4 back-to-back 1-phase D2D packets (pipelined en=1 + data)
// - Cycles 6..9   : D2D idle while PHY streams 3 back-to-back 1-phase packets
// - Cycles 10..15 : D2D 2-phase locked packet followed immediately by a new
//                   request in the post-lock cooldown cycle (Cycle 13)
// Total: 15 cycles
// =============================================================================
class pe_sbtx_D2D_b2b_seq extends pe_sbtx_D2D_base_seq;
  `uvm_object_utils(pe_sbtx_D2D_b2b_seq)
  
  function new(string name = "pe_sbtx_D2D_b2b_seq");
    super.new(name);
  endfunction
  
  virtual task body();
    // Step 1a (Cycles 1..5): Stream 4 back-to-back 1-phase D2D packets
    drive_d2d_item(.en(1'b1), .data_marker(1'b0), .comp_marker(1'b0), .rand_data(1'b0)); // Cycle 1: Req #1
    drive_d2d_item(.en(1'b1), .data_marker(1'b0), .comp_marker(1'b0), .rand_data(1'b1)); // Cycle 2: Data #1 + Req #2
    drive_d2d_item(.en(1'b1), .data_marker(1'b0), .comp_marker(1'b1), .rand_data(1'b1)); // Cycle 3: Data #2 + Req #3
    drive_d2d_item(.en(1'b1), .data_marker(1'b0), .comp_marker(1'b0), .rand_data(1'b1)); // Cycle 4: Data #3 + Req #4
    drive_d2d_item(.en(1'b0), .data_marker(1'b0), .comp_marker(1'b1), .rand_data(1'b1)); // Cycle 5: Data #4
    
    // Step 1b (Cycles 6..9): D2D idle while PHY streams back-to-back 1-phase packets
    drive_d2d_idle(4);
    
    // Step 2 (Cycles 10..15): D2D 2-phase packet followed immediately by a new request in the cooldown bubble
    drive_d2d_item(.en(1'b1), .data_marker(1'b1), .comp_marker(1'b0), .rand_data(1'b0)); // Cycle 10: 2-phase Req
    drive_d2d_item(.en(1'b0), .data_marker(1'b1), .comp_marker(1'b0), .rand_data(1'b1)); // Cycle 11: Lock Cycle 1 (Header)
    drive_d2d_item(.en(1'b0), .data_marker(1'b1), .comp_marker(1'b0), .rand_data(1'b1)); // Cycle 12: Lock Cycle 2 (Data)
    drive_d2d_item(.en(1'b1), .data_marker(1'b0), .comp_marker(1'b0), .rand_data(1'b0)); // Cycle 13: Cooldown bubble (FIFO_WR=0) + New 1-phase Req
    drive_d2d_item(.en(1'b0), .data_marker(1'b0), .comp_marker(1'b0), .rand_data(1'b1)); // Cycle 14: New 1-phase Header granted after bubble
    drive_d2d_idle(1); // Cycle 15: Idle

    // Step 3 (Cycles 16..20): PHY 2-phase packet followed by BOTH_ACTIVE in the post-lock cooldown bubble
    drive_d2d_idle(3); // Cycles 16..18: Idle during PHY 2-phase packet
    drive_d2d_item(.en(1'b1), .data_marker(1'b0), .comp_marker(1'b0), .rand_data(1'b0)); // Cycle 19: Cooldown bubble + BOTH_ACTIVE (D2D_En=1 & PHY_En=1)
    drive_d2d_idle(1); // Cycle 20: Drain cycle
  endtask
endclass

`endif // PE_SBTX_D2D_B2B_SEQ_SVH