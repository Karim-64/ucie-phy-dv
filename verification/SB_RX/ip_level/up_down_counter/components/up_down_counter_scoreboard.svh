`ifndef UP_DOWN_COUNTER_SCOREBOARD_SVH
`define UP_DOWN_COUNTER_SCOREBOARD_SVH

class up_down_counter_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(up_down_counter_scoreboard)
  uvm_analysis_export #(up_down_counter_sequence_item) exp;
  uvm_tlm_analysis_fifo #(up_down_counter_sequence_item) fifo;

  // Reference model variables
  protected int unsigned total_transactions;
  protected int unsigned match_count;
  protected int unsigned mismatch_count;
  protected logic [WIDTH-1:0] ex_count;

  function new(string name = "up_down_counter_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    total_transactions   = 0;
    match_count          = 0;
    mismatch_count       = 0;
    ex_count             = {WIDTH{1'b1}};
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
    up_down_counter_sequence_item t;
    super.run_phase(phase);
    forever begin
      fifo.get(t);
      check_item(t);
    end
  endtask

  function void check_item(up_down_counter_sequence_item t);
    if (t == null) begin
      `uvm_error("SCB_NULL_ITEM", "Received null sequence item in up_down_counter_scoreboard")
      return;
    end

    total_transactions++;

    if(!t.sys_rst) begin
      ex_count = {WIDTH{1'b1}};
      if(t.count != ex_count) begin
        mismatch_count++;
        `uvm_error("SCB_MISMATCH", $sformatf("Mismatch: Expected %0h, Got %0h", ex_count, t.count))
      end else begin
        match_count++;
      end

    end else begin
      if(t.count != ex_count) begin
        mismatch_count++;
        `uvm_error("SCB_MISMATCH", $sformatf("Mismatch: Expected %0h, Got %0h", ex_count, t.count))
      end else begin
        match_count++;
      end
      if({t.up, t.down} == 2'b10) begin
        if(ex_count < {WIDTH{1'b1}}) begin
          ex_count++;
        end
      end else if({t.up, t.down} == 2'b01) begin
        if(ex_count > 0) begin
          ex_count--;
        end
      end
    end
    
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);

    `uvm_info("SCB_REPORT", "============================================================", UVM_NONE)
    `uvm_info("SCB_REPORT", "           UP_DOWN_COUNTER SCOREBOARD REPORT                ", UVM_NONE)
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

`endif // UP_DOWN_COUNTER_SCOREBOARD_SVH
