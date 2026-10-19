`ifndef SYNCHRONIZER_MONITOR_SVH
`define SYNCHRONIZER_MONITOR_SVH

class Synchronizer_monitor extends uvm_monitor;
  `uvm_component_utils(Synchronizer_monitor)

  Synchronizer_sequence_item seq_item;
  Synchronizer_sequence_item seqr_item;
  Synchronizer_drv_mon_cfg_obj cfg;
  uvm_analysis_imp#(Synchronizer_sequence_item, Synchronizer_monitor) mon_aimp;
  uvm_analysis_port#(Synchronizer_sequence_item) mon_aport;

  function new(string name = "Synchronizer_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(Synchronizer_drv_mon_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("SYNCHRONIZER_MON", "Synchronizer_cfg_obj not found in config_db for Synchronizer_monitor")
    mon_aport = new("mon_aport", this);
    mon_aimp = new("mon_aimp", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  function void write(Synchronizer_sequence_item t);
    seqr_item = Synchronizer_sequence_item::type_id::create("seqr_item");
    seqr_item.rst_n = t.rst_n;
    seqr_item.signal_src = t.signal_src;
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      seq_item = Synchronizer_sequence_item::type_id::create("seq_item");
      @(cfg.Synchronizer_vif.mon_cb);
      if (seqr_item) begin
        seq_item.rst_n <= seqr_item.rst_n;
        seq_item.signal_src <= seqr_item.signal_src;
      end
      seq_item.signal_dst <= cfg.Synchronizer_vif.mon_cb.signal_dst;
      #1step mon_aport.write(seq_item);
    end
  endtask
endclass

`endif // SYNCHRONIZER_MONITOR_SVH
