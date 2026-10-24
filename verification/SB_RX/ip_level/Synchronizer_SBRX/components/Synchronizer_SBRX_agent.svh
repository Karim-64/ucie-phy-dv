`ifndef SYNCHRONIZER_SBRX_AGENT_SVH
`define SYNCHRONIZER_SBRX_AGENT_SVH

class Synchronizer_SBRX_agent extends uvm_agent;
  `uvm_component_utils(Synchronizer_SBRX_agent)

  Synchronizer_SBRX_sequencer seqr;
  Synchronizer_SBRX_driver drv;
  Synchronizer_SBRX_monitor mon;

  Synchronizer_SBRX_agt_cfg_obj cfg;
  Synchronizer_SBRX_drv_mon_cfg_obj drv_mon_cfg;
  uvm_analysis_port#(Synchronizer_SBRX_sequence_item) agt_aport;

  function new(string name = "Synchronizer_SBRX_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(Synchronizer_SBRX_agt_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("SYNCHRONIZER_SBRX_AGENT", "Synchronizer_SBRX_cfg_obj not found in config_db for Synchronizer_SBRX_agent")

    drv_mon_cfg = Synchronizer_SBRX_drv_mon_cfg_obj::type_id::create("drv_mon_cfg");
    drv_mon_cfg.Synchronizer_SBRX_vif = cfg.Synchronizer_SBRX_vif;

    uvm_config_db#(Synchronizer_SBRX_drv_mon_cfg_obj)::set(this, "*", "cfg", drv_mon_cfg);

    if (cfg.is_active == UVM_ACTIVE) begin
      seqr = Synchronizer_SBRX_sequencer::type_id::create("seqr", this);
      drv = Synchronizer_SBRX_driver::type_id::create("drv", this);
    end

    mon = Synchronizer_SBRX_monitor::type_id::create("mon", this);
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

`endif // SYNCHRONIZER_SBRX_AGENT_SVH
