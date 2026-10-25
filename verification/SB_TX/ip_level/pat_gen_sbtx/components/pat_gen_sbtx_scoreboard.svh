`ifndef PAT_GEN_SBTX_SCOREBOARD_SVH
`define PAT_GEN_SBTX_SCOREBOARD_SVH

class pat_gen_sbtx_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(pat_gen_sbtx_scoreboard)
  uvm_analysis_export#(pat_gen_sbtx_sequence_item) sb_aexp;
  uvm_tlm_analysis_fifo#(pat_gen_sbtx_sequence_item) sb_fifo;

  bit start_64_exp;
  bit SBTX_DATA_exp;
  bit pattern;

  int unsigned error_count;
  int unsigned pass_count;

  pat_gen_sbtx_sequence_item item;

  function new(string name = "pat_gen_sbtx_scoreboard", uvm_component parent = null);
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
    super.run_phase(phase);

    // Skip the first item to avoid uninitialized values in the scoreboard
    sb_fifo.get(item);
    forever begin
      sb_fifo.get(item);
      if(!item.RST_n) begin
        ref_model(item);
        check_item(item);
      end
      check_item(item);
      ref_model(item);
    end
  endtask

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(), $sformatf("Scoreboard summary: pass_count=%0d, error_count=%0d, final state: start_64_exp=%0b, SBTX_DATA_exp=%0b, pattern=%0b",
                pass_count, error_count, start_64_exp, SBTX_DATA_exp, pattern), UVM_MEDIUM)
  endfunction

  task ref_model(pat_gen_sbtx_sequence_item item);
    if(!item.RST_n) begin
       pattern = 1'b1;
       start_64_exp = 1'b0;
       SBTX_DATA_exp = 1'b0;
    end
    else if(!item.Patt_Gen_En) begin
       pattern = 1'b1;
       start_64_exp = 1'b0;
       SBTX_DATA_exp = 1'b0;
    end
    else begin
      start_64_exp = 1'b1;
      SBTX_DATA_exp = pattern;
      pattern = ~pattern;
    end
  endtask

  task check_item (pat_gen_sbtx_sequence_item item);
    if (item.start_64 !== start_64_exp || item.SBTX_DATA !== SBTX_DATA_exp) begin
      `uvm_error(get_type_name(), $sformatf("Scoreboard mismatch: Inputs: RST_n=%0b | Patt_Gen_En=%0b | start_64=%0b | SBTX_DATA=%0b | Expected: start_64=%0b | SBTX_DATA=%0b",
                  item.RST_n, item.Patt_Gen_En, item.start_64, item.SBTX_DATA, start_64_exp, SBTX_DATA_exp))
      error_count++;
    end
    else begin
      `uvm_info(get_type_name(), $sformatf("Scoreboard match: Inputs: RST_n=%0b | Patt_Gen_En=%0b | start_64=%0b | SBTX_DATA=%0b | Expected: start_64=%0b | SBTX_DATA=%0b",
                  item.RST_n, item.Patt_Gen_En, item.start_64, item.SBTX_DATA, start_64_exp, SBTX_DATA_exp), UVM_HIGH)
      pass_count++;
    end
  endtask
endclass

`endif // PAT_GEN_SBTX_SCOREBOARD_SVH
