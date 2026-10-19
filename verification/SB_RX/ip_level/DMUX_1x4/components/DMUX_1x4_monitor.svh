`ifndef DMUX_1X4_MONITOR_SVH
`define DMUX_1X4_MONITOR_SVH

class DMUX_1x4_monitor extends uvm_monitor;
  `uvm_component_utils(DMUX_1x4_monitor)

  DMUX_1x4_sequence_item seq_item;
  DMUX_1x4_sequence_item seqr_item;
  DMUX_1x4_drv_mon_cfg_obj cfg;
  uvm_analysis_imp#(DMUX_1x4_sequence_item, DMUX_1x4_monitor) mon_aimp;
  uvm_analysis_port#(DMUX_1x4_sequence_item) mon_aport;

  function new(string name = "DMUX_1x4_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(DMUX_1x4_drv_mon_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("DMUX_1X4_MON", "DMUX_1x4_cfg_obj not found in config_db for DMUX_1x4_monitor")
    mon_aport = new("mon_aport", this);
    mon_aimp = new("mon_aimp", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  function void write(DMUX_1x4_sequence_item t);
    seqr_item = DMUX_1x4_sequence_item::type_id::create("seqr_item");
    seqr_item.din = t.din;
    seqr_item.sel = t.sel;
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      seq_item = DMUX_1x4_sequence_item::type_id::create("seq_item");
      @(cfg.DMUX_1x4_vif.mon_cb);
      if (seqr_item) begin
        seq_item.din <= seqr_item.din;
        seq_item.sel <= seqr_item.sel;
      end
      seq_item.d0 <= cfg.DMUX_1x4_vif.mon_cb.d0;
      seq_item.d1 <= cfg.DMUX_1x4_vif.mon_cb.d1;
      seq_item.d2 <= cfg.DMUX_1x4_vif.mon_cb.d2;
      seq_item.d3 <= cfg.DMUX_1x4_vif.mon_cb.d3;
      #1step mon_aport.write(seq_item);
    end
  endtask
endclass

`endif // DMUX_1X4_MONITOR_SVH
