`ifndef DMUX_1X4_AGENT_SVH
`define DMUX_1X4_AGENT_SVH

class DMUX_1x4_agent extends uvm_agent;
  `uvm_component_utils(DMUX_1x4_agent)

  DMUX_1x4_sequencer seqr;
  DMUX_1x4_driver drv;
  DMUX_1x4_monitor mon;

  DMUX_1x4_agt_cfg_obj cfg;
  DMUX_1x4_drv_mon_cfg_obj drv_mon_cfg;
  uvm_analysis_port#(DMUX_1x4_sequence_item) agt_aport;

  function new(string name = "DMUX_1x4_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(DMUX_1x4_agt_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("DMUX_1X4_AGENT", "DMUX_1x4_cfg_obj not found in config_db for DMUX_1x4_agent")

    drv_mon_cfg = DMUX_1x4_drv_mon_cfg_obj::type_id::create("drv_mon_cfg");
    drv_mon_cfg.DMUX_1x4_vif = cfg.DMUX_1x4_vif;

    uvm_config_db#(DMUX_1x4_drv_mon_cfg_obj)::set(this, "*", "cfg", drv_mon_cfg);

    if (cfg.is_active == UVM_ACTIVE) begin
      seqr = DMUX_1x4_sequencer::type_id::create("seqr", this);
      drv = DMUX_1x4_driver::type_id::create("drv", this);
    end

    mon = DMUX_1x4_monitor::type_id::create("mon", this);
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

`endif // DMUX_1X4_AGENT_SVH
