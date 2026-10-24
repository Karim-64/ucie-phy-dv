`ifndef SYNCHRONIZER_SBRX_SCOREBOARD_SVH
`define SYNCHRONIZER_SBRX_SCOREBOARD_SVH

class Synchronizer_SBRX_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(Synchronizer_SBRX_scoreboard)
 // uvm_analysis_imp#(Synchronizer_SBRX_sequence_item, Synchronizer_SBRX_scoreboard) sb_aimp;
  uvm_analysis_export #(Synchronizer_SBRX_sequence_item) Synchronizer_SBRX_analysis_export;
  uvm_tlm_analysis_fifo #(Synchronizer_SBRX_sequence_item) Synchronizer_SBRX_analysis_fifo;

  Synchronizer_SBRX_sequence_item seq_item;

  // expected output variable
  logic signal_dst_expected;
  // internal helper variables
  logic first_stage_ff;
  logic second_stage_ff;
  // error and correct counters
  int correct_counter;
  int error_counter;

  function new(string name = "Synchronizer_SBRX_scoreboard", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  
    //sb_aimp = new("sb_aimp", this);
    Synchronizer_SBRX_analysis_export = new("Synchronizer_SBRX_analysis_export",this);
    Synchronizer_SBRX_analysis_fifo   = new("Synchronizer_SBRX_analysis_fifo",this);

  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    Synchronizer_SBRX_analysis_export.connect(Synchronizer_SBRX_analysis_fifo.analysis_export);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    // drop first transaction
    Synchronizer_SBRX_analysis_fifo.get(seq_item);
    forever begin
      Synchronizer_SBRX_analysis_fifo.get(seq_item);
      reference_model(seq_item);
      check_data(seq_item);
    end
  endtask

  task reference_model(Synchronizer_SBRX_sequence_item seq_item);
    // reset all variables
    if(~seq_item.rst_n)begin
      signal_dst_expected = 0;
      first_stage_ff      = 0;
      second_stage_ff     = 0; 
    end
    else begin
      signal_dst_expected =  second_stage_ff;
      second_stage_ff     = first_stage_ff;
      first_stage_ff      = seq_item.signal_src; 
    end
  endtask

  task check_data(Synchronizer_SBRX_sequence_item seq_item);
    if(signal_dst_expected !== seq_item.signal_dst)begin
      $display("signal_dst=%d,signal_dst_expected=%d",seq_item.signal_dst,signal_dst_expected);
      error_counter ++;
    end
    else begin
      correct_counter ++;
    end
  endtask

  //function void write(Synchronizer_SBRX_sequence_item t);
  //  // TODO: Implement the reference model logic and output checking
  //endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    $display("==================================================");
    $display("       Synchronizer_SBRX SCOREBOARD SUMMARY       ");
    $display("==================================================");
    $display(" Successful Matches : %0d", correct_counter);
    $display(" Mismatches/Errors  : %0d", error_counter);
    $display("==================================================");
  endfunction

endclass

`endif // SYNCHRONIZER_SBRX_SCOREBOARD_SVH
