`ifndef DMUX_1X4_SCOREBOARD_SVH
`define DMUX_1X4_SCOREBOARD_SVH

class DMUX_1x4_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(DMUX_1x4_scoreboard)
  uvm_analysis_export #(DMUX_1x4_sequence_item) exp;
  uvm_tlm_analysis_fifo #(DMUX_1x4_sequence_item) fifo;

  // TODO: Add variables for reference model and checking here
  protected int unsigned total_transactions;
  protected int unsigned match_count;
  protected int unsigned mismatch_count;

  function new(string name = "DMUX_1x4_scoreboard", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    exp   = new("exp", this);
    fifo  = new("fifo", this);
    exp.connect(fifo.analysis_export);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    // TODO: Add connection logic if needed
  endfunction

  task run_phase(uvm_phase phase);
    DMUX_1x4_sequence_item t;
    super.run_phase(phase);
    forever begin
      fifo.get(t);
      check_item(t);
    end
  endtask

  function void check_item(DMUX_1x4_sequence_item t);

    total_transactions++;

    if(t.sel == 2'b00) begin
        if(t.d0 != t.din) begin
            mismatch_count++;
            `uvm_error("DMUX_1x4_SCB", $sformatf("Mismatch detected! t.din=%b, t.d0=%b", t.din, t.d0))
        end
        else begin
            match_count++;
        end
    end else if(t.sel == 2'b01) begin
        if(t.d1 != t.din) begin
            mismatch_count++;
            `uvm_error("DMUX_1x4_SCB", $sformatf("Mismatch detected! t.din=%b, t.d1=%b", t.din, t.d1))
        end
        else begin
            match_count++;
        end
    end else if(t.sel == 2) begin
        if(t.d2 != t.din) begin
            mismatch_count++;
            `uvm_error("DMUX_1x4_SCB", $sformatf("Mismatch detected! t.din=%b, t.d2=%b", t.din, t.d2))
        end
        else begin
            match_count++;
        end
    end else if(t.sel == 3) begin
        if(t.d3 != t.din) begin
            mismatch_count++;
            `uvm_error("DMUX_1x4_SCB", $sformatf("Mismatch detected! t.din=%b, t.d3=%b", t.din, t.d3))
        end
        else begin
            match_count++;
        end
    end
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);

    `uvm_info("SCB_REPORT", "============================================================", UVM_NONE)
    `uvm_info("SCB_REPORT", "                DMUX_1x4 SCOREBOARD REPORT                  ", UVM_NONE)
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

`endif // DMUX_1X4_SCOREBOARD_SVH
