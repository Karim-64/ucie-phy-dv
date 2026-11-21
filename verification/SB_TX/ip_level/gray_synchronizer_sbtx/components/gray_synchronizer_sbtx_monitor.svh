`ifndef GRAY_SYNCHRONIZER_SBTX_MONITOR_SVH
`define GRAY_SYNCHRONIZER_SBTX_MONITOR_SVH

class gray_synchronizer_sbtx_monitor extends uvm_monitor;
  `uvm_component_utils(gray_synchronizer_sbtx_monitor)

  gray_synchronizer_sbtx_sequence_item seq_item;
  gray_synchronizer_sbtx_sequence_item seqr_item;
  gray_synchronizer_sbtx_drv_mon_cfg_obj cfg;
  uvm_analysis_imp#(gray_synchronizer_sbtx_sequence_item, gray_synchronizer_sbtx_monitor) mon_aimp;
  uvm_analysis_port#(gray_synchronizer_sbtx_sequence_item) mon_aport;

  function new(string name = "gray_synchronizer_sbtx_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(gray_synchronizer_sbtx_drv_mon_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("GRAY_SYNCHRONIZER_SBTX_MON", "gray_synchronizer_sbtx_cfg_obj not found in config_db for gray_synchronizer_sbtx_monitor")
    mon_aport = new("mon_aport", this);
    mon_aimp = new("mon_aimp", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  function void write(gray_synchronizer_sbtx_sequence_item t);
    seqr_item = gray_synchronizer_sbtx_sequence_item::type_id::create("seqr_item");
    seqr_item.RST_n = t.RST_n;
    seqr_item.Async_Data = t.Async_Data;
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      seq_item = gray_synchronizer_sbtx_sequence_item::type_id::create("seq_item");
      @(cfg.gray_synchronizer_sbtx_vif.mon_cb);
      if (seqr_item) begin
        seq_item.RST_n <= seqr_item.RST_n;
        seq_item.Async_Data <= seqr_item.Async_Data;
      end
      seq_item.Sync_Data <= cfg.gray_synchronizer_sbtx_vif.mon_cb.Sync_Data;
      #1step mon_aport.write(seq_item);
    end
  endtask
endclass

`endif // GRAY_SYNCHRONIZER_SBTX_MONITOR_SVH
