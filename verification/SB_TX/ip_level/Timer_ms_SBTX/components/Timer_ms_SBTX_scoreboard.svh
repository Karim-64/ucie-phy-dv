`ifndef TIMER_MS_SBTX_SCOREBOARD_SVH
`define TIMER_MS_SBTX_SCOREBOARD_SVH

class Timer_ms_SBTX_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(Timer_ms_SBTX_scoreboard)
  uvm_analysis_imp#(Timer_ms_SBTX_sequence_item, Timer_ms_SBTX_scoreboard) sb_aimp;

  Timer_ms_SBTX_sequence_item item, prev_item;
  logic alarm_ref, patt_alarm_ref;

  int pass_count = 0;
  int fail_count = 0;

  int counter = 0 ;
  bit counting = 0;

  function new(string name = "Timer_ms_SBTX_scoreboard", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    sb_aimp = new("sb_aimp", this);
    prev_item = null;
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  function void write(Timer_ms_SBTX_sequence_item t);
    item = t;
    if(prev_item != null) begin
      reference;

      // async reset overrides ref
      if(!item.rst_n) begin
        alarm_ref = '0;
        patt_alarm_ref = '0;
      end

      check_item;
      prev_item = new item;
    end
    prev_item = new item;
  endfunction

  function reference;
    if(!prev_item.rst_n) begin
      alarm_ref = 0;
      patt_alarm_ref = 0;
      counter = 0;
      counting = 0;
    end
    else begin 
      if(!counting && prev_item.start) begin
        counting = 1'b1; 
      end

      if(counting) begin
        counter++;
      end

      if(counter == COUNT_MAX) begin
        alarm_ref = 0;
        patt_alarm_ref = 0;
        counter = 0;
        counting = 0;
      end
      else if(counter == COUNT_MAX-1) begin
        alarm_ref = 1;
        patt_alarm_ref = 0;
      end
      else if(counter == COUNT_MAX-32) begin
        patt_alarm_ref = 1;
        alarm_ref = 0;
      end
      else begin
        alarm_ref = 0;
        patt_alarm_ref = 0;
      end
    end
  endfunction

  function check_item;
    // $display("=============Transaction=============");
    // $display(item.convert2string);
    // $display("counter=%d\n", counter);
    if(item.alarm !== alarm_ref || item.patt_alarm !== patt_alarm_ref) begin
      `uvm_error("TIMER_MS SCOREBOARD",$sformatf("patt_alarm: %b -> ref: %b\nalarm: %b -> ref: %b", item.patt_alarm, patt_alarm_ref, item.alarm, alarm_ref))
      fail_count++;
    end
    else pass_count++;
  endfunction

  function void report_phase(uvm_phase phase);
    $display("==================================================");
    $display("            TIMER_MS SCOREBOARD SUMMARY           ");
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

`endif // TIMER_MS_SBTX_SCOREBOARD_SVH
