`ifndef DEMUX_SBTX_MONITOR_SVH
`define DEMUX_SBTX_MONITOR_SVH

class demux_SBTX_monitor extends uvm_monitor;
  `uvm_component_utils(demux_SBTX_monitor)

  demux_SBTX_sequence_item seq_item;
  demux_SBTX_sequence_item seqr_item;
  demux_SBTX_drv_mon_cfg_obj cfg;
  uvm_analysis_imp#(demux_SBTX_sequence_item, demux_SBTX_monitor) mon_aimp;
  uvm_analysis_port#(demux_SBTX_sequence_item) mon_aport;

  function new(string name = "demux_SBTX_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(demux_SBTX_drv_mon_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("DEMUX_SBTX_MON", "demux_SBTX_cfg_obj not found in config_db for demux_SBTX_monitor")
    mon_aport = new("mon_aport", this);
    mon_aimp = new("mon_aimp", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  function void write(demux_SBTX_sequence_item t);
    seqr_item = demux_SBTX_sequence_item::type_id::create("seqr_item");
    seqr_item.din = t.din;
    seqr_item.sel = t.sel;
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      seq_item = demux_SBTX_sequence_item::type_id::create("seq_item");
      @(cfg.demux_SBTX_vif.mon_cb);
      if (seqr_item) begin
        seq_item.din <= seqr_item.din;
        seq_item.sel <= seqr_item.sel;
      end
      seq_item.dout0 <= cfg.demux_SBTX_vif.mon_cb.dout0;
      seq_item.dout1 <= cfg.demux_SBTX_vif.mon_cb.dout1;
      seq_item.dout2 <= cfg.demux_SBTX_vif.mon_cb.dout2;
      seq_item.dout3 <= cfg.demux_SBTX_vif.mon_cb.dout3;
      #1step mon_aport.write(seq_item);
    end
  endtask
endclass

`endif // DEMUX_SBTX_MONITOR_SVH
