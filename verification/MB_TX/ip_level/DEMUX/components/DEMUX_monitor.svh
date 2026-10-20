`ifndef DEMUX_MONITOR_SVH
`define DEMUX_MONITOR_SVH

class DEMUX_monitor extends uvm_monitor;
  `uvm_component_utils(DEMUX_monitor)

  DEMUX_sequence_item seq_item;
  DEMUX_sequence_item seqr_item;
  DEMUX_drv_mon_cfg_obj cfg;
  uvm_analysis_imp#(DEMUX_sequence_item, DEMUX_monitor) mon_aimp;
  uvm_analysis_port#(DEMUX_sequence_item) mon_aport;

  function new(string name = "DEMUX_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(DEMUX_drv_mon_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("DEMUX_MON", "DEMUX_cfg_obj not found in config_db for DEMUX_monitor")
    mon_aport = new("mon_aport", this);
    mon_aimp = new("mon_aimp", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  function void write(DEMUX_sequence_item t);
    seqr_item = DEMUX_sequence_item::type_id::create("seqr_item");
    seqr_item.lp_data = t.lp_data;
    seqr_item.SEL_4 = t.SEL_4;
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      seq_item = DEMUX_sequence_item::type_id::create("seq_item");
      @(cfg.DEMUX_vif.mon_cb);
      if (seqr_item) begin
        seq_item.lp_data <= seqr_item.lp_data;
        seq_item.SEL_4 <= seqr_item.SEL_4;
      end
      seq_item.lp_data_0 <= cfg.DEMUX_vif.mon_cb.lp_data_0;
      seq_item.lp_data_1 <= cfg.DEMUX_vif.mon_cb.lp_data_1;
      #1step mon_aport.write(seq_item);
    end
  endtask
endclass

`endif // DEMUX_MONITOR_SVH
