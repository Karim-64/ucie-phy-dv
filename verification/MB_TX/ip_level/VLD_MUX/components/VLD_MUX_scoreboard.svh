`ifndef VLD_MUX_SCOREBOARD_SVH
`define VLD_MUX_SCOREBOARD_SVH

class VLD_MUX_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(VLD_MUX_scoreboard)
  uvm_analysis_imp#(VLD_MUX_sequence_item, VLD_MUX_scoreboard) sb_aimp;

  bit [7:0] expected_out;   // output predicted by the reference model
  int total_count;    // total transactions checked
  int pass_count;     // matches
  int fail_count;     // mismatches

  function new(string name = "VLD_MUX_scoreboard", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    sb_aimp = new("sb_aimp", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  function bit [7:0] ref_model(VLD_MUX_sequence_item t);
    bit [7:0] exp;

    if (t.SEL_1 == 2'b00)
      exp = t.IN_0;
    else if (t.SEL_1 == 2'b01)
      exp = t.IN_1;
    else if (t.SEL_1 == 2'b10)
      exp = t.IN_2;
    else
      exp = t.IN_3;
    return exp;
  endfunction

  function void write(VLD_MUX_sequence_item t);
    total_count++;

    expected_out = ref_model(t);

    if (t.OUT !== expected_out) begin
      fail_count++;
      `uvm_error("SB_MISMATCH",
        $sformatf("SEL_1=%0d IN_0=%h IN_1=%h IN_2=%h IN_3=%h | Expected OUT=%h, Actual OUT=%h",
                  t.SEL_1, t.IN_0, t.IN_1, t.IN_2, t.IN_3, expected_out, t.OUT))
    end
    else begin
      pass_count++;
      `uvm_info("SB_MATCH",
        $sformatf("SEL_1=%0d | Expected OUT=%h, Actual OUT=%h",
                  t.SEL_1, expected_out, t.OUT), UVM_HIGH)
    end
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
      `uvm_info("SB_REPORT",
        $sformatf("\n---------- VLD_MUX Scoreboard Report ----------\n Total : %0d\n Passed: %0d\n Failed: %0d\n------------------------------------------------",
                  total_count, pass_count, fail_count), UVM_LOW)

  endfunction
endclass

`endif // VLD_MUX_SCOREBOARD_SVH
