`ifndef ENABLE_GENERATOR_MBRX_AGENT_SVH
`define ENABLE_GENERATOR_MBRX_AGENT_SVH

class Enable_Generator_MBRX_agent extends uvm_agent;
  `uvm_component_utils(Enable_Generator_MBRX_agent)

  Enable_Generator_MBRX_sequencer seqr;
  Enable_Generator_MBRX_driver drv;
  Enable_Generator_MBRX_monitor mon;

  Enable_Generator_MBRX_agt_cfg_obj cfg;
  Enable_Generator_MBRX_drv_mon_cfg_obj drv_mon_cfg;
  uvm_analysis_port#(Enable_Generator_MBRX_sequence_item) agt_aport;

  function new(string name = "Enable_Generator_MBRX_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(Enable_Generator_MBRX_agt_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("ENABLE_GENERATOR_MBRX_AGENT", "Enable_Generator_MBRX_cfg_obj not found in config_db for Enable_Generator_MBRX_agent")

    drv_mon_cfg = Enable_Generator_MBRX_drv_mon_cfg_obj::type_id::create("drv_mon_cfg");
    drv_mon_cfg.Enable_Generator_MBRX_vif = cfg.Enable_Generator_MBRX_vif;

    uvm_config_db#(Enable_Generator_MBRX_drv_mon_cfg_obj)::set(this, "*", "cfg", drv_mon_cfg);

    if (cfg.is_active == UVM_ACTIVE) begin
      seqr = Enable_Generator_MBRX_sequencer::type_id::create("seqr", this);
      drv = Enable_Generator_MBRX_driver::type_id::create("drv", this);
    end

    mon = Enable_Generator_MBRX_monitor::type_id::create("mon", this);
    agt_aport = new("agt_aport", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (cfg.is_active == UVM_ACTIVE) begin
      drv.seq_item_port.connect(seqr.seq_item_export);
      seqr.seqr_ap.connect(mon.mon_aimp);
    end
    mon.mon_aport.connect(agt_aport);
  endfunction
endclass

`endif // ENABLE_GENERATOR_MBRX_AGENT_SVH
