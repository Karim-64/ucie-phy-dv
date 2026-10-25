`ifndef SYNC_FIFO_SBRX_SCOREBOARD_SVH
`define SYNC_FIFO_SBRX_SCOREBOARD_SVH

// =============================================================================
// Design Under Test: Sync_FIFO_SBRX (Single-Clock Synchronous FIFO)
// File Name        : Sync_fifo_SBRX_scoreboard.svh
// Description      : Scoreboard implementing golden reference queue model and
//                    checking rules per Section 5 of the Verification Spec.
// =============================================================================

class Sync_fifo_SBRX_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(Sync_fifo_SBRX_scoreboard)

  // TLM connections from agent analysis port
  uvm_analysis_export #(Sync_fifo_SBRX_sequence_item) exp;
  uvm_tlm_analysis_fifo #(Sync_fifo_SBRX_sequence_item) fifo;

  // Golden Reference Model variables
  protected logic [DATA_WIDTH:0] ref_queue[$];
  protected logic [DATA_WIDTH:0] exp_rd_data;
  protected bit                  exp_empty;
  protected bit                  exp_full;

  // Registered interface stimulus for cycle-accurate modeling
  protected bit                  prev_rst;
  protected bit                  prev_wr_en;
  protected bit                  prev_rd_en;
  protected logic [DATA_WIDTH:0] prev_wr_data;

  // Transaction and checking counters
  protected int unsigned total_transactions;
  protected int unsigned match_count;
  protected int unsigned mismatch_count;
  protected int unsigned write_count;
  protected int unsigned read_count;
  protected int unsigned overflow_count;
  protected int unsigned underflow_count;

  // ---------------------------------------------------------------------------
  // Constructor
  // ---------------------------------------------------------------------------
  function new(string name = "Sync_fifo_SBRX_scoreboard", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // ---------------------------------------------------------------------------
  // Build Phase
  // ---------------------------------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    exp   = new("exp", this);
    fifo  = new("fifo", this);

    ref_queue.delete();
    exp_rd_data        = '0;
    exp_empty          = 1'b1;
    exp_full           = 1'b0;
    prev_rst           = 1'b0;
    prev_wr_en         = 1'b0;
    prev_rd_en         = 1'b0;
    prev_wr_data       = '0;
    total_transactions = 0;
    match_count        = 0;
    mismatch_count     = 0;
    write_count        = 0;
    read_count         = 0;
    overflow_count     = 0;
    underflow_count    = 0;
  endfunction

  // ---------------------------------------------------------------------------
  // Connect Phase
  // ---------------------------------------------------------------------------
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    exp.connect(fifo.analysis_export);
  endfunction

  // ---------------------------------------------------------------------------
  // Run Phase
  // ---------------------------------------------------------------------------
  task run_phase(uvm_phase phase);
    Sync_fifo_SBRX_sequence_item t;
    super.run_phase(phase);
    forever begin
      fifo.get(t);
      check_item(t);
    end
  endtask

  // ---------------------------------------------------------------------------
  // check_item: Golden Reference Model Evaluation & Output Checking (Spec Sec 5)
  // ---------------------------------------------------------------------------
  function void check_item(Sync_fifo_SBRX_sequence_item t);
    bit accept_write;
    bit accept_read;

    if (t == null) begin
      `uvm_error("SCB", "Received null transaction in scoreboard")
      return;
    end

    total_transactions++;
    
    if (t.empty !== 1'bx) begin
      // Rule 1: Empty Flag Check
      if (t.empty === exp_empty) begin
        match_count++;
      end else begin
        mismatch_count++;
        `uvm_error("SCB_FLAG_MISMATCH", $sformatf("empty flag mismatch! Occupancy: %0d, Exp: %0b, Got: %0b",
                   ref_queue.size(), exp_empty, t.empty))
      end

      // Rule 2: Full Flag Check
      if (t.full === exp_full) begin
        match_count++;
      end else begin
        mismatch_count++;
        `uvm_error("SCB_FLAG_MISMATCH", $sformatf("full flag mismatch! Occupancy: %0d, Exp: %0b, Got: %0b",
                   ref_queue.size(), exp_full, t.full))
      end

      // Rule 4 & 5: Read Data Check (valid read data or hold during idle)
      if (t.rd_data === exp_rd_data) begin
        match_count++;
      end else begin
        mismatch_count++;
        `uvm_error("SCB_DATA_MISMATCH", $sformatf("Read Data Mismatch! Expected: 0x%0h, Got: 0x%0h",
                   exp_rd_data, t.rd_data))
      end
    end

    // -------------------------------------------------------------------------
    // 2. Reference Model Update for the NEXT cycle
    // -------------------------------------------------------------------------
    if (!t.sys_rst) begin
      ref_queue.delete();
      exp_rd_data = '0;
      exp_empty   = 1'b1;
      exp_full    = 1'b0;
    end else if (prev_rst) begin
      // Synchronous operations driven on previous clock edge execute in DUT at this edge
      accept_write = prev_wr_en && (!exp_full);
      accept_read  = prev_rd_en && (!exp_empty);

      if (prev_wr_en && exp_full) begin
        overflow_count++;
        `uvm_info("SCB_INFO", "Write rejected due to FIFO full (Overflow attempt caught)", UVM_HIGH)
      end

      if (prev_rd_en && exp_empty) begin
        underflow_count++;
        `uvm_info("SCB_INFO", "Read rejected due to FIFO empty (Underflow attempt caught)", UVM_HIGH)
      end

      // Sequential Read Data update: DUT latches read data into rd_data register
      if (accept_read) begin
        read_count++;
        exp_rd_data = ref_queue.pop_front();
      end

      // Sequential Write update: DUT writes into memory
      if (accept_write) begin
        write_count++;
        ref_queue.push_back(prev_wr_data);
      end

      // Combinational Full and Empty flags updated immediately with occupancy
      exp_empty = (ref_queue.size() == 0);
      exp_full  = (ref_queue.size() == FIFO_DEPTH);
    end

    // -------------------------------------------------------------------------
    // 3. Register inputs for the next cycle
    // -------------------------------------------------------------------------
    prev_rst     = t.sys_rst;
    prev_wr_en   = t.wr_en;
    prev_rd_en   = t.rd_en;
    prev_wr_data = t.wr_data;
  endfunction

  // ---------------------------------------------------------------------------
  // Report Phase
  // ---------------------------------------------------------------------------
  function void report_phase(uvm_phase phase);
    super.report_phase(phase);

    `uvm_info("SCB_REPORT", "============================================================", UVM_NONE)
    `uvm_info("SCB_REPORT", "                Sync_fifo_SBRX SCOREBOARD REPORT            ", UVM_NONE)
    `uvm_info("SCB_REPORT", "============================================================", UVM_NONE)
    `uvm_info("SCB_REPORT", $sformatf(" Total Transactions Processed : %0d", total_transactions), UVM_NONE)
    `uvm_info("SCB_REPORT", $sformatf(" Accepted Writes              : %0d", write_count), UVM_NONE)
    `uvm_info("SCB_REPORT", $sformatf(" Accepted Reads               : %0d", read_count), UVM_NONE)
    `uvm_info("SCB_REPORT", $sformatf(" Rejected Writes (Overflow)   : %0d", overflow_count), UVM_NONE)
    `uvm_info("SCB_REPORT", $sformatf(" Rejected Reads (Underflow)   : %0d", underflow_count), UVM_NONE)
    `uvm_info("SCB_REPORT", $sformatf(" Final Reference Queue Size   : %0d", ref_queue.size()), UVM_NONE)
    `uvm_info("SCB_REPORT", "------------------------------------------------------------", UVM_NONE)
    `uvm_info("SCB_REPORT", $sformatf(" Total Checks Matched         : %0d", match_count), UVM_NONE)
    `uvm_info("SCB_REPORT", $sformatf(" Total Checks Mismatched      : %0d", mismatch_count), UVM_NONE)
    `uvm_info("SCB_REPORT", "------------------------------------------------------------", UVM_NONE)

    if (mismatch_count == 0 && total_transactions > 0) begin
      `uvm_info("SCB_REPORT", "        *** [TEST PASSED] ALL CHECKS MATCHED! ***           ", UVM_NONE)
    end else if (total_transactions == 0) begin
      `uvm_warning("SCB_REPORT", "    *** [TEST INCOMPLETE] NO TRANSACTIONS RECEIVED! ***    ")
    end else begin
      `uvm_error("SCB_REPORT", $sformatf("    *** [TEST FAILED] %0d MISMATCHES DETECTED! ***      ", mismatch_count))
    end
    `uvm_info("SCB_REPORT", "============================================================", UVM_NONE)
  endfunction

endclass

`endif // SYNC_FIFO_SBRX_SCOREBOARD_SVH
