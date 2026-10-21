`ifndef DEMUX1X2_MONITOR_SVH
`define DEMUX1X2_MONITOR_SVH

class Demux1x2_monitor extends uvm_monitor;
  `uvm_component_utils(Demux1x2_monitor)

  Demux1x2_sequence_item seq_item;
  Demux1x2_sequence_item seqr_item;
  Demux1x2_drv_mon_cfg_obj cfg;
  uvm_analysis_imp#(Demux1x2_sequence_item, Demux1x2_monitor) mon_aimp;
  uvm_analysis_port#(Demux1x2_sequence_item) mon_aport;

  function new(string name = "Demux1x2_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(Demux1x2_drv_mon_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("DEMUX1X2_MON", "Demux1x2_cfg_obj not found in config_db for Demux1x2_monitor")
    mon_aport = new("mon_aport", this);
    mon_aimp = new("mon_aimp", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  function void write(Demux1x2_sequence_item t);
    seqr_item = Demux1x2_sequence_item::type_id::create("seqr_item");
    seqr_item.data_in = t.data_in;
    seqr_item.sel = t.sel;
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      seq_item = Demux1x2_sequence_item::type_id::create("seq_item");
      @(cfg.Demux1x2_vif.mon_cb);
      if (seqr_item) begin
        seq_item.data_in <= seqr_item.data_in;
        seq_item.sel <= seqr_item.sel;
      end
      seq_item.out0 <= cfg.Demux1x2_vif.mon_cb.out0;
      seq_item.out1 <= cfg.Demux1x2_vif.mon_cb.out1;
      #1step mon_aport.write(seq_item);
    end
  endtask
endclass

`endif // DEMUX1X2_MONITOR_SVH
