`ifndef FIFO_RD_MBRX_MONITOR_SVH
`define FIFO_RD_MBRX_MONITOR_SVH

class fifo_rd_mbrx_monitor extends uvm_monitor;
  `uvm_component_utils(fifo_rd_mbrx_monitor)

  fifo_rd_mbrx_sequence_item seq_item;
  fifo_rd_mbrx_sequence_item seqr_item;
  fifo_rd_mbrx_drv_mon_cfg_obj cfg;
  uvm_analysis_imp#(fifo_rd_mbrx_sequence_item, fifo_rd_mbrx_monitor) mon_aimp;
  uvm_analysis_port#(fifo_rd_mbrx_sequence_item) mon_aport;

  function new(string name = "fifo_rd_mbrx_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(fifo_rd_mbrx_drv_mon_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("FIFO_RD_MBRX_MON", "fifo_rd_mbrx_cfg_obj not found in config_db for fifo_rd_mbrx_monitor")
    mon_aport = new("mon_aport", this);
    mon_aimp = new("mon_aimp", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  function void write(fifo_rd_mbrx_sequence_item t);
    seqr_item = fifo_rd_mbrx_sequence_item::type_id::create("seqr_item");
    seqr_item.r_rstn = t.r_rstn;
    seqr_item.r_inc = t.r_inc;
    seqr_item.sync_wr_ptr = t.sync_wr_ptr;
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      seq_item = fifo_rd_mbrx_sequence_item::type_id::create("seq_item");
      @(cfg.fifo_rd_mbrx_vif.mon_cb);
      if (seqr_item) begin
        seq_item.r_rstn <= seqr_item.r_rstn;
        seq_item.r_inc <= seqr_item.r_inc;
        seq_item.sync_wr_ptr <= seqr_item.sync_wr_ptr;
      end
      seq_item.rd_addr <= cfg.fifo_rd_mbrx_vif.mon_cb.rd_addr;
      seq_item.empty <= cfg.fifo_rd_mbrx_vif.mon_cb.empty;
      seq_item.gray_rd_ptr <= cfg.fifo_rd_mbrx_vif.mon_cb.gray_rd_ptr;
      #1step mon_aport.write(seq_item);
    end
  endtask
endclass

`endif // FIFO_RD_MBRX_MONITOR_SVH
