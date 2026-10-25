`ifndef CLK_GATE_SBTX_SCOREBOARD_SVH
`define CLK_GATE_SBTX_SCOREBOARD_SVH

class clk_gate_sbtx_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(clk_gate_sbtx_scoreboard)
  uvm_analysis_imp#(clk_gate_sbtx_sequence_item, clk_gate_sbtx_scoreboard) sb_aimp;

  // TODO: Add variables for reference model and checking here

  logic effective_en;


  function new(string name = "clk_gate_sbtx_scoreboard", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // TODO: Instantiate components if needed
    sb_aimp = new("sb_aimp", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    // TODO: Add connection logic if needed
  endfunction

  function void write(clk_gate_sbtx_sequence_item t);
    // TODO: Implement the reference model logic and output checking

    logic out_clk_exp;
    if (~t.CLK) begin
      effective_en= t.Load | t.Enable;
    end

    out_clk_exp=t.CLK && effective_en;
    if (t.SBTX_CLK !== out_clk_exp) begin
         `uvm_error("CLK_GATE_GLITCH", $sformatf("Mismatch at time %0t! Inputs: CLK=%0b, Enable=%0b, Load=%0b\nInternal Latch: %0b\nExpected Output: %0b | Actual: %0b", $realtime, t.CLK, t.Enable, t.Load, effective_en, out_clk_exp, t.SBTX_CLK))
    end
  endfunction

  function void report_phase(uvm_phase phase);
    // TODO: Report scoreboard statistics (e.g. total passed/failed)
  endfunction
endclass

`endif // CLK_GATE_SBTX_SCOREBOARD_SVH
