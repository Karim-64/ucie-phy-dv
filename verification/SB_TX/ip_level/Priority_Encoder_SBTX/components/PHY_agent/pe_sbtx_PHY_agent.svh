`ifndef PE_SBTX_PHY_AGENT_SVH
`define PE_SBTX_PHY_AGENT_SVH

class pe_sbtx_PHY_agent extends uvm_agent;
  `uvm_component_utils(pe_sbtx_PHY_agent)

  pe_sbtx_PHY_sequencer seqr;
  pe_sbtx_PHY_driver drv;
  pe_sbtx_PHY_monitor mon;

  pe_sbtx_PHY_agt_cfg_obj cfg;
  pe_sbtx_PHY_drv_mon_cfg_obj drv_mon_cfg;
  uvm_analysis_port#(pe_sbtx_PHY_sequence_item) agt_aport;

  function new(string name = "pe_sbtx_PHY_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(pe_sbtx_PHY_agt_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("PE_SBTX_PHY_AGENT", "pe_sbtx_PHY_agt_cfg_obj not found in config_db for pe_sbtx_PHY_agent")

    drv_mon_cfg = pe_sbtx_PHY_drv_mon_cfg_obj::type_id::create("drv_mon_cfg");
    drv_mon_cfg.pe_sbtx_vif = cfg.pe_sbtx_vif;

    uvm_config_db#(pe_sbtx_PHY_drv_mon_cfg_obj)::set(this, "*", "cfg", drv_mon_cfg);

    if (cfg.is_active == UVM_ACTIVE) begin
      seqr = pe_sbtx_PHY_sequencer::type_id::create("seqr", this);
      drv = pe_sbtx_PHY_driver::type_id::create("drv", this);
    end

    mon = pe_sbtx_PHY_monitor::type_id::create("mon", this);
    agt_aport = new("agt_aport", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (cfg.is_active == UVM_ACTIVE) begin
      drv.seq_item_port.connect(seqr.seq_item_export);
      seqr.seqr_aport.connect(mon.mon_aimp);
      mon.mon_aport.connect(seqr.seqr_aexport);
    end
    mon.mon_aport.connect(agt_aport);
  endfunction
endclass

`endif // PE_SBTX_PHY_AGENT_SVH
