`ifndef PACKET_BUFFER_SBRX_SCOREBOARD_SVH
`define PACKET_BUFFER_SBRX_SCOREBOARD_SVH

class Packet_buffer_SBRX_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(Packet_buffer_SBRX_scoreboard)
  uvm_analysis_imp#(Packet_buffer_SBRX_sequence_item, Packet_buffer_SBRX_scoreboard) sb_aimp;

  bit [DATA_WIDTH:0] ref_q[$]; 
  bit [DATA_WIDTH:0] exp_rd_data;

  int total_count, fail_count;
  int overflow_attempts;
  int underflow_attempts;
  int simul_count;
  int wr_since_rst, wrap_count;

  function new(string name = "Packet_buffer_SBRX_scoreboard", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    sb_aimp = new("sb_aimp", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  function void write(Packet_buffer_SBRX_sequence_item t);
    bit exp_full, exp_empty, do_wr, do_rd, mismatch;

    if (t.sys_rst == 1'b0) begin
      ref_q.delete();
      exp_rd_data  = '0;
      wr_since_rst = 0;
      total_count++;
      if (t.empty !== 1'b1 || t.full !== 1'b0 || t.rd_data !== '0) begin
        fail_count++;
        `uvm_error("SB_RST", $sformatf("Bad state in reset: empty=%b full=%b rd_data=%h (expected 1/0/0)",
                                       t.empty, t.full, t.rd_data))
      end
      return;
    end

    total_count++;

    exp_full = (ref_q.size() == DEPTH);
    exp_empty = (ref_q.size() == 0);

    if (t.full != exp_full) begin
      mismatch = 1;
      `uvm_error("SB_FULL",  $sformatf("full: expected=%b actual=%b (occupancy=%0d)", exp_full, t.full, ref_q.size()))
    end
    if (t.empty != exp_empty) begin
      mismatch = 1;
      `uvm_error("SB_EMPTY", $sformatf("empty: expected=%b actual=%b (occupancy=%0d)", exp_empty, t.empty, ref_q.size()))
    end
    if (t.rd_data != exp_rd_data) begin
      mismatch = 1;
      `uvm_error("SB_RDATA", $sformatf("rd_data: expected=%h actual=%h", exp_rd_data, t.rd_data))
    end
    if (mismatch) fail_count++;

    do_wr = t.wr_en && !exp_full;
    do_rd = t.rd_en && !exp_empty;

    if (t.wr_en && exp_full)  overflow_attempts++;
    if (t.rd_en && exp_empty) underflow_attempts++;
    if (do_wr && do_rd) simul_count++;

    if (do_rd) exp_rd_data = ref_q.pop_front();
    if (do_wr) begin
      ref_q.push_back(t.wr_data);
      wr_since_rst++;
      if (wr_since_rst % (2*DEPTH) == 0) wrap_count++;
    end
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("SB_REPORT", $sformatf(
      "\n------- Packet_buffer_SBRX Scoreboard -------\n Checked cycles     : %0d\n Failed cycles      : %0d\n Overflow attempts  : %0d\n Underflow attempts : %0d\n Simultaneous wr+rd : %0d\n Pointer wraps      : %0d\n---------------------------------------------",
      total_count, fail_count, overflow_attempts, underflow_attempts, simul_count, wrap_count), UVM_LOW)

    if (overflow_attempts  == 0) `uvm_warning("SB_REPORT", "Overflow was never exercised")
    if (underflow_attempts == 0) `uvm_warning("SB_REPORT", "Underflow was never exercised")
    if (wrap_count == 0) `uvm_warning("SB_REPORT", "Pointers never wrapped: the full-flag bug can hide")

    if (total_count == 0) `uvm_warning("SB_REPORT", "No transactions were checked!")
    else if (fail_count == 0) `uvm_info("SB_REPORT", "*** TEST PASSED ***", UVM_LOW)
    else `uvm_error("SB_REPORT", "*** TEST FAILED ***")
  endfunction
endclass

`endif // PACKET_BUFFER_SBRX_SCOREBOARD_SVH
