`ifndef CREDITS_HANDLER_SBTX_AGENT_SVH
`define CREDITS_HANDLER_SBTX_AGENT_SVH

class Credits_Handler_SBTX_agent extends uvm_agent;
  `uvm_component_utils(Credits_Handler_SBTX_agent)

  Credits_Handler_SBTX_sequencer seqr;
  Credits_Handler_SBTX_driver drv;
  Credits_Handler_SBTX_monitor mon;

  Credits_Handler_SBTX_agt_cfg_obj cfg;
  Credits_Handler_SBTX_drv_mon_cfg_obj drv_mon_cfg;
  uvm_analysis_port#(Credits_Handler_SBTX_sequence_item) agt_aport;

  function new(string name = "Credits_Handler_SBTX_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(Credits_Handler_SBTX_agt_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("CREDITS_HANDLER_SBTX_AGENT", "Credits_Handler_SBTX_cfg_obj not found in config_db for Credits_Handler_SBTX_agent")

    drv_mon_cfg = Credits_Handler_SBTX_drv_mon_cfg_obj::type_id::create("drv_mon_cfg");
    drv_mon_cfg.Credits_Handler_SBTX_vif = cfg.Credits_Handler_SBTX_vif;

    uvm_config_db#(Credits_Handler_SBTX_drv_mon_cfg_obj)::set(this, "*", "cfg", drv_mon_cfg);

    if (cfg.is_active == UVM_ACTIVE) begin
      seqr = Credits_Handler_SBTX_sequencer::type_id::create("seqr", this);
      drv = Credits_Handler_SBTX_driver::type_id::create("drv", this);
    end

    mon = Credits_Handler_SBTX_monitor::type_id::create("mon", this);
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

`endif // CREDITS_HANDLER_SBTX_AGENT_SVH
