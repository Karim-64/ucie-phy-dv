`ifndef DEMUX_SCOREBOARD_SVH
`define DEMUX_SCOREBOARD_SVH

class DEMUX_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(DEMUX_scoreboard)
  // uvm_analysis_imp#(DEMUX_sequence_item, DEMUX_scoreboard) sb_aimp;
  uvm_analysis_export#(DEMUX_sequence_item) scb_aexp;
  uvm_tlm_analysis_fifo#(DEMUX_sequence_item) scb_fifo;

  logic [63:0] [7:0] data_0_ref;
  logic [63:0] [7:0] data_1_ref;
  
  int pass_count, error_count;

  function new(string name = "DEMUX_scoreboard", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // sb_aimp = new("sb_aimp", this);
    scb_aexp = new("scb_aexp", this);
    scb_fifo = new("scb_fifo", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    scb_aexp.connect(scb_fifo.analysis_export);
  endfunction

  // function void write(DEMUX_sequence_item t);
  //     reference(t);
  //     check_item(t);
  // endfunction

  task run_phase(uvm_phase phase);
    DEMUX_sequence_item t;
    
    // drop first transaction
    scb_fifo.get(t);

    forever begin
      scb_fifo.get(t);
      reference(t);
      check_item(t);
    end
  endtask

  function void report_phase(uvm_phase phase);
    $display("==================================================");
    $display("             DEMUX SCOREBOARD SUMMARY             ");
    $display("==================================================");
    $display(" Successful Matches : %0d", pass_count);
    $display(" Mismatches/Errors  : %0d", error_count);
    $display("==================================================");
    
    if (error_count == 0 && pass_count > 0) begin
        `uvm_info(get_type_name(), "TEST PASSED", UVM_NONE)
    end else begin
        `uvm_error(get_type_name(), "TEST FAILED")
    end
  endfunction

  function void reference(DEMUX_sequence_item seq_item);
    case (seq_item.SEL_4)
      0: begin
        data_0_ref = seq_item.lp_data;
        data_1_ref = '0;
      end
      1: begin
        data_0_ref = '0;
        data_1_ref = seq_item.lp_data;
      end
    endcase
  endfunction

  function void check_item(DEMUX_sequence_item seq_item);
    // $display("SEL_4 : %b", seq_item.SEL_4);
    // $display("Input Data : %h", seq_item.lp_data);
    // $display("Data 0 Expected : %h", data_0_ref);
    // $display("Data 0 Received : %h", seq_item.lp_data_0);
    // $display("Data 1 Expected : %h", data_1_ref);
    // $display("Data 1 Received : %h", seq_item.lp_data_1);
    if(seq_item.lp_data_0 !== data_0_ref || seq_item.lp_data_1 !== data_1_ref) begin
      // `uvm_error("DEMUX_SCOREBOARD", "DUT output does not match reference")
      error_count++;
    end else begin
      // `uvm_info("DEMUX_SCOREBOARD", "DUT output matches reference", UVM_LOW)
      pass_count++;
    end
  endfunction
endclass

`endif // DEMUX_SCOREBOARD_SVH
