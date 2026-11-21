`ifndef LEVEL_SYNC_SBTX_SCOREBOARD_SVH
`define LEVEL_SYNC_SBTX_SCOREBOARD_SVH

class level_sync_sbtx_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(level_sync_sbtx_scoreboard)
  uvm_analysis_imp#(level_sync_sbtx_sequence_item, level_sync_sbtx_scoreboard) sb_aimp;

  bit exp_ff1;
  bit exp_ff2;
  bit seen_reset;

  // Statistics
  int total_count;
  int pass_count;
  int fail_count;

  function new(string name = "level_sync_sbtx_scoreboard", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    sb_aimp = new("sb_aimp", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  function void write(level_sync_sbtx_sequence_item t);
    bit expected;

    if (t.RST_n === 1'b0) begin
      exp_ff1 = 1'b0;
      exp_ff2 = 1'b0;
      seen_reset = 1'b1;
      expected = 1'b0;
    end
    else begin
      expected = exp_ff2;
    end

    if (seen_reset) begin
      total_count++;
      if (t.Sync_Signal === expected) begin
        pass_count++;
        `uvm_info(get_type_name(),
                  $sformatf("PASS: %s | expected=%0b", t.convert2string(), expected), UVM_HIGH)
      end
      else begin
        fail_count++;
        `uvm_error(get_type_name(),
                   $sformatf("MISMATCH: %s | expected Sync_Signal=%0b", t.convert2string(), expected))
      end
    end

    if (t.RST_n !== 1'b0) begin
      exp_ff2 = exp_ff1;
      exp_ff1 = t.Async_Signal;
    end
  endfunction

  function void report_phase(uvm_phase phase);
    `uvm_info(get_type_name(),
              $sformatf("\n---- Level_Sync_SBTX Scoreboard Summary ----\n total   = %0d\n passed   = %0d\n failed  = %0d\n 
                        --------------------------------------------",
                        total_count, pass_count, fail_count), UVM_LOW)
  endfunction
endclass

`endif // LEVEL_SYNC_SBTX_SCOREBOARD_SVH
