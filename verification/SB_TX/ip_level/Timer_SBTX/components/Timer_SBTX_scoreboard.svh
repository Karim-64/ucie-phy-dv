`ifndef TIMER_SBTX_SCOREBOARD_SVH
`define TIMER_SBTX_SCOREBOARD_SVH

class Timer_SBTX_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(Timer_SBTX_scoreboard)
  uvm_analysis_export #(Timer_SBTX_sequence_item) exp;
  uvm_tlm_analysis_fifo #(Timer_SBTX_sequence_item) fifo;

  // Reference model variables
  protected int unsigned total_transactions;
  protected int unsigned match_count;
  protected int unsigned mismatch_count;

  // TODO: Add variables for reference model and checking here
  int count = 0;
  bit start_toggled = 0;

  function new(string name = "Timer_SBTX_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    total_transactions   = 0;
    match_count          = 0;
    mismatch_count       = 0;
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    exp     = new("exp", this);
    fifo    = new("fifo", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    exp.connect(fifo.analysis_export);
  endfunction

  task run_phase(uvm_phase phase);
    Timer_SBTX_sequence_item t;
    super.run_phase(phase);
    forever begin
      fifo.get(t);
      check_item(t);
    end
  endtask

  function void check_item(Timer_SBTX_sequence_item t);
    // Before the first reset item is driven, rst_n/alarm are X (nothing has
    // been applied to the DUT yet) - there is nothing meaningful to check.
    if($isunknown(t.rst_n)) return;

    total_transactions++;
    if(t.rst_n == 1'b0) begin
      count = 0;
      start_toggled = 1'b0; // reset aborts any in-flight operation
      if(t.alarm != 1'b0) begin
        mismatch_count++;
        `uvm_error("SCB_CHECK", "TEST FAILED : Alarm is asserted during reset")
      end
      else begin
        match_count++;
      end
      return;
    end
    
    if(count == NO_OF_CYCLES-1) begin
      if(t.alarm != 1'b1) begin
        mismatch_count++;
        `uvm_error("SCB_CHECK",
          $sformatf("Alarm mismatch: rst_n=%0b, start=%0b, count=%0d, expected_alarm=1, actual_alarm=%0b",
                    t.rst_n, t.start, count, t.alarm))
      end
      else begin
        match_count++;
      end
    end
    else begin
      if(t.alarm == 1'b0) begin
        match_count++;
      end
      else begin
        mismatch_count++;
        `uvm_error("SCB_CHECK",
          $sformatf("Alarm mismatch: rst_n=%0b, start=%0b, count=%0d, expected_alarm=0, actual_alarm=%0b",
                    t.rst_n, t.start, count, t.alarm))
      end
    end

    if(t.alarm == 1'b1) begin
      count = 0;
      start_toggled = 1'b0;
    end

    if(t.start == 1'b1 && count == 1'b0) begin
        start_toggled = 1'b1;
      end

      if(start_toggled == 1'b1) count++;
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);

    `uvm_info("SCB_REPORT", "============================================================", UVM_NONE)
    `uvm_info("SCB_REPORT", "            TIMER_SBTX SCOREBOARD REPORT                   ", UVM_NONE)
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

`endif // TIMER_SBTX_SCOREBOARD_SVH
