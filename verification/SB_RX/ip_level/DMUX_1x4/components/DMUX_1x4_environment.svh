`ifndef DMUX_1X4_ENVIRONMENT_SVH
`define DMUX_1X4_ENVIRONMENT_SVH

class DMUX_1x4_environment extends uvm_env;
  `uvm_component_utils(DMUX_1x4_environment)

  DMUX_1x4_agent agt;
  DMUX_1x4_scoreboard sb;
  DMUX_1x4_subscriber sub;

  DMUX_1x4_env_cfg_obj cfg;
  DMUX_1x4_agt_cfg_obj agt_cfg;

  uvm_analysis_port#(DMUX_1x4_sequence_item) DMUX_1x4_env_aport;

  function new(string name = "DMUX_1x4_environment", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    DMUX_1x4_env_aport = new("DMUX_1x4_env_aport", this);

    if (!uvm_config_db#(DMUX_1x4_env_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("DMUX_1X4_ENV", "DMUX_1x4_env_cfg_obj not found in config_db for DMUX_1x4_environment")

    if (cfg.DMUX_1x4_has_agent) begin
      agt_cfg = DMUX_1x4_agt_cfg_obj::type_id::create("agt_cfg");
      agt_cfg.DMUX_1x4_vif = cfg.DMUX_1x4_vif;
      agt_cfg.is_active = cfg.active_passive_agents["DMUX_1x4"];

      uvm_config_db#(DMUX_1x4_agt_cfg_obj)::set(this, "agt", "cfg", agt_cfg);
    end

    if (cfg.DMUX_1x4_has_agent)
      agt = DMUX_1x4_agent::type_id::create("agt", this);

    if (cfg.DMUX_1x4_has_scoreboard)
      sb = DMUX_1x4_scoreboard::type_id::create("sb", this);

    if (cfg.DMUX_1x4_has_subscriber)
      sub = DMUX_1x4_subscriber::type_id::create("sub", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    if (cfg.DMUX_1x4_has_agent) begin
      if (cfg.DMUX_1x4_has_scoreboard)
        agt.agt_aport.connect(sb.exp);

      if (cfg.DMUX_1x4_has_subscriber)
        agt.agt_aport.connect(sub.exp);

      agt.agt_aport.connect(DMUX_1x4_env_aport);
    end
  endfunction
endclass

`endif // DMUX_1X4_ENVIRONMENT_SVH
