`ifndef MUX_SBTX_SCOREBOARD_SVH
`define MUX_SBTX_SCOREBOARD_SVH

class mux_sbtx_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(mux_sbtx_scoreboard)

  uvm_analysis_export   #(mux_sbtx_sequence_item) sb_aexp;
  uvm_tlm_analysis_fifo #(mux_sbtx_sequence_item) sb_fifo;

  int pass_cnt = 0;
  int fail_cnt = 0;

  logic [INPUT_WIDTH-1:0] expected_out;

  function new(string name = "mux_sbtx_scoreboard", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    sb_aexp = new("sb_aexp", this);
    sb_fifo = new("sb_fifo", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    sb_aexp.connect(sb_fifo.analysis_export);
  endfunction

  task run_phase(uvm_phase phase);
    mux_sbtx_sequence_item item;
    forever begin
      sb_fifo.get(item);
      
      // Compute expected output and check against actual DUT output
      ref_model(item);
      check_item(item);
    end
  endtask 

  task ref_model(mux_sbtx_sequence_item item);
    if (item.Mux_Sel === 1'b1)
      expected_out = item.IN_1;
    else if (item.Mux_Sel === 1'b0)
      expected_out = item.IN_0;
  endtask

  function void check_item(mux_sbtx_sequence_item item);
    if (item.OUT !== expected_out) begin
      fail_cnt++;
      `uvm_error("MUX_SCB_FAIL", $sformatf(
        "MISMATCH! Mux_Sel=%0b | IN_0=0x%0h | IN_1=0x%0h | Expected OUT=0x%0h | Actual OUT=0x%0h",
        item.Mux_Sel, item.IN_0, item.IN_1, expected_out, item.OUT))
    end else begin
      pass_cnt++;
      `uvm_info("MUX_SCB_PASS", $sformatf(
        "MATCH: Mux_Sel=%0b | IN_0=0x%0h | IN_1=0x%0h | OUT=0x%0h",
        item.Mux_Sel, item.IN_0, item.IN_1, item.OUT), UVM_HIGH)
    end
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("MUX_SCB_SUMMARY", $sformatf(
      "\n========================================\n  SCOREBOARD SUMMARY\n  Total Transactions : %0d\n  Passed             : %0d\n  Failed             : %0d\n========================================",
      (pass_cnt + fail_cnt), pass_cnt, fail_cnt), UVM_LOW)
  endfunction
endclass

`endif // MUX_SBTX_SCOREBOARD_SVH