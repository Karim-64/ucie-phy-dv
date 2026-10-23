`ifndef LEVEL_SYNC_SBTX_AGENT_SVH
`define LEVEL_SYNC_SBTX_AGENT_SVH

class level_sync_sbtx_agent extends uvm_agent;
  `uvm_component_utils(level_sync_sbtx_agent)

  level_sync_sbtx_sequencer seqr;
  level_sync_sbtx_driver drv;
  level_sync_sbtx_monitor mon;

  level_sync_sbtx_agt_cfg_obj cfg;
  level_sync_sbtx_drv_mon_cfg_obj drv_mon_cfg;
  uvm_analysis_port#(level_sync_sbtx_sequence_item) agt_aport;

  function new(string name = "level_sync_sbtx_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(level_sync_sbtx_agt_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("LEVEL_SYNC_SBTX_AGENT", "level_sync_sbtx_cfg_obj not found in config_db for level_sync_sbtx_agent")

    drv_mon_cfg = level_sync_sbtx_drv_mon_cfg_obj::type_id::create("drv_mon_cfg");
    drv_mon_cfg.level_sync_sbtx_vif = cfg.level_sync_sbtx_vif;

    uvm_config_db#(level_sync_sbtx_drv_mon_cfg_obj)::set(this, "*", "cfg", drv_mon_cfg);

    if (cfg.is_active == UVM_ACTIVE) begin
      seqr = level_sync_sbtx_sequencer::type_id::create("seqr", this);
      drv = level_sync_sbtx_driver::type_id::create("drv", this);
    end

    mon = level_sync_sbtx_monitor::type_id::create("mon", this);
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

`endif // LEVEL_SYNC_SBTX_AGENT_SVH
