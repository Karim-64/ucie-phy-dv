`ifndef MUX_SBRX_MONITOR_SVH
`define MUX_SBRX_MONITOR_SVH

class mux_sbrx_monitor extends uvm_monitor;
  `uvm_component_utils(mux_sbrx_monitor)

  mux_sbrx_sequence_item seq_item;
  mux_sbrx_sequence_item seqr_item;
  mux_sbrx_drv_mon_cfg_obj cfg;
  uvm_analysis_imp#(mux_sbrx_sequence_item, mux_sbrx_monitor) mon_aimp;
  uvm_analysis_port#(mux_sbrx_sequence_item) mon_aport;

  function new(string name = "mux_sbrx_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(mux_sbrx_drv_mon_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("MUX_SBRX_MON", "mux_sbrx_cfg_obj not found in config_db for mux_sbrx_monitor")
    mon_aport = new("mon_aport", this);
    mon_aimp = new("mon_aimp", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  function void write(mux_sbrx_sequence_item t);
    seqr_item = mux_sbrx_sequence_item::type_id::create("seqr_item");
    seqr_item.in0 = t.in0;
    seqr_item.in1 = t.in1;
    seqr_item.sel = t.sel;
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      seq_item = mux_sbrx_sequence_item::type_id::create("seq_item");
      @(cfg.mux_sbrx_vif.mon_cb);
      if (seqr_item) begin
        seq_item.in0 <= seqr_item.in0;
        seq_item.in1 <= seqr_item.in1;
        seq_item.sel <= seqr_item.sel;
      end
      seq_item.out <= cfg.mux_sbrx_vif.mon_cb.out;
      #1step mon_aport.write(seq_item);
    end
  endtask
endclass

`endif // MUX_SBRX_MONITOR_SVH
