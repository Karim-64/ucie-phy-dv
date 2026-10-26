`ifndef TIMER_MS_SBTX_MONITOR_SVH
`define TIMER_MS_SBTX_MONITOR_SVH

class Timer_ms_SBTX_monitor extends uvm_monitor;
  `uvm_component_utils(Timer_ms_SBTX_monitor)

  Timer_ms_SBTX_sequence_item seq_item;
  Timer_ms_SBTX_sequence_item seqr_item;
  Timer_ms_SBTX_drv_mon_cfg_obj cfg;
  uvm_analysis_imp#(Timer_ms_SBTX_sequence_item, Timer_ms_SBTX_monitor) mon_aimp;
  uvm_analysis_port#(Timer_ms_SBTX_sequence_item) mon_aport;

  function new(string name = "Timer_ms_SBTX_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(Timer_ms_SBTX_drv_mon_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("TIMER_MS_SBTX_MON", "Timer_ms_SBTX_cfg_obj not found in config_db for Timer_ms_SBTX_monitor")
    mon_aport = new("mon_aport", this);
    mon_aimp = new("mon_aimp", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  function void write(Timer_ms_SBTX_sequence_item t);
    seqr_item = Timer_ms_SBTX_sequence_item::type_id::create("seqr_item");
    seqr_item.rst_n = t.rst_n;
    seqr_item.start = t.start;
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      seq_item = Timer_ms_SBTX_sequence_item::type_id::create("seq_item");
      @(cfg.Timer_ms_SBTX_vif.mon_cb);
      if (seqr_item) begin
        seq_item.rst_n <= seqr_item.rst_n;
        seq_item.start <= seqr_item.start;
      end
      seq_item.alarm <= cfg.Timer_ms_SBTX_vif.mon_cb.alarm;
      seq_item.patt_alarm <= cfg.Timer_ms_SBTX_vif.mon_cb.patt_alarm;
      #1step mon_aport.write(seq_item);
    end
  endtask
endclass

`endif // TIMER_MS_SBTX_MONITOR_SVH
