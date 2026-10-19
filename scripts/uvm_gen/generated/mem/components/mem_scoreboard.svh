`ifndef MEM_SCOREBOARD_SVH
`define MEM_SCOREBOARD_SVH

class mem_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(mem_scoreboard)
  uvm_analysis_imp#(mem_sequence_item, mem_scoreboard) sb_aimp;

  // TODO: Add variables for reference model and checking here

  function new(string name = "mem_scoreboard", uvm_component parent = null);
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

  function void write(mem_sequence_item t);
    // TODO: Implement the reference model logic and output checking
  endfunction

  function void report_phase(uvm_phase phase);
    // TODO: Report scoreboard statistics (e.g. total passed/failed)
  endfunction
endclass

`endif // MEM_SCOREBOARD_SVH
