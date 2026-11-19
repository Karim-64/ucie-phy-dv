`ifndef CREDITS_HANDLER_SBTX_SCOREBOARD_SVH
`define CREDITS_HANDLER_SBTX_SCOREBOARD_SVH

class Credits_Handler_SBTX_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(Credits_Handler_SBTX_scoreboard)
  uvm_analysis_export#(Credits_Handler_SBTX_sequence_item) sb_aexp;
  uvm_tlm_analysis_fifo#(Credits_Handler_SBTX_sequence_item) sb_fifo;

  Credits_Handler_SBTX_sequence_item item, prev_item;

  int pass_count = 0;
  int fail_count = 0;
  int counter = 0;

  logic prev_comp_sent = 0;
  logic pl_cfg_crd_ref = 0;

  function new(string name = "Credits_Handler_SBTX_scoreboard", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    sb_aexp = new("sb_aexp", this);
    sb_fifo = new("sb_fifo", this);
    prev_item = null;
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    sb_aexp.connect(sb_fifo.analysis_export);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    sb_fifo.get(prev_item);
    forever begin
      if(prev_item != null) begin
        sb_fifo.get(item);
        reference;
        if(!item.rst_n) counter = '0;
        check_item;
      end
      prev_comp_sent = prev_item.comp_sent;
      prev_item = new item;
    end
  endtask

  function void reference;
    if(!prev_item.rst_n) counter = '0;
    else begin
      if(prev_item.D2D_phy_marker & ~prev_item.data_marker & ~prev_item.comp_marker) counter++;
      if(prev_item.UIE) counter++;
      if(prev_item.credit) counter++;
      if(prev_item.comp_sent & ~prev_comp_sent) counter++;
    end
  endfunction

  function void check_item;
    if(counter > 0) begin
      pl_cfg_crd_ref = 1;
      counter--;
    end
    else pl_cfg_crd_ref = 0;

    `uvm_info(get_type_name(), $sformatf("\n===========Transaction===========\ncounter = %0d\nrst_n: %b\nD2D_phy_marker: %b\ndata_marker: %b\ncomp_marker: %b\nUIE: %b\ncredit: %b\ncomp_sent: %b\npl_cfg_crd: %b\npl_cfg_crd_ref: %b",
      counter, item.rst_n, prev_item.D2D_phy_marker, prev_item.data_marker, prev_item.comp_marker, prev_item.UIE, prev_item.credit, prev_item.comp_sent, item.pl_cfg_crd, pl_cfg_crd_ref), UVM_HIGH)

    if(item.pl_cfg_crd !== pl_cfg_crd_ref) begin
      fail_count++;
      `uvm_error(get_type_name(), "failed")
    end
    else begin 
      pass_count++;
      `uvm_info("get_type_name()", "passed", UVM_HIGH)
    end
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(), $sformatf("\n==================================================\n   Credits_Handler_SYNC_SBTX SCOREBOARD SUMMARY   \n==================================================\n Successful Matches : %0d\n Mismatches/Errors  : %0d\n==================================================", pass_count, fail_count), UVM_NONE)
    
    if (fail_count == 0 && pass_count > 0) begin
        `uvm_info(get_type_name(), "TEST PASSED", UVM_NONE)
    end else begin
        `uvm_error(get_type_name(), "TEST FAILED")
    end
  endfunction
endclass

`endif // CREDITS_HANDLER_SBTX_SCOREBOARD_SVH