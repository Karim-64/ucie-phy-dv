`ifndef DEMUX1X2_SCOREBOARD_SVH
`define DEMUX1X2_SCOREBOARD_SVH

class Demux1x2_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(Demux1x2_scoreboard)

  //uvm_analysis_imp#(Demux1x2_sequence_item, Demux1x2_scoreboard) sb_aimp;
  uvm_analysis_export #(Demux1x2_sequence_item) Demux1x2_analysis_export;
  uvm_tlm_analysis_fifo #(Demux1x2_sequence_item) Demux1x2_analysis_fifo;

  Demux1x2_sequence_item seq_item;

  // expected outputs
  logic [DATA_WIDTH-1:0] out_0_expected;
  logic [DATA_WIDTH-1:0] out_1_expected;
  int error_counter;
  int correct_counter;

  function new(string name = "Demux1x2_scoreboard", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // TODO: Instantiate components if needed
    //sb_aimp = new("sb_aimp", this);
    Demux1x2_analysis_export = new("Demux1x2_analysis_export", this);
    Demux1x2_analysis_fifo   = new("Demux1x2_analysis_fifo", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    // TODO: Add connection logic if needed
    Demux1x2_analysis_export.connect(Demux1x2_analysis_fifo.analysis_export);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    // drop first transaction
    Demux1x2_analysis_fifo.get(seq_item);
    forever begin
      Demux1x2_analysis_fifo.get(seq_item);
      reference_model(seq_item);
      check_data(seq_item);
    end
  endtask

  task reference_model(input Demux1x2_sequence_item seq_item);
    if(seq_item.sel == 1'b1)begin
      out_1_expected = seq_item.data_in;
      out_0_expected = 0;
    end
    else begin
      out_0_expected = seq_item.data_in;
      out_1_expected = 0;
    end
  endtask

  task check_data(input Demux1x2_sequence_item t);
    if ((t.out0 !== out_0_expected) || (t.out1 !== out_1_expected)) begin
        $display("Output mismatch: sel=%0b data_in=0x%0h out0 RTL/expected=0x%0h/0x%0h out1 RTL/expected=0x%0h/0x%0h",
        t.sel, t.data_in, t.out0, out_0_expected, t.out1, out_1_expected);
      error_counter++;
    end else begin
      correct_counter++;
    end
  endtask

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    $display("==================================================");
    $display("             DEMUX SCOREBOARD SUMMARY             ");
    $display("==================================================");
    $display(" Successful Matches : %0d", correct_counter);
    $display(" Mismatches/Errors  : %0d", error_counter);
    $display("==================================================");
  endfunction
endclass

`endif // DEMUX1X2_SCOREBOARD_SVH
