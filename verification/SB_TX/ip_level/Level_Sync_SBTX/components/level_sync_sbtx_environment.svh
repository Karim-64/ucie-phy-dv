`ifndef LEVEL_SYNC_SBTX_ENVIRONMENT_SVH
`define LEVEL_SYNC_SBTX_ENVIRONMENT_SVH

class level_sync_sbtx_environment extends uvm_env;
  `uvm_component_utils(level_sync_sbtx_environment)

  level_sync_sbtx_agent agt;
  level_sync_sbtx_scoreboard sb;
  level_sync_sbtx_subscriber sub;

  level_sync_sbtx_env_cfg_obj cfg;
  level_sync_sbtx_agt_cfg_obj agt_cfg;

  uvm_analysis_port#(level_sync_sbtx_sequence_item) level_sync_sbtx_env_aport;

  function new(string name = "level_sync_sbtx_environment", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    level_sync_sbtx_env_aport = new("level_sync_sbtx_env_aport", this);

    if (!uvm_config_db#(level_sync_sbtx_env_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("LEVEL_SYNC_SBTX_ENV", "level_sync_sbtx_env_cfg_obj not found in config_db for level_sync_sbtx_environment")

    if (cfg.level_sync_sbtx_has_agent) begin
      agt_cfg = level_sync_sbtx_agt_cfg_obj::type_id::create("agt_cfg");
      agt_cfg.level_sync_sbtx_vif = cfg.level_sync_sbtx_vif;
      agt_cfg.is_active = cfg.active_passive_agents["level_sync_sbtx"];

      uvm_config_db#(level_sync_sbtx_agt_cfg_obj)::set(this, "agt", "cfg", agt_cfg);
    end

    if (cfg.level_sync_sbtx_has_agent)
      agt = level_sync_sbtx_agent::type_id::create("agt", this);

    if (cfg.level_sync_sbtx_has_scoreboard)
      sb = level_sync_sbtx_scoreboard::type_id::create("sb", this);

    if (cfg.level_sync_sbtx_has_subscriber)
      sub = level_sync_sbtx_subscriber::type_id::create("sub", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    if (cfg.level_sync_sbtx_has_agent) begin
      if (cfg.level_sync_sbtx_has_scoreboard)
        agt.agt_aport.connect(sb.sb_aimp);

      if (cfg.level_sync_sbtx_has_subscriber)
        agt.agt_aport.connect(sub.analysis_export);

      agt.agt_aport.connect(level_sync_sbtx_env_aport);
    end
  endfunction
endclass

`endif // LEVEL_SYNC_SBTX_ENVIRONMENT_SVH
