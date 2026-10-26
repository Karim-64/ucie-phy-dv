`ifndef BIT_SYNC_SBTX_SCOREBOARD_SVH
`define BIT_SYNC_SBTX_SCOREBOARD_SVH

class BIT_SYNC_SBTX_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(BIT_SYNC_SBTX_scoreboard)

  uvm_analysis_export#(BIT_SYNC_SBTX_sequence_item) sb_aexp;
  uvm_tlm_analysis_fifo#(BIT_SYNC_SBTX_sequence_item) sb_fifo;

  BIT_SYNC_SBTX_sequence_item item;
  BIT_SYNC_SBTX_sequence_item item_queue[$];

  logic[BUS_WIDTH-1:0] sync_ref;

  int pass_count = 0;
  int fail_count = 0;

  function new(string name = "BIT_SYNC_SBTX_scoreboard", uvm_component parent = null);
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
    sb_fifo.get(item);
    forever begin
      sb_fifo.get(item);
      item_queue.push_back(item);
      reference;
    end
  endtask

  task reference();
    $write("item_queue: [ ");
    foreach (item_queue[i]) $write("%b ", item_queue[i].async);
    $write("]\n");
    $display("================Transaction===================\n%s", item.convert2string);
    if(!item.rst_n) begin
      item_queue.delete;
      sync_ref = 'b0 ;
      $display("Reset signal is received\n");
      check_item;
    end
    else if(item_queue.size() > NUM_STAGES) begin
      sync_ref = item_queue.pop_front().async;
      $display("Sync reference is %b\n", sync_ref);
      check_item;
    end

  endtask

  task check_item();
    if(sync_ref !== item.sync) begin
      `uvm_error("BIT_SYNC_SBTX_SCOREBOARD", $sformatf("Mismatch between sync_ref=%b and item.sync=%b", sync_ref, item.sync))
      fail_count++;
    end
    else begin
      pass_count++;
    end
  endtask
  
  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    $display("==================================================");
    $display("         BIT_SYNC_SBTX SCOREBOARD SUMMARY         ");
    $display("==================================================");
    $display(" Successful Matches : %0d", pass_count);
    $display(" Mismatches/Errors  : %0d", fail_count);
    $display("==================================================");
    
    if (fail_count == 0 && pass_count > 0) begin
        `uvm_info(get_type_name(), "TEST PASSED", UVM_NONE)
    end else begin
        `uvm_error(get_type_name(), "TEST FAILED")
    end
  endfunction
endclass

`endif // BIT_SYNC_SBTX_SCOREBOARD_SVH
