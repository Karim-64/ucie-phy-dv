`ifndef MUX_SBRX_SCOREBOARD_SVH
`define MUX_SBRX_SCOREBOARD_SVH

class mux_sbrx_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(mux_sbrx_scoreboard)

  uvm_analysis_export   #(mux_sbrx_sequence_item) sb_aexp;
  uvm_tlm_analysis_fifo #(mux_sbrx_sequence_item) sb_fifo;

  int pass_cnt = 0;
  int fail_cnt = 0;

  logic [INPUT_WIDTH-1:0] expected_out;

  function new(string name = "mux_sbrx_scoreboard", uvm_component parent = null);
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
    mux_sbrx_sequence_item item;
    forever begin
      sb_fifo.get(item);
      
      // Compute expected output and check against actual DUT output
      ref_model(item);
      check_item(item);
    end
  endtask 

  task ref_model(mux_sbrx_sequence_item item);
    if (item.sel === 1'b1)
      expected_out = item.in1;
    else if (item.sel === 1'b0)
      expected_out = item.in0;
  endtask

  function void check_item(mux_sbrx_sequence_item item);
    if (item.out !== expected_out) begin
      fail_cnt++;
      `uvm_error("MUX_SCB_FAIL", $sformatf(
        "MISMATCH! sel=%0b | in0=0x%0h | in1=0x%0h | Expected out=0x%0h | Actual out=0x%0h",
        item.sel, item.in0, item.in1, expected_out, item.out))
    end else begin
      pass_cnt++;
      `uvm_info("MUX_SCB_PASS", $sformatf(
        "MATCH: sel=%0b | in0=0x%0h | in1=0x%0h | out=0x%0h",
        item.sel, item.in0, item.in1, item.out), UVM_HIGH)
    end
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("MUX_SCB_SUMMARY", $sformatf(
      "\n========================================\n  SCOREBOARD SUMMARY\n  Total Transactions : %0d\n  Passed             : %0d\n  Failed             : %0d\n========================================",
      (pass_cnt + fail_cnt), pass_cnt, fail_cnt), UVM_LOW)
  endfunction
endclass

`endif // MUX_SBRX_SCOREBOARD_SVH