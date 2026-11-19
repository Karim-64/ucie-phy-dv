`ifndef PE_SBTX_PHY_RAND_SEQ_SVH
`define PE_SBTX_PHY_RAND_SEQ_SVH

// =============================================================================
// Randomized Stress Sequence (PHY side)
// - Sends `num_tx` (default 100) randomized 1-phase or 2-phase PHY packets.
// - Inserts a random number of idle cycles (0..4) between transactions.
// - Uses the reactive NACK mechanism (p_sequencer.seqr_fifo) to detect
//   PHY_Resend_Req == 1 and retry the exact same packet until accepted.
// =============================================================================
class pe_sbtx_PHY_rand_seq extends pe_sbtx_PHY_base_seq;
  `uvm_object_utils(pe_sbtx_PHY_rand_seq)
  
  rand int unsigned num_tx = 100;
  
  function new(string name = "pe_sbtx_PHY_rand_seq");
    super.new(name);
  endfunction
  
  virtual task body();
    pe_sbtx_PHY_sequence_item rsp;
    bit is_two_phase;
    logic[DATA_WIDTH-1 : 0] hdr_data;
    logic[DATA_WIDTH-1 : 0] pay_data;
    int unsigned idle_cycles;
    int unsigned backoff_cycles;
    int unsigned total_retries = 0;
    
    `uvm_info("PHY_RAND_SEQ", $sformatf("Starting randomized PHY sequence for %0d transactions...", num_tx), UVM_LOW)
    
    for (int i = 0; i < num_tx; i++) begin
      // Randomize packet attributes for this transaction
      is_two_phase = $urandom_range(0, 1);
      hdr_data = {$urandom(), $urandom()};
      pay_data = {$urandom(), $urandom()};
      idle_cycles = $urandom_range(0, 4);
      
      // Random idle gap before issuing the transaction
      if (idle_cycles > 0) begin
        drive_phy_idle(idle_cycles);
      end
      
      // Send transaction and reactively retry on NACK (PHY_Resend_Req == 1)
      do begin
        if (!is_two_phase) begin
          // 1-phase (header-only) packet
          drive_phy_item(.rst_n(1'b1), .en(1'b1), .data_marker(1'b0), .data('0), .rand_data(1'b0));
          drive_phy_item(.rst_n(1'b1), .en(1'b0), .data_marker(1'b0), .data(hdr_data), .rand_data(1'b0));
          drive_phy_idle(1); // Wait 1 cycle to sample resend_req
        end
        else begin
          // 2-phase (header + data) locked packet
          drive_phy_item(.rst_n(1'b1), .en(1'b1), .data_marker(1'b1), .data('0), .rand_data(1'b0));
          drive_phy_item(.rst_n(1'b1), .en(1'b0), .data_marker(1'b1), .data(hdr_data), .rand_data(1'b0));
          drive_phy_item(.rst_n(1'b1), .en(1'b0), .data_marker(1'b1), .data(pay_data), .rand_data(1'b0));
        end
        
        p_sequencer.seqr_fifo.flush();
        p_sequencer.seqr_fifo.get(rsp);
        
        if (rsp.resend_req === 1'b1) begin
          total_retries++;
          // Optional random backoff (0..2 cycles) before retrying
          backoff_cycles = $urandom_range(0, 2);
          if (backoff_cycles > 0) begin
            drive_phy_idle(backoff_cycles);
          end
        end
        else if (is_two_phase) begin
          // Accepted 2-phase packet: mandatory 1-cycle post-lock cooldown bubble
          drive_phy_idle(1);
        end
      end while (rsp.resend_req === 1'b1);
    end
    
    drive_phy_idle(2);
    `uvm_info("PHY_RAND_SEQ", $sformatf("Completed %0d PHY transactions (total retries=%0d).", num_tx, total_retries), UVM_LOW)
  endtask
endclass

`endif // PE_SBTX_PHY_RAND_SEQ_SVH