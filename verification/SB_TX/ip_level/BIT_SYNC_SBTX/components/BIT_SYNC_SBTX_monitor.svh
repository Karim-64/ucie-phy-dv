`ifndef BIT_SYNC_SBTX_MONITOR_SVH
`define BIT_SYNC_SBTX_MONITOR_SVH

class BIT_SYNC_SBTX_monitor extends uvm_monitor;
  `uvm_component_utils(BIT_SYNC_SBTX_monitor)

  BIT_SYNC_SBTX_sequence_item seq_item;
  BIT_SYNC_SBTX_sequence_item seqr_item;
  BIT_SYNC_SBTX_drv_mon_cfg_obj cfg;
  uvm_analysis_imp#(BIT_SYNC_SBTX_sequence_item, BIT_SYNC_SBTX_monitor) mon_aimp;
  uvm_analysis_port#(BIT_SYNC_SBTX_sequence_item) mon_aport;

  function new(string name = "BIT_SYNC_SBTX_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(BIT_SYNC_SBTX_drv_mon_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("BIT_SYNC_SBTX_MON", "BIT_SYNC_SBTX_cfg_obj not found in config_db for BIT_SYNC_SBTX_monitor")
    mon_aport = new("mon_aport", this);
    mon_aimp = new("mon_aimp", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  function void write(BIT_SYNC_SBTX_sequence_item t);
    seqr_item = BIT_SYNC_SBTX_sequence_item::type_id::create("seqr_item");
    seqr_item.rst_n = t.rst_n;
    seqr_item.async = t.async;
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      seq_item = BIT_SYNC_SBTX_sequence_item::type_id::create("seq_item");
      @(cfg.BIT_SYNC_SBTX_vif.mon_cb);
      if (seqr_item) begin
        seq_item.rst_n <= seqr_item.rst_n;
        seq_item.async <= seqr_item.async;
      end
      seq_item.sync <= cfg.BIT_SYNC_SBTX_vif.mon_cb.sync;
      #1step mon_aport.write(seq_item);
    end
  endtask
endclass

`endif // BIT_SYNC_SBTX_MONITOR_SVH
