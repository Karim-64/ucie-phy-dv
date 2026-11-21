`ifndef DEMUX_SBTX_SCOREBOARD_SVH
`define DEMUX_SBTX_SCOREBOARD_SVH

class demux_SBTX_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(demux_SBTX_scoreboard)
  uvm_analysis_imp#(demux_SBTX_sequence_item, demux_SBTX_scoreboard) sb_aimp;

  bit [DATA_WIDTH-1:0] exp_dout0, exp_dout1, exp_dout2, exp_dout3;
  int total_count;
  int pass_count;
  int fail_count;

  function new(string name = "demux_SBTX_scoreboard", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    sb_aimp = new("sb_aimp", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  function void ref_model(demux_SBTX_sequence_item t);
    exp_dout0 = (t.sel == 2'b00) ? t.din : '0;
    exp_dout1 = (t.sel == 2'b01) ? t.din : '0;
    exp_dout2 = (t.sel == 2'b10) ? t.din : '0;
    exp_dout3 = (t.sel == 2'b11) ? t.din : '0;
  endfunction

  function void write(demux_SBTX_sequence_item t);
    bit mismatch = 0;
    total_count++;

    ref_model(t);

    if (t.dout0 !== exp_dout0) begin
      mismatch = 1;
      `uvm_error("SB_MISMATCH_DOUT0",
        $sformatf("sel=%0d din=%h | Expected dout0=%h, Actual dout0=%h",
                  t.sel, t.din, exp_dout0, t.dout0))
    end
    if (t.dout1 !== exp_dout1) begin
      mismatch = 1;
      `uvm_error("SB_MISMATCH_DOUT1",
        $sformatf("sel=%0d din=%h | Expected dout1=%h, Actual dout1=%h",
                  t.sel, t.din, exp_dout1, t.dout1))
    end
    if (t.dout2 !== exp_dout2) begin
      mismatch = 1;
      `uvm_error("SB_MISMATCH_DOUT2",
        $sformatf("sel=%0d din=%h | Expected dout2=%h, Actual dout2=%h",
                  t.sel, t.din, exp_dout2, t.dout2))
    end
    if (t.dout3 !== exp_dout3) begin
      mismatch = 1;
      `uvm_error("SB_MISMATCH_DOUT3",
        $sformatf("sel=%0d din=%h | Expected dout3=%h, Actual dout3=%h",
                  t.sel, t.din, exp_dout3, t.dout3))
    end

    if (mismatch)
      fail_count++;
    else begin
      pass_count++;
      `uvm_info("SB_MATCH",
        $sformatf("sel=%0d din=%h | all outputs matched", t.sel, t.din), UVM_HIGH)
    end
  endfunction

  function void report_phase(uvm_phase phase);
  super.report_phase(phase);
    `uvm_info("SB_REPORT",
      $sformatf("\n---------- demux_SBTX Scoreboard Report ----------\n Total : %0d\n Passed: %0d\n Failed: %0d\n--------------------------------------------------",
                total_count, pass_count, fail_count), UVM_LOW)
  endfunction
endclass

`endif // DEMUX_SBTX_SCOREBOARD_SVH
