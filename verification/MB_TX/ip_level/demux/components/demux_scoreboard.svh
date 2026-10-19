`ifndef DEMUX_SCOREBOARD_SVH
`define DEMUX_SCOREBOARD_SVH

class demux_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(demux_scoreboard)
  uvm_analysis_export #(demux_sequence_item) sb_aexp;
  uvm_tlm_analysis_fifo #(demux_sequence_item) sb_fifo;

  int pass_count = 0;
  int fail_count = 0;

  logic [63:0][7:0] exp_data_0;
  logic [63:0][7:0] exp_data_1;



  function new(string name = "demux_scoreboard", uvm_component parent = null);
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
    demux_sequence_item item;

    super.run_phase(phase);
    // drop the first item to avoid uninitialized expected data
    sb_fifo.get(item);

    forever begin
      sb_fifo.get(item);
      // Compare received item with expected values
      ref_model(item);
      check_item(item);
    end
  endtask

  function void ref_model(demux_sequence_item item);
    // Update expected data based on the received item
    if(item.SEL_4 == 1'b0) begin
      exp_data_0 = item.lp_data;
      exp_data_1 = '0;
    end else begin
      exp_data_0 = '0;
      exp_data_1 = item.lp_data;
    end
  endfunction

  function void check_item(demux_sequence_item item);
    // Compare received item with expected values
    if (item.lp_data_0 !== exp_data_0 || item.lp_data_1 !== exp_data_1) begin
      `uvm_error("DEMUX_SCOREBOARD", $sformatf("Mismatch detected! Expected: %p, %p; Received: %p, %p",
        exp_data_0, exp_data_1, item.lp_data_0, item.lp_data_1))
      fail_count++;
    end else begin
      pass_count++;
    end
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("DEMUX_SCOREBOARD", $sformatf("Total Pass: %0d, Total Fail: %0d", pass_count, fail_count), UVM_LOW)
  endfunction
endclass

`endif // DEMUX_SCOREBOARD_SVH
