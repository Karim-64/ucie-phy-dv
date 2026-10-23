`ifndef LEVEL_SYNC_SBTX_MONITOR_SVH
`define LEVEL_SYNC_SBTX_MONITOR_SVH

class level_sync_sbtx_monitor extends uvm_monitor;
  `uvm_component_utils(level_sync_sbtx_monitor)

  level_sync_sbtx_sequence_item seq_item;
  level_sync_sbtx_sequence_item seqr_item;
  level_sync_sbtx_drv_mon_cfg_obj cfg;
  uvm_analysis_imp#(level_sync_sbtx_sequence_item, level_sync_sbtx_monitor) mon_aimp;
  uvm_analysis_port#(level_sync_sbtx_sequence_item) mon_aport;

  function new(string name = "level_sync_sbtx_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(level_sync_sbtx_drv_mon_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("LEVEL_SYNC_SBTX_MON", "level_sync_sbtx_cfg_obj not found in config_db for level_sync_sbtx_monitor")
    mon_aport = new("mon_aport", this);
    mon_aimp = new("mon_aimp", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  function void write(level_sync_sbtx_sequence_item t);
    seqr_item = level_sync_sbtx_sequence_item::type_id::create("seqr_item");
    seqr_item.RST_n = t.RST_n;
    seqr_item.Async_Signal = t.Async_Signal;
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      seq_item = level_sync_sbtx_sequence_item::type_id::create("seq_item");
      @(cfg.level_sync_sbtx_vif.mon_cb);
      if (seqr_item) begin
        seq_item.RST_n <= seqr_item.RST_n;
        seq_item.Async_Signal <= seqr_item.Async_Signal;
      end
      seq_item.Sync_Signal <= cfg.level_sync_sbtx_vif.mon_cb.Sync_Signal;
      #1step mon_aport.write(seq_item);
    end
  endtask
endclass

`endif // LEVEL_SYNC_SBTX_MONITOR_SVH
