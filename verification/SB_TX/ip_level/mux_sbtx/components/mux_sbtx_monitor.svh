`ifndef MUX_SBTX_MONITOR_SVH
`define MUX_SBTX_MONITOR_SVH

class mux_sbtx_monitor extends uvm_monitor;
  `uvm_component_utils(mux_sbtx_monitor)

  mux_sbtx_sequence_item seq_item;
  mux_sbtx_sequence_item seqr_item;
  mux_sbtx_drv_mon_cfg_obj cfg;
  uvm_analysis_imp#(mux_sbtx_sequence_item, mux_sbtx_monitor) mon_aimp;
  uvm_analysis_port#(mux_sbtx_sequence_item) mon_aport;

  function new(string name = "mux_sbtx_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(mux_sbtx_drv_mon_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("MUX_SBTX_MON", "mux_sbtx_cfg_obj not found in config_db for mux_sbtx_monitor")
    mon_aport = new("mon_aport", this);
    mon_aimp = new("mon_aimp", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  function void write(mux_sbtx_sequence_item t);
    seqr_item = mux_sbtx_sequence_item::type_id::create("seqr_item");
    seqr_item.IN_0 = t.IN_0;
    seqr_item.IN_1 = t.IN_1;
    seqr_item.Mux_Sel = t.Mux_Sel;
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      seq_item = mux_sbtx_sequence_item::type_id::create("seq_item");
      @(cfg.mux_sbtx_vif.mon_cb);
      if (seqr_item) begin
        seq_item.IN_0 <= seqr_item.IN_0;
        seq_item.IN_1 <= seqr_item.IN_1;
        seq_item.Mux_Sel <= seqr_item.Mux_Sel;
      end
      seq_item.OUT <= cfg.mux_sbtx_vif.mon_cb.OUT;
      #1step mon_aport.write(seq_item);
    end
  endtask
endclass

`endif // MUX_SBTX_MONITOR_SVH
