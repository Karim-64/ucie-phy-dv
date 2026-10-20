`ifndef VLD_MUX_ENVIRONMENT_SVH
`define VLD_MUX_ENVIRONMENT_SVH

class VLD_MUX_environment extends uvm_env;
  `uvm_component_utils(VLD_MUX_environment)

  VLD_MUX_agent agt;
  VLD_MUX_scoreboard sb;
  VLD_MUX_subscriber sub;

  VLD_MUX_env_cfg_obj cfg;
  VLD_MUX_agt_cfg_obj agt_cfg;

  uvm_analysis_port#(VLD_MUX_sequence_item) VLD_MUX_env_aport;

  function new(string name = "VLD_MUX_environment", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    VLD_MUX_env_aport = new("VLD_MUX_env_aport", this);

    if (!uvm_config_db#(VLD_MUX_env_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("VLD_MUX_ENV", "VLD_MUX_env_cfg_obj not found in config_db for VLD_MUX_environment")

    if (cfg.VLD_MUX_has_agent) begin
      agt_cfg = VLD_MUX_agt_cfg_obj::type_id::create("agt_cfg");
      agt_cfg.VLD_MUX_vif = cfg.VLD_MUX_vif;
      agt_cfg.is_active = cfg.active_passive_agents["VLD_MUX"];

      uvm_config_db#(VLD_MUX_agt_cfg_obj)::set(this, "agt", "cfg", agt_cfg);
    end

    if (cfg.VLD_MUX_has_agent)
      agt = VLD_MUX_agent::type_id::create("agt", this);

    if (cfg.VLD_MUX_has_scoreboard)
      sb = VLD_MUX_scoreboard::type_id::create("sb", this);

    if (cfg.VLD_MUX_has_subscriber)
      sub = VLD_MUX_subscriber::type_id::create("sub", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    if (cfg.VLD_MUX_has_agent) begin
      if (cfg.VLD_MUX_has_scoreboard)
        agt.agt_aport.connect(sb.sb_aimp);

      if (cfg.VLD_MUX_has_subscriber)
        agt.agt_aport.connect(sub.analysis_export);

      agt.agt_aport.connect(VLD_MUX_env_aport);
    end
  endfunction
endclass

`endif // VLD_MUX_ENVIRONMENT_SVH
