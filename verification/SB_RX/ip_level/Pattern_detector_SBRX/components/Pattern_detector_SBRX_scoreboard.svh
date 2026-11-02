`ifndef PATTERN_DETECTOR_SBRX_SCOREBOARD_SVH
`define PATTERN_DETECTOR_SBRX_SCOREBOARD_SVH

class Pattern_detector_SBRX_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(Pattern_detector_SBRX_scoreboard)
  uvm_analysis_export #(Pattern_detector_SBRX_sequence_item) exp;
  uvm_tlm_analysis_fifo #(Pattern_detector_SBRX_sequence_item) fifo;

  // Reference model variables
  protected int unsigned total_transactions;
  protected int unsigned match_count;
  protected int unsigned mismatch_count;

  logic pattern_detected_exp;
  logic sb_o_detected_exp;
  logic [DATA_WIDTH-1:0] old_pattern_data_in;
  logic old_data_valid;
  logic old_sb_sys_rst;
  logic detect_first_valid;

  logic [DATA_WIDTH-1:0] valid_pattern = 64'h5555_5555_5555_5555;
  logic [4:0] opcode  = 5'b10010;
  logic [2:0] dstid   = 3'b110;
  logic [7:0] msgcode = 8'h91;
  logic [3:0] result  = 4'b0001;

  // TODO: Add variables for reference model and checking here

  function new(string name = "Pattern_detector_SBRX_scoreboard", uvm_component parent = null);
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
    // TODO: Add connection logic if needed
    exp.connect(fifo.analysis_export);
  endfunction

  task run_phase(uvm_phase phase);
    Pattern_detector_SBRX_sequence_item t;
    super.run_phase(phase);
    forever begin
      fifo.get(t);
      do_check(t);
      evaluate(t);
      total_transactions++;
    end
  endtask

  function void do_check(Pattern_detector_SBRX_sequence_item t);
    if(!t.sb_sys_rst) begin
      if(t.pattern_detected != 1'b0 || t.sb_o_detected != 1'b0)
      begin
        mismatch_count++;
        `uvm_error("Pattern_detector_SBRX_SCB", $sformatf("Mismatch detected \nrstn=%b, data_valid=%b, pattern_data_in=%h ,pattern_detected=%b, pattern_detected_exp=%b, sb_o_detected=%b, sb_o_detected_exp=%b",old_sb_sys_rst, old_data_valid, old_pattern_data_in, t.pattern_detected,pattern_detected_exp, t.sb_o_detected, sb_o_detected_exp))
      end
      else begin
        match_count++;
        // `uvm_info("Pattern_detector_SBRX_SCB", $sformatf("Correct \nrstn=%b, data_valid=%b, pattern_data_in=%h ,pattern_detected=%b, pattern_detected_exp=%b, sb_o_detected=%b, sb_o_detected_exp=%b",old_sb_sys_rst, old_data_valid, old_pattern_data_in, t.pattern_detected,pattern_detected_exp, t.sb_o_detected, sb_o_detected_exp),UVM_LOW)
      end
    end
    else begin
      if(t.pattern_detected != pattern_detected_exp || t.sb_o_detected != sb_o_detected_exp)
      begin
        mismatch_count++;
        `uvm_error("Pattern_detector_SBRX_SCB", $sformatf("Mismatch detected \nrstn=%b, data_valid=%b, pattern_data_in=%h ,pattern_detected=%b, pattern_detected_exp=%b, sb_o_detected=%b, sb_o_detected_exp=%b",old_sb_sys_rst, old_data_valid, old_pattern_data_in, t.pattern_detected,pattern_detected_exp, t.sb_o_detected, sb_o_detected_exp))
      end
      else begin
        match_count++;
        // `uvm_info("Pattern_detector_SBRX_SCB", $sformatf("Correct \nrstn=%b, data_valid=%b, pattern_data_in=%h ,pattern_detected=%b, pattern_detected_exp=%b, sb_o_detected=%b, sb_o_detected_exp=%b",old_sb_sys_rst, old_data_valid, old_pattern_data_in, t.pattern_detected,pattern_detected_exp, t.sb_o_detected, sb_o_detected_exp),UVM_LOW)
      end
    end
  endfunction

  function void evaluate(Pattern_detector_SBRX_sequence_item t);
    if(!t.sb_sys_rst) begin
      pattern_detected_exp = 1'b0;
      sb_o_detected_exp    = 1'b0;
      old_pattern_data_in = 64'b0;
      old_data_valid = 1'b0;
      detect_first_valid = 1'b0;
    end
    else begin
      if(t.data_valid && detect_first_valid && t.pattern_data_in == valid_pattern)
      begin
        pattern_detected_exp = 1'b1;
        detect_first_valid   = 1'b0;
      end
      else if(t.data_valid && t.pattern_data_in == valid_pattern) begin
        pattern_detected_exp = 1'b0;
        detect_first_valid   = 1'b1;
      end
      else if(t.data_valid && t.pattern_data_in != valid_pattern) begin
        pattern_detected_exp = 1'b0;
        detect_first_valid   = 1'b0;
      end
      else begin
        pattern_detected_exp = 1'b0;
      end

      if(t.data_valid && t.pattern_data_in[4:0] == opcode && t.pattern_data_in[21:14] == msgcode && 
         t.pattern_data_in[40] == 1'b1 && t.pattern_data_in[58:56] == dstid && 
         t.pattern_data_in[62] == (^t.pattern_data_in[61:0]))
      begin
        sb_o_detected_exp = 1'b1;
      end
      else sb_o_detected_exp = 1'b0;

      old_pattern_data_in = t.pattern_data_in;
      old_data_valid = t.data_valid;
      old_sb_sys_rst = t.sb_sys_rst;
    end
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);

    `uvm_info("SCB_REPORT", "============================================================", UVM_NONE)
    `uvm_info("SCB_REPORT", "         Pattern_detector_SBRX SCOREBOARD REPOR             ", UVM_NONE)
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

`endif // PATTERN_DETECTOR_SBRX_SCOREBOARD_SVH
