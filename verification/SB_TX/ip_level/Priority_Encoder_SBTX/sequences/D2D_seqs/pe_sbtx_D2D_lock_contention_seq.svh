`ifndef PE_SBTX_D2D_LOCK_CONTENTION_SEQ_SVH
`define PE_SBTX_D2D_LOCK_CONTENTION_SEQ_SVH

// =============================================================================
// Scenario 7 (D2D side): Simultaneous Contention During a Lock (BOTH_ACTIVE Edge Case)
// Uses the same reactive NACK mechanism (p_sequencer.seqr_fifo) as retry_seq:
// - Sub-test 7a : D2D initiates a 2-phase locked transaction; during Lock Cycle 1,
//                 BOTH D2D_En=1 and PHY_En=1 are asserted simultaneously. D2D
//                 checks seqr_fifo for NACK (resend_req==1) and reactively
//                 re-sends until accepted.
// - Sub-test 7b : PHY initiates a 2-phase locked transaction; during Lock Cycle 1,
//                 BOTH PHY_En=1 and D2D_En=1 are asserted simultaneously. D2D
//                 checks seqr_fifo for NACK (resend_req==1) and reactively
//                 re-sends until accepted.
// =============================================================================
class pe_sbtx_D2D_lock_contention_seq extends pe_sbtx_D2D_base_seq;
  `uvm_object_utils(pe_sbtx_D2D_lock_contention_seq)

  function new(string name = "pe_sbtx_D2D_lock_contention_seq");
    super.new(name);
  endfunction

  virtual task body();
    pe_sbtx_D2D_sequence_item rsp;
    logic [DATA_WIDTH-1:0]    d2d_retry_data_7a = 64'hD2D7_AAAA_0001_0001;
    logic [DATA_WIDTH-1:0]    d2d_retry_data_7b = 64'hD2D7_BBBB_0002_0002;
    int                       attempt           = 0;

    // -------------------------------------------------------------------------
    // Sub-test 7a: D2D holds 2-phase lock while BOTH_ACTIVE (2'b11) occurs
    // -------------------------------------------------------------------------
    // Cycle 1: D2D Request & Lock trigger
    drive_d2d_item(.en(1'b1), .data_marker(1'b1), .comp_marker(1'b0), .rand_data(1'b0));

    do begin
      attempt++;
      if (attempt == 1) begin
        // Cycle 2: Lock Cycle 1 (D2D Header; D2D_En=1 & PHY_En=1 simultaneously)
        drive_d2d_item(.en(1'b1), .data_marker(1'b1), .comp_marker(1'b0), .rand_data(1'b1));
        // Cycle 3: Lock Cycle 2 (D2D Data completes)
        drive_d2d_item(.en(1'b0), .data_marker(1'b1), .comp_marker(1'b0), .rand_data(1'b1));
      end
      else begin
        `uvm_info("D2D_LOCK_CONT_SEQ", $sformatf("7a: NACK (D2D_Resend_Req=1) detected! Retry attempt #%0d", attempt - 1), UVM_LOW)
        drive_d2d_item(.en(1'b1), .data_marker(1'b0), .comp_marker(1'b0), .data('0),                .rand_data(1'b0));
        drive_d2d_item(.en(1'b0), .data_marker(1'b0), .comp_marker(1'b0), .data(d2d_retry_data_7a), .rand_data(1'b0));
      end

      // Post-lock cooldown / drain cycle + sample NACK from seqr_fifo
      drive_d2d_idle(1);
      p_sequencer.seqr_fifo.flush();
      p_sequencer.seqr_fifo.get(rsp);
    end while (rsp.resend_req === 1'b1);
    `uvm_info("D2D_LOCK_CONT_SEQ", "7a: ACK (D2D_Resend_Req=0) detected via seqr_fifo.", UVM_LOW)

    // -------------------------------------------------------------------------
    // Sub-test 7b: PHY holds 2-phase lock while BOTH_ACTIVE (2'b11) occurs
    // -------------------------------------------------------------------------
    attempt = 0;
    // Cycle 1 of 7b: Idle while PHY requests 2-phase lock
    drive_d2d_idle(1);

    do begin
      attempt++;
      if (attempt > 1) begin
        `uvm_info("D2D_LOCK_CONT_SEQ", $sformatf("7b: NACK (D2D_Resend_Req=1) detected! Retry attempt #%0d", attempt - 1), UVM_LOW)
      end

      // Drive Enable & Data, then 1 idle cycle & check seqr_fifo
      drive_d2d_item(.en(1'b1), .data_marker(1'b0), .comp_marker(1'b0), .data('0),                .rand_data(1'b0));
      drive_d2d_item(.en(1'b0), .data_marker(1'b0), .comp_marker(1'b0), .data(d2d_retry_data_7b), .rand_data(1'b0));
      drive_d2d_idle(1);

      p_sequencer.seqr_fifo.flush();
      p_sequencer.seqr_fifo.get(rsp);
    end while (rsp.resend_req === 1'b1);
    `uvm_info("D2D_LOCK_CONT_SEQ", "7b: ACK (D2D_Resend_Req=0) detected via seqr_fifo.", UVM_LOW)

    // -------------------------------------------------------------------------
    // Sub-test 7c: D2D holds 2-phase lock while BOTH_ACTIVE occurs in Lock Cycle 2
    // -------------------------------------------------------------------------
    attempt = 0;
    // Cycle 1 of 7c: D2D Request & Lock trigger
    drive_d2d_item(.en(1'b1), .data_marker(1'b1), .comp_marker(1'b0), .rand_data(1'b0));
    // Cycle 2 of 7c: Lock Cycle 1 (D2D Header, uncontended)
    drive_d2d_item(.en(1'b0), .data_marker(1'b1), .comp_marker(1'b0), .rand_data(1'b1));

    do begin
      attempt++;
      if (attempt == 1) begin
        // Cycle 3 of 7c: Lock Cycle 2 (D2D Data; D2D_En=1 & PHY_En=1 simultaneously)
        drive_d2d_item(.en(1'b1), .data_marker(1'b1), .comp_marker(1'b0), .rand_data(1'b1));
      end
      else begin
        `uvm_info("D2D_LOCK_CONT_SEQ", $sformatf("7c: NACK (D2D_Resend_Req=1) detected! Retry attempt #%0d", attempt - 1), UVM_LOW)
        drive_d2d_item(.en(1'b1), .data_marker(1'b0), .comp_marker(1'b0), .data('0),                .rand_data(1'b0));
        drive_d2d_item(.en(1'b0), .data_marker(1'b0), .comp_marker(1'b0), .data(d2d_retry_data_7a), .rand_data(1'b0));
      end

      drive_d2d_idle(1);
      p_sequencer.seqr_fifo.flush();
      p_sequencer.seqr_fifo.get(rsp);
    end while (rsp.resend_req === 1'b1);
    `uvm_info("D2D_LOCK_CONT_SEQ", "7c: ACK (D2D_Resend_Req=0) detected via seqr_fifo.", UVM_LOW)

    // -------------------------------------------------------------------------
    // Sub-test 7d: PHY holds 2-phase lock while BOTH_ACTIVE occurs in Lock Cycle 2
    // -------------------------------------------------------------------------
    attempt = 0;
    // Cycles 1..2 of 7d: Idle during PHY Req & Lock Cycle 1
    drive_d2d_idle(2);

    do begin
      attempt++;
      if (attempt > 1) begin
        `uvm_info("D2D_LOCK_CONT_SEQ", $sformatf("7d: NACK (D2D_Resend_Req=1) detected! Retry attempt #%0d", attempt - 1), UVM_LOW)
      end

      // Cycle 3 of 7d: Lock Cycle 2 (D2D_En=1 & PHY_En=1 simultaneously)
      drive_d2d_item(.en(1'b1), .data_marker(1'b0), .comp_marker(1'b0), .data('0),                .rand_data(1'b0));
      drive_d2d_item(.en(1'b0), .data_marker(1'b0), .comp_marker(1'b0), .data(d2d_retry_data_7b), .rand_data(1'b0));
      drive_d2d_idle(1);

      p_sequencer.seqr_fifo.flush();
      p_sequencer.seqr_fifo.get(rsp);
    end while (rsp.resend_req === 1'b1);
    `uvm_info("D2D_LOCK_CONT_SEQ", "7d: ACK (D2D_Resend_Req=0) detected via seqr_fifo.", UVM_LOW)
  endtask
endclass

`endif // PE_SBTX_D2D_LOCK_CONTENTION_SEQ_SVH