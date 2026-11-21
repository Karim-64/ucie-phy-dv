`ifndef MUX_SBRX_AGENT_SVH
`define MUX_SBRX_AGENT_SVH

class mux_sbrx_agent extends uvm_agent;
  `uvm_component_utils(mux_sbrx_agent)

  mux_sbrx_sequencer seqr;
  mux_sbrx_driver drv;
  mux_sbrx_monitor mon;

  mux_sbrx_agt_cfg_obj cfg;
  mux_sbrx_drv_mon_cfg_obj drv_mon_cfg;
  uvm_analysis_port#(mux_sbrx_sequence_item) agt_aport;

  function new(string name = "mux_sbrx_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(mux_sbrx_agt_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("MUX_SBRX_AGENT", "mux_sbrx_cfg_obj not found in config_db for mux_sbrx_agent")

    drv_mon_cfg = mux_sbrx_drv_mon_cfg_obj::type_id::create("drv_mon_cfg");
    drv_mon_cfg.mux_sbrx_vif = cfg.mux_sbrx_vif;

    uvm_config_db#(mux_sbrx_drv_mon_cfg_obj)::set(this, "*", "cfg", drv_mon_cfg);

    if (cfg.is_active == UVM_ACTIVE) begin
      seqr = mux_sbrx_sequencer::type_id::create("seqr", this);
      drv = mux_sbrx_driver::type_id::create("drv", this);
    end

    mon = mux_sbrx_monitor::type_id::create("mon", this);
    agt_aport = new("agt_aport", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (cfg.is_active == UVM_ACTIVE) begin
      drv.seq_item_port.connect(seqr.seq_item_export);
      seqr.seqr_aport.connect(mon.mon_aimp);
    end
    mon.mon_aport.connect(agt_aport);
  endfunction
endclass

`endif // MUX_SBRX_AGENT_SVH
