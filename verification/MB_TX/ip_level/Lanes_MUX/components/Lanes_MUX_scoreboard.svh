`ifndef LANES_MUX_SCOREBOARD_SVH
`define LANES_MUX_SCOREBOARD_SVH

class Lanes_MUX_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(Lanes_MUX_scoreboard)
  uvm_analysis_imp#(Lanes_MUX_sequence_item, Lanes_MUX_scoreboard) sb_aimp;

  // TODO: Add variables for reference model and checking here

  int err = 0, pass = 0;

  function new(string name = "Lanes_MUX_scoreboard", uvm_component parent = null);
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

  function void write(Lanes_MUX_sequence_item t);
    if (t.SEL_2) begin
      if (t.IN_1 != t.OUT) begin
        `uvm_error ("LANES_MUX_SCOREBOARD", "ERROR! -- SEL = 1, INPUT_1 not equal OUT")
        `uvm_info ("LANES_MUX_SCOREBOARD", t.convert2string, UVM_MEDIUM)
        err ++;
      end
      else begin
        `uvm_info ("LANES_MUX_SCOREBOARD", "PASS! -- INPUT_1 equal OUT", UVM_HIGH)
        pass ++;
      end
    end
    else begin
      if (t.IN_0 != t.OUT) begin
        `uvm_error ("LANES_MUX_SCOREBOARD", "ERROR! -- SEL = 0, INPUT_0 not equal OUT")
        `uvm_info ("LANES_MUX_SCOREBOARD", t.convert2string, UVM_MEDIUM)
        err ++;
      end
      else begin
        `uvm_info ("LANES_MUX_SCOREBOARD", "PASS! -- INPUT_0 equal OUT", UVM_HIGH)
        pass ++;
      end
    end
  endfunction

  function void report_phase(uvm_phase phase);
    // TODO: Report scoreboard statistics (e.g. total passed/failed)
        `uvm_info ("LANES_MUX_SCOREBOARD", $sformatf ("Total Error: %d, Total Pass: %d", err, pass), UVM_LOW)
  endfunction
endclass

`endif // LANES_MUX_SCOREBOARD_SVH
