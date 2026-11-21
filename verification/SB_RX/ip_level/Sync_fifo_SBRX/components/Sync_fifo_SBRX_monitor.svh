`ifndef SYNC_FIFO_SBRX_MONITOR_SVH
`define SYNC_FIFO_SBRX_MONITOR_SVH

class Sync_fifo_SBRX_monitor extends uvm_monitor;
  `uvm_component_utils(Sync_fifo_SBRX_monitor)

  Sync_fifo_SBRX_sequence_item seq_item;
  Sync_fifo_SBRX_sequence_item seqr_item;
  Sync_fifo_SBRX_drv_mon_cfg_obj cfg;
  uvm_analysis_imp#(Sync_fifo_SBRX_sequence_item, Sync_fifo_SBRX_monitor) mon_aimp;
  uvm_analysis_port#(Sync_fifo_SBRX_sequence_item) mon_aport;

  function new(string name = "Sync_fifo_SBRX_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(Sync_fifo_SBRX_drv_mon_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("SYNC_FIFO_SBRX_MON", "Sync_fifo_SBRX_cfg_obj not found in config_db for Sync_fifo_SBRX_monitor")
    mon_aport = new("mon_aport", this);
    mon_aimp = new("mon_aimp", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  function void write(Sync_fifo_SBRX_sequence_item t);
    seqr_item = Sync_fifo_SBRX_sequence_item::type_id::create("seqr_item");
    seqr_item.sys_rst = t.sys_rst;
    seqr_item.wr_en = t.wr_en;
    seqr_item.rd_en = t.rd_en;
    seqr_item.wr_data = t.wr_data;
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      seq_item = Sync_fifo_SBRX_sequence_item::type_id::create("seq_item");
      @(cfg.Sync_fifo_SBRX_vif.mon_cb);
      if (seqr_item) begin
        seq_item.sys_rst <= seqr_item.sys_rst;
        seq_item.wr_en <= seqr_item.wr_en;
        seq_item.rd_en <= seqr_item.rd_en;
        seq_item.wr_data <= seqr_item.wr_data;
      end
      seq_item.rd_data <= cfg.Sync_fifo_SBRX_vif.mon_cb.rd_data;
      seq_item.full <= cfg.Sync_fifo_SBRX_vif.mon_cb.full;
      seq_item.empty <= cfg.Sync_fifo_SBRX_vif.mon_cb.empty;
      #1step mon_aport.write(seq_item);
    end
  endtask
endclass

`endif // SYNC_FIFO_SBRX_MONITOR_SVH
