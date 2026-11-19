`ifndef PE_SBTX_PHY_RETRY_SEQ_SVH
`define PE_SBTX_PHY_RETRY_SEQ_SVH

// =============================================================================
// Scenario 6 (PHY side): Reactive Retry Loop (End-to-End Resend Completion)
// - Case 6a (Cycles 1..6)  : PHY wins 2-phase contention while D2D reactively
//                            monitors seqr_fifo and retries on NACK.
// - Case 6b (Cycles 7..13) : PHY requests during D2D's 2-phase lock (Cycle 8),
//                            monitors p_sequencer.seqr_fifo for NACK
//                            (PHY_Resend_Req == 1), and reactively re-sends
//                            its enable and data until accepted.
// Total: 13 cycles
// =============================================================================
class pe_sbtx_PHY_retry_seq extends pe_sbtx_PHY_base_seq;
  `uvm_object_utils(pe_sbtx_PHY_retry_seq)
  
  function new(string name = "pe_sbtx_PHY_retry_seq");
    super.new(name);
  endfunction
  
  virtual task body();
    pe_sbtx_PHY_sequence_item rsp;
    logic[DATA_WIDTH-1 : 0] deferred_phy_data = 64'hF110_DEAD_BEEF_0002;
    int attempt = 0;
    
    // -------------------------------------------------------------------------
    // Case 6a (Cycles 1..6): PHY wins 2-phase contention while D2D retries
    // -------------------------------------------------------------------------
    drive_phy_item(.rst_n(1'b1), .en(1'b1), .data_marker(1'b1), .rand_data(1'b0)); // Cycle 1: PHY 2-phase Request
    drive_phy_item(.rst_n(1'b1), .en(1'b0), .data_marker(1'b1), .rand_data(1'b1)); // Cycle 2: Lock Cycle 1 (PHY Header)
    drive_phy_item(.rst_n(1'b1), .en(1'b0), .data_marker(1'b1), .rand_data(1'b1)); // Cycle 3: Lock Cycle 2 (PHY Data)
    drive_phy_idle(3); // Cycles 4..6: Idle while D2D completes Attempt #2
    
    // -------------------------------------------------------------------------
    // Case 6b (Cycles 7..13): Reactive PHY Retry Loop using p_sequencer.seqr_fifo
    // -------------------------------------------------------------------------
    drive_phy_idle(1); // Cycle 7: Idle while D2D acquires 2-phase lock
    
    do begin
      attempt++;
      `uvm_info("PHY_RETRY_SEQ", $sformatf("Case 6b: PHY Attempt #%0d driving enable and data=0x%0h", attempt, deferred_phy_data), UVM_MEDIUM)
      
      // 1. Drive Enable request cycle
      drive_phy_item(.rst_n(1'b1), .en(1'b1), .data_marker(1'b0), .data('0), .rand_data(1'b0));
      
      // 2. Drive Data payload cycle (DUT samples request on this rising edge)
      drive_phy_item(.rst_n(1'b1), .en(1'b0), .data_marker(1'b0), .data(deferred_phy_data), .rand_data(1'b0));
      
      // 3. Drive 1 idle cycle & sample the resulting resend_req from seqr_fifo
      drive_phy_idle(1);
      p_sequencer.seqr_fifo.flush();
      p_sequencer.seqr_fifo.get(rsp);
      
      if (rsp.resend_req === 1'b1) begin
        `uvm_info("PHY_RETRY_SEQ", "NACK (PHY_Resend_Req=1) detected via seqr_fifo! Retrying transaction...", UVM_LOW)
      end
      else begin
        `uvm_info("PHY_RETRY_SEQ", "ACK (PHY_Resend_Req=0) detected via seqr_fifo! Transaction accepted.", UVM_LOW)
      end
    end while (rsp.resend_req === 1'b1);
  endtask
endclass

`endif // PE_SBTX_PHY_RETRY_SEQ_SVH