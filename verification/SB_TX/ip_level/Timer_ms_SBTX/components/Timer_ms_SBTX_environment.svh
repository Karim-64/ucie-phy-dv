`ifndef TIMER_MS_SBTX_ENVIRONMENT_SVH
`define TIMER_MS_SBTX_ENVIRONMENT_SVH

class Timer_ms_SBTX_environment extends uvm_env;
  `uvm_component_utils(Timer_ms_SBTX_environment)

  Timer_ms_SBTX_agent agt;
  Timer_ms_SBTX_scoreboard sb;
  Timer_ms_SBTX_subscriber sub;

  Timer_ms_SBTX_env_cfg_obj cfg;
  Timer_ms_SBTX_agt_cfg_obj agt_cfg;

  uvm_analysis_port#(Timer_ms_SBTX_sequence_item) Timer_ms_SBTX_env_aport;

  function new(string name = "Timer_ms_SBTX_environment", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    Timer_ms_SBTX_env_aport = new("Timer_ms_SBTX_env_aport", this);

    if (!uvm_config_db#(Timer_ms_SBTX_env_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("TIMER_MS_SBTX_ENV", "Timer_ms_SBTX_env_cfg_obj not found in config_db for Timer_ms_SBTX_environment")

    if (cfg.Timer_ms_SBTX_has_agent) begin
      agt_cfg = Timer_ms_SBTX_agt_cfg_obj::type_id::create("agt_cfg");
      agt_cfg.Timer_ms_SBTX_vif = cfg.Timer_ms_SBTX_vif;
      agt_cfg.is_active = cfg.active_passive_agents["Timer_ms_SBTX"];

      uvm_config_db#(Timer_ms_SBTX_agt_cfg_obj)::set(this, "agt", "cfg", agt_cfg);
    end

    if (cfg.Timer_ms_SBTX_has_agent)
      agt = Timer_ms_SBTX_agent::type_id::create("agt", this);

    if (cfg.Timer_ms_SBTX_has_scoreboard)
      sb = Timer_ms_SBTX_scoreboard::type_id::create("sb", this);

    if (cfg.Timer_ms_SBTX_has_subscriber)
      sub = Timer_ms_SBTX_subscriber::type_id::create("sub", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    if (cfg.Timer_ms_SBTX_has_agent) begin
      if (cfg.Timer_ms_SBTX_has_scoreboard)
        agt.agt_aport.connect(sb.sb_aimp);

      if (cfg.Timer_ms_SBTX_has_subscriber)
        agt.agt_aport.connect(sub.analysis_export);

      agt.agt_aport.connect(Timer_ms_SBTX_env_aport);
    end
  endfunction
endclass

`endif // TIMER_MS_SBTX_ENVIRONMENT_SVH
