`ifndef SYNCHRONIZER_SCOREBOARD_SVH
`define SYNCHRONIZER_SCOREBOARD_SVH

class Synchronizer_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(Synchronizer_scoreboard)
  uvm_analysis_export #(Synchronizer_sequence_item) exp;
  uvm_tlm_analysis_fifo #(Synchronizer_sequence_item) fifo;

  // ---------------------------------------------------------------------------
  // Reference Model State Registers (2-Stage Flip-Flop Synchronizer)
  // ---------------------------------------------------------------------------
  // stage 1: latches signal_src on posedge clk_dst
  // stage 2: latches stage 1 on posedge clk_dst and produces signal_dst
  protected bit sync_stage1;
  protected bit sync_stage2;



  // ---------------------------------------------------------------------------
  // Scoreboard Verification Statistics
  // ---------------------------------------------------------------------------
  protected int unsigned total_transactions;
  protected int unsigned match_count;
  protected int unsigned mismatch_count;

  function new(string name = "Synchronizer_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    sync_stage1          = 1'b0;
    sync_stage2          = 1'b0;
    total_transactions   = 0;
    match_count          = 0;
    mismatch_count       = 0;
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    exp   = new("exp", this);
    fifo  = new("fifo", this);
    exp.connect(fifo.analysis_export);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    Synchronizer_sequence_item t;
    super.run_phase(phase);
    forever begin
      fifo.get(t);
      check_item(t);
    end
  endtask

  // ---------------------------------------------------------------------------
  // Transaction checking implementation
  // ---------------------------------------------------------------------------
  function void check_item(Synchronizer_sequence_item t);
    bit expected_dst;

    if (t == null) begin
      `uvm_error("SCB_NULL_ITEM", "Received null sequence item in Synchronizer_scoreboard")
      return;
    end

    total_transactions++;

    if(!t.rst_n) begin
        sync_stage1 = 1'b0;
        sync_stage2 = 1'b0;
        expected_dst = 1'b0;
    end else begin
        expected_dst = sync_stage2;
        sync_stage2 = sync_stage1;
        sync_stage1 = t.signal_src;

        if(expected_dst != t.signal_dst) begin
            mismatch_count++;
            `uvm_error("SYNCHRONIZER_SCB", $sformatf("Mismatch detected! t.signal_src=%b, t.signal_dst=%b, expected_dst=%b", t.signal_src, t.signal_dst, expected_dst))
        end
        else begin
            match_count++;
        end
    end
  endfunction

  // ---------------------------------------------------------------------------
  // Report Phase - summarize pass/fail results
  // ---------------------------------------------------------------------------
  function void report_phase(uvm_phase phase);
    super.report_phase(phase);

    `uvm_info("SCB_REPORT", "============================================================", UVM_NONE)
    `uvm_info("SCB_REPORT", "              SYNCHRONIZER SCOREBOARD REPORT                ", UVM_NONE)
    `uvm_info("SCB_REPORT", "============================================================", UVM_NONE)
    `uvm_info("SCB_REPORT", $sformatf(" Total Transactions Received : %0d", total_transactions), UVM_NONE)
    `uvm_info("SCB_REPORT", $sformatf(" Total Matches               : %0d", match_count), UVM_NONE)
    `uvm_info("SCB_REPORT", $sformatf(" Total Mismatches            : %0d", mismatch_count), UVM_NONE)
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

`endif // SYNCHRONIZER_SCOREBOARD_SVH
