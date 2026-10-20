`ifndef DATA_MUX_SCOREBOARD_SVH
`define DATA_MUX_SCOREBOARD_SVH

class Data_MUX_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(Data_MUX_scoreboard)

  uvm_analysis_export   #(Data_MUX_sequence_item) sb_aexp;
  uvm_tlm_analysis_fifo #(Data_MUX_sequence_item) sb_fifo;

  int pass_count = 0;
  int fail_count = 0;

  logic [63:0][7:0] expected_out;

  function new(string name = "Data_MUX_scoreboard", uvm_component parent = null);
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
    Data_MUX_sequence_item item;
    sb_fifo.get(item);

    forever begin
      sb_fifo.get(item);
      ref_model(item);
      check_item(item);
    end
  endtask 

  task ref_model(Data_MUX_sequence_item item);
    if (item.SEL_5 === 1'b1)
      expected_out = item.IN_1;
    else if (item.SEL_5 === 1'b0)
      expected_out = item.IN_0;
  endtask

  function void check_item(Data_MUX_sequence_item item);
    if (item.OUT !== expected_out) begin
      fail_count++;
      `uvm_error("MUX_SCB_FAIL", $sformatf(
        "MISMATCH! Mux_Sel=%0b | IN_0=0x%0h | IN_1=0x%0h | Expected OUT=0x%0h | Actual OUT=0x%0h",
        item.SEL_5, item.IN_0, item.IN_1, expected_out, item.OUT))
    end else begin
      pass_count++;
      `uvm_info("MUX_SCB_PASS", $sformatf(
        "MATCH: Mux_Sel=%0b | IN_0=0x%0h | IN_1=0x%0h | OUT=0x%0h",
        item.SEL_5, item.IN_0, item.IN_1, item.OUT), UVM_HIGH)
    end
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("MUX_SCB_SUMMARY", $sformatf(
      "\n========================================\n  SCOREBOARD SUMMARY\n  Total Transactions : %0d\n  Passed             : %0d\n  Failed             : %0d\n========================================",
      (pass_count + fail_count), pass_count, fail_count), UVM_LOW)
  endfunction
endclass

`endif // DATA_MUX_SCOREBOARD_SVH