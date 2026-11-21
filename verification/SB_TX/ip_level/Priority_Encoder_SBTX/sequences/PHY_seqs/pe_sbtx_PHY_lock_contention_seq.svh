`ifndef PE_SBTX_PHY_LOCK_CONTENTION_SEQ_SVH
`define PE_SBTX_PHY_LOCK_CONTENTION_SEQ_SVH

// =============================================================================
// Scenario 7 (PHY side): Simultaneous Contention During a Lock (BOTH_ACTIVE Edge Case)
// Uses the same reactive NACK mechanism (p_sequencer.seqr_fifo) as retry_seq:
// - Sub-test 7a : D2D initiates a 2-phase locked transaction; during Lock Cycle 1,
//                 BOTH D2D_En=1 and PHY_En=1 are asserted simultaneously. PHY
//                 checks seqr_fifo for NACK (resend_req==1) and reactively
//                 re-sends if rejected.
// - Sub-test 7b : PHY initiates a 2-phase locked transaction; during Lock Cycle 1,
//                 BOTH PHY_En=1 and D2D_En=1 are asserted simultaneously. PHY
//                 checks seqr_fifo for NACK (resend_req==1) and stays idle
//                 while D2D completes its retry.
// =============================================================================
class pe_sbtx_PHY_lock_contention_seq extends pe_sbtx_PHY_base_seq;
  `uvm_object_utils(pe_sbtx_PHY_lock_contention_seq)

  function new(string name = "pe_sbtx_PHY_lock_contention_seq");
    super.new(name);
  endfunction

  virtual task body();
    pe_sbtx_PHY_sequence_item rsp;
    logic [DATA_WIDTH-1:0]    phy_retry_data_7a = 64'hF117_AAAA_0001_0001;
    logic [DATA_WIDTH-1:0]    phy_retry_data_7b = 64'hF117_BBBB_0002_0002;
    int                       attempt           = 0;

    // -------------------------------------------------------------------------
    // Sub-test 7a: D2D holds 2-phase lock while BOTH_ACTIVE (2'b11) occurs
    // -------------------------------------------------------------------------
    // Cycle 1: Idle while D2D acquires lock
    drive_phy_idle(1);

    do begin
      attempt++;
      if (attempt > 1) begin
        `uvm_info("PHY_LOCK_CONT_SEQ", $sformatf("7a: NACK (PHY_Resend_Req=1) detected! Retry attempt #%0d", attempt - 1), UVM_LOW)
      end

      // Drive Enable & Data, then 1 idle cycle & check seqr_fifo
      drive_phy_item(.rst_n(1'b1), .en(1'b1), .data_marker(1'b0), .data('0),                .rand_data(1'b0));
      drive_phy_item(.rst_n(1'b1), .en(1'b0), .data_marker(1'b0), .data(phy_retry_data_7a), .rand_data(1'b0));
      drive_phy_idle(1);

      p_sequencer.seqr_fifo.flush();
      p_sequencer.seqr_fifo.get(rsp);
    end while (rsp.resend_req === 1'b1);
    `uvm_info("PHY_LOCK_CONT_SEQ", "7a: ACK (PHY_Resend_Req=0) detected via seqr_fifo.", UVM_LOW)

    // Keep PHY aligned (3 cycles) while D2D completes its 7a reactive retry
    drive_phy_idle(3);

    // -------------------------------------------------------------------------
    // Sub-test 7b: PHY holds 2-phase lock while BOTH_ACTIVE (2'b11) occurs
    // -------------------------------------------------------------------------
    attempt = 0;
    // Cycle 1 of 7b: PHY Request & Lock trigger
    drive_phy_item(.rst_n(1'b1), .en(1'b1), .data_marker(1'b1), .rand_data(1'b0));

    do begin
      attempt++;
      if (attempt == 1) begin
        // Cycle 2 of 7b: Lock Cycle 1 (PHY Header; PHY_En=1 & D2D_En=1 simultaneously)
        drive_phy_item(.rst_n(1'b1), .en(1'b1), .data_marker(1'b1), .rand_data(1'b1));
        // Cycle 3 of 7b: Lock Cycle 2 (PHY Data completes)
        drive_phy_item(.rst_n(1'b1), .en(1'b0), .data_marker(1'b1), .rand_data(1'b1));
      end
      else begin
        `uvm_info("PHY_LOCK_CONT_SEQ", $sformatf("7b: NACK (PHY_Resend_Req=1) detected! Retry attempt #%0d", attempt - 1), UVM_LOW)
        drive_phy_item(.rst_n(1'b1), .en(1'b1), .data_marker(1'b0), .data('0),                .rand_data(1'b0));
        drive_phy_item(.rst_n(1'b1), .en(1'b0), .data_marker(1'b0), .data(phy_retry_data_7b), .rand_data(1'b0));
      end

      // Post-lock cooldown / drain cycle + sample NACK from seqr_fifo
      drive_phy_idle(1);
      p_sequencer.seqr_fifo.flush();
      p_sequencer.seqr_fifo.get(rsp);
    end while (rsp.resend_req === 1'b1);
    `uvm_info("PHY_LOCK_CONT_SEQ", "7b: ACK (PHY_Resend_Req=0) detected via seqr_fifo.", UVM_LOW)

    // Keep PHY aligned (3 cycles) while D2D completes its 7b reactive retry
    drive_phy_idle(3);

    // -------------------------------------------------------------------------
    // Sub-test 7c: D2D holds 2-phase lock while BOTH_ACTIVE occurs in Lock Cycle 2
    // -------------------------------------------------------------------------
    attempt = 0;
    // Cycles 1..2 of 7c: Idle during D2D Req & Lock Cycle 1
    drive_phy_idle(2);

    do begin
      attempt++;
      if (attempt > 1) begin
        `uvm_info("PHY_LOCK_CONT_SEQ", $sformatf("7c: NACK (PHY_Resend_Req=1) detected! Retry attempt #%0d", attempt - 1), UVM_LOW)
      end

      // Cycle 3 of 7c: Lock Cycle 2 (PHY_En=1 & D2D_En=1 simultaneously)
      drive_phy_item(.rst_n(1'b1), .en(1'b1), .data_marker(1'b0), .data('0),                .rand_data(1'b0));
      drive_phy_item(.rst_n(1'b1), .en(1'b0), .data_marker(1'b0), .data(phy_retry_data_7a), .rand_data(1'b0));
      drive_phy_idle(1);

      p_sequencer.seqr_fifo.flush();
      p_sequencer.seqr_fifo.get(rsp);
    end while (rsp.resend_req === 1'b1);
    `uvm_info("PHY_LOCK_CONT_SEQ", "7c: ACK (PHY_Resend_Req=0) detected via seqr_fifo.", UVM_LOW)

    // Keep PHY aligned (2 cycles) while D2D completes its 7c reactive retry
    drive_phy_idle(2);

    // -------------------------------------------------------------------------
    // Sub-test 7d: PHY holds 2-phase lock while BOTH_ACTIVE occurs in Lock Cycle 2
    // -------------------------------------------------------------------------
    attempt = 0;
    // Cycle 1 of 7d: PHY Request & Lock trigger
    drive_phy_item(.rst_n(1'b1), .en(1'b1), .data_marker(1'b1), .rand_data(1'b0));
    // Cycle 2 of 7d: Lock Cycle 1 (PHY Header, uncontended)
    drive_phy_item(.rst_n(1'b1), .en(1'b0), .data_marker(1'b1), .rand_data(1'b1));

    do begin
      attempt++;
      if (attempt == 1) begin
        // Cycle 3 of 7d: Lock Cycle 2 (PHY Data; PHY_En=1 & D2D_En=1 simultaneously)
        drive_phy_item(.rst_n(1'b1), .en(1'b1), .data_marker(1'b1), .rand_data(1'b1));
      end
      else begin
        `uvm_info("PHY_LOCK_CONT_SEQ", $sformatf("7d: NACK (PHY_Resend_Req=1) detected! Retry attempt #%0d", attempt - 1), UVM_LOW)
        drive_phy_item(.rst_n(1'b1), .en(1'b1), .data_marker(1'b0), .data('0),                .rand_data(1'b0));
        drive_phy_item(.rst_n(1'b1), .en(1'b0), .data_marker(1'b0), .data(phy_retry_data_7b), .rand_data(1'b0));
      end

      drive_phy_idle(1);
      p_sequencer.seqr_fifo.flush();
      p_sequencer.seqr_fifo.get(rsp);
    end while (rsp.resend_req === 1'b1);
    `uvm_info("PHY_LOCK_CONT_SEQ", "7d: ACK (PHY_Resend_Req=0) detected via seqr_fifo.", UVM_LOW)

    // Keep PHY aligned (4 cycles) while D2D completes its 7d reactive retry
    drive_phy_idle(4);
  endtask
endclass

`endif // PE_SBTX_PHY_LOCK_CONTENTION_SEQ_SVH