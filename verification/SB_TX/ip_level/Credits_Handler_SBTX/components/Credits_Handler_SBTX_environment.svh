`ifndef CREDITS_HANDLER_SBTX_ENVIRONMENT_SVH
`define CREDITS_HANDLER_SBTX_ENVIRONMENT_SVH

class Credits_Handler_SBTX_environment extends uvm_env;
  `uvm_component_utils(Credits_Handler_SBTX_environment)

  Credits_Handler_SBTX_agent agt;
  Credits_Handler_SBTX_scoreboard sb;
  Credits_Handler_SBTX_subscriber sub;

  Credits_Handler_SBTX_env_cfg_obj cfg;
  Credits_Handler_SBTX_agt_cfg_obj agt_cfg;

  uvm_analysis_port#(Credits_Handler_SBTX_sequence_item) Credits_Handler_SBTX_env_aport;

  function new(string name = "Credits_Handler_SBTX_environment", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    Credits_Handler_SBTX_env_aport = new("Credits_Handler_SBTX_env_aport", this);

    if (!uvm_config_db#(Credits_Handler_SBTX_env_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("CREDITS_HANDLER_SBTX_ENV", "Credits_Handler_SBTX_env_cfg_obj not found in config_db for Credits_Handler_SBTX_environment")

    if (cfg.Credits_Handler_SBTX_has_agent) begin
      agt_cfg = Credits_Handler_SBTX_agt_cfg_obj::type_id::create("agt_cfg");
      agt_cfg.Credits_Handler_SBTX_vif = cfg.Credits_Handler_SBTX_vif;
      agt_cfg.is_active = cfg.active_passive_agents["Credits_Handler_SBTX"];

      uvm_config_db#(Credits_Handler_SBTX_agt_cfg_obj)::set(this, "agt", "cfg", agt_cfg);
    end

    if (cfg.Credits_Handler_SBTX_has_agent)
      agt = Credits_Handler_SBTX_agent::type_id::create("agt", this);

    if (cfg.Credits_Handler_SBTX_has_scoreboard)
      sb = Credits_Handler_SBTX_scoreboard::type_id::create("sb", this);

    if (cfg.Credits_Handler_SBTX_has_subscriber)
      sub = Credits_Handler_SBTX_subscriber::type_id::create("sub", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    if (cfg.Credits_Handler_SBTX_has_agent) begin
      if (cfg.Credits_Handler_SBTX_has_scoreboard)
        agt.agt_aport.connect(sb.sb_aexp);

      if (cfg.Credits_Handler_SBTX_has_subscriber)
        agt.agt_aport.connect(sub.analysis_export);

      agt.agt_aport.connect(Credits_Handler_SBTX_env_aport);
    end
  endfunction
endclass

`endif // CREDITS_HANDLER_SBTX_ENVIRONMENT_SVH
