`ifndef PE_SBTX_D2D_RETRY_SEQ_SVH
`define PE_SBTX_D2D_RETRY_SEQ_SVH

// =============================================================================
// Scenario 6 (D2D side): Reactive Retry Loop (End-to-End Resend Completion)
// - Case 6a (Cycles 1..6)  : D2D sends a 1-phase packet during PHY 2-phase
//                            contention, monitors p_sequencer.seqr_fifo for
//                            NACK (resend_req == 1), and reactively re-sends
//                            the enable and data until resend_req == 0.
// - Case 6b (Cycles 7..13) : D2D initiates a 2-phase locked transfer while PHY
//                            reactively retries on NACK.
// Total: 13 cycles
// =============================================================================
class pe_sbtx_D2D_retry_seq extends pe_sbtx_D2D_base_seq;
  `uvm_object_utils(pe_sbtx_D2D_retry_seq)

  function new(string name = "pe_sbtx_D2D_retry_seq");
    super.new(name);
  endfunction

  virtual task body();
    pe_sbtx_D2D_sequence_item rsp;
    logic [DATA_WIDTH-1:0]    deferred_d2d_data = 64'hD2D0_CAFE_BABE_0001;
    int                       attempt           = 0;

    // -------------------------------------------------------------------------
    // Case 6a (Cycles 1..6): Reactive D2D Retry Loop using p_sequencer.seqr_fifo
    // -------------------------------------------------------------------------
    do begin
      attempt++;
      `uvm_info("D2D_RETRY_SEQ", $sformatf("Case 6a: D2D Attempt #%0d driving enable and data=0x%0h",
        attempt, deferred_d2d_data), UVM_MEDIUM)

      // 1. Drive Enable request cycle
      drive_d2d_item(.en(1'b1), .data_marker(1'b0), .comp_marker(1'b1), .data('0), .rand_data(1'b0));

      // 2. Drive Data payload cycle (DUT samples request on this rising edge)
      drive_d2d_item(.en(1'b0), .data_marker(1'b0), .comp_marker(1'b1), .data(deferred_d2d_data), .rand_data(1'b0));

      // 3. Drive 1 idle cycle & sample the resulting resend_req from seqr_fifo
      drive_d2d_idle(1);
      p_sequencer.seqr_fifo.flush();
      p_sequencer.seqr_fifo.get(rsp);

      if (rsp.resend_req === 1'b1) begin
        `uvm_info("D2D_RETRY_SEQ", "NACK (D2D_Resend_Req=1) detected via seqr_fifo! Retrying transaction...", UVM_LOW)
      end
      else begin
        `uvm_info("D2D_RETRY_SEQ", "ACK (D2D_Resend_Req=0) detected via seqr_fifo! Transaction accepted.", UVM_LOW)
      end
    end while (rsp.resend_req === 1'b1);

    // -------------------------------------------------------------------------
    // Case 6b (Cycles 7..13): D2D holds 2-phase lock while PHY reactively retries
    // -------------------------------------------------------------------------
    drive_d2d_item(.en(1'b1), .data_marker(1'b1), .comp_marker(1'b0), .rand_data(1'b0)); // Cycle 7: D2D 2-phase Request & Lock trigger
    drive_d2d_item(.en(1'b0), .data_marker(1'b1), .comp_marker(1'b0), .rand_data(1'b1)); // Cycle 8: Lock Cycle 1 (D2D Header; PHY Attempt #1 Req)
    drive_d2d_item(.en(1'b0), .data_marker(1'b1), .comp_marker(1'b0), .rand_data(1'b1)); // Cycle 9: Lock Cycle 2 (D2D Data; PHY Attempt #1 Data)
    drive_d2d_idle(4);                                                                    // Cycles 10..13: Idle while PHY checks NACK and completes Attempt #2
  endtask
endclass

`endif // PE_SBTX_D2D_RETRY_SEQ_SVH