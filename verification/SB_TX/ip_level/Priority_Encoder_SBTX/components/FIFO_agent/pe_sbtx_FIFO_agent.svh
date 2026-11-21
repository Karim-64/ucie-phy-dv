`ifndef PE_SBTX_FIFO_AGENT_SVH
`define PE_SBTX_FIFO_AGENT_SVH

class pe_sbtx_FIFO_agent extends uvm_agent;
  `uvm_component_utils(pe_sbtx_FIFO_agent)

  pe_sbtx_FIFO_monitor mon;

  pe_sbtx_FIFO_agt_cfg_obj cfg;
  pe_sbtx_FIFO_drv_mon_cfg_obj drv_mon_cfg;
  uvm_analysis_port#(pe_sbtx_FIFO_sequence_item) agt_aport;

  function new(string name = "pe_sbtx_FIFO_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(pe_sbtx_FIFO_agt_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("PE_SBTX_FIFO_AGENT", "pe_sbtx_FIFO_agt_cfg_obj not found in config_db for pe_sbtx_FIFO_agent")

    drv_mon_cfg = pe_sbtx_FIFO_drv_mon_cfg_obj::type_id::create("drv_mon_cfg");
    drv_mon_cfg.pe_sbtx_vif = cfg.pe_sbtx_vif;

    uvm_config_db#(pe_sbtx_FIFO_drv_mon_cfg_obj)::set(this, "*", "cfg", drv_mon_cfg);

    mon = pe_sbtx_FIFO_monitor::type_id::create("mon", this);
    agt_aport = new("agt_aport", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    mon.mon_aport.connect(agt_aport);
  endfunction
endclass

`endif // PE_SBTX_FIFO_AGENT_SVH